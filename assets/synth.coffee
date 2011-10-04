mkbuf = (len) -> 
    new Float32Array(len)

firefox_on_linux = ->
    $.browser.mozilla and (navigator.platform.indexOf("Linux") != -1 or navigator.oscpu.indexOf("Linux") != -1)

mksink = (srate)->
    try
        prebuf_size = if firefox_on_linux() then (srate/2) else srate/7
        Sink(null, 1, prebuf_size, srate)
    catch error # not sure if the exception would happen here
        $("#error_box").text("Your browser doesn't support Web Audio. Open this page in Firefox").show()
        if $.browser.webkit
            $("#error_box").after("In Chrome, you can enable web audio from <code>about:flags</code>" + 
                "(only available in beta versions)")
        {sampleRate: srate, ringOffset: 0}
            
window.dev = mksink(44100)
SRATE = dev.sampleRate

period_len = (freq) -> Math.round (SRATE/freq)

avg = (a, b) -> (a + b) / 2

probability = (p) ->
    # return true with probablily p (p is between 0, 1)
    return Math.random() < p

ks_noise_sample = (val=0.5) ->
    # get either val or -val with 50% chance
    if probability(0.5)
        val
    else
        -val

random_sample = ->
    2 * Math.random() - 1

mk_point = (x,y) -> {x, y}

mk_wave_shape = (points) ->
    if points[0].x != 0
        points.unshift(mk_point(0,0))
    if points[points.length-1].x != 1
        points.push(mk_point(1,0))
    points

interpolate = (v1, v2, dist) ->
    (v2 - v1) * dist + v1

wave_shape_to_sample = (shape, len) ->
    # turns a waveshape to an actual wave form of the given length
    shape = _(shape).clone()
    sample = mkbuf(len)
    prev = shape.shift()
    for s, i in sample
        next = shape[0]
        x = i/len
        dist = (x-prev.x) / (next.x - prev.x)
        sample[i] = interpolate(prev.y, next.y, dist)
        if x > next.x
            prev = shape.shift()
    return sample

oud_wave_shape = mk_wave_shape [
    mk_point 0.1, 0.8
    mk_point 0.26, 0.72
    mk_point 0.4, 0.42
    mk_point 0.6, 0.84
    mk_point 0.84, 0.3
]

DURATION = 2.6
GAIN = 0.24
SIGNAL_LEN = DURATION * SRATE

dev.ringBuffer = mkbuf(7 * SRATE)

dampness = (Math.pow(Math.E, -5 * (point/SIGNAL_LEN)) for point in [0..SIGNAL_LEN])

# OLD
# Base signal shape, which we later add white-noise to it
# sines_sig = precalc_table sines(2, 100, 390)

# karplus strong algorithm
oud_signal_gen = (freq) ->
    table_len = period_len freq
    table = mkbuf(table_len)
    base_sample = wave_shape_to_sample(oud_wave_shape, table_len)
    signal = mkbuf(SIGNAL_LEN)
    for s, index in signal
        point = index % table_len
        if index < table_len
            table[point] = base_sample[point] + ks_noise_sample(0.09)
            signal[index] = table[point]
        else
            prev = (index - 1) % table_len
            table[point] = avg(table[point], table[prev])
            signal[index] = table[point]
    return signal

tonefreq = (tone, base=130.82) ->
   tones_per_octave = 6 # DON'T CHANGE!!
   return base * Math.pow(2, tone/tones_per_octave)

window.tone_signal = {}

tone_gen = (tone) ->
    if tone of tone_signal
        tone_signal[tone]
    else
        signal_raw = oud_signal_gen(tonefreq(tone))
        signal = mkbuf(SIGNAL_LEN)
        for s, point in signal
            signal[point] = signal_raw[point] * dampness[point] * GAIN
        tone_signal[tone] = signal

window.playtone = (tone)->
    signal = tone_gen(tone)
    start = dev.ringOffset
    for s, i in signal
        point = start + i
        point = point % dev.ringBuffer.length
        dev.ringBuffer[point] += s

mk_ring_cleaner = ->
    prev_offset = 0
    len = dev.ringBuffer.length
    clean_ring = ->
        offset = dev.ringOffset
        point = prev_offset
        end = if offset < prev_offset then len + offset else offset
        while point < end
            dev.ringBuffer[point % len] = 0
            point++
        prev_offset = offset

setInterval(mk_ring_cleaner(), 1000)


