mkbuf = (len) ->
    new Float32Array Math.floor len

firefox_on_linux = ->
    $.browser.mozilla and (navigator.platform.indexOf("Linux") != -1 or navigator.oscpu.indexOf("Linux") != -1)

CHANNELS = 2

mksink = (srate)->
    try
        # if $.browser.mozilla
        #    issue_warning("This app works better in Chrome")
        prebuf_size = if firefox_on_linux() then (srate/2) else 2048
        prebuf_size = Math.floor(prebuf_size)
        Sink(null, CHANNELS, prebuf_size, srate)
    catch error # not sure if the exception would happen here
        alert("الرجاء فتح الموقع فيمتصفح كووكل كروم")
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
    shape = Object.clone(shape)
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
    mk_point 0.1, 0.1
    mk_point 0.16, 0.22
    mk_point 0.26, -0.26
    mk_point 0.4, -0.22
    mk_point 0.5, 0.1
    mk_point 0.6, 0.34
    mk_point 0.7, 0.24
    mk_point 0.84, 0
    mk_point 0.91, -0.04
]

DURATION = 1.1
GAIN = 0.7
SIGNAL_LEN = DURATION * SRATE * CHANNELS

dev.ringBuffer = mkbuf(7 * CHANNELS * SRATE)

# just for the dampness
dampness = (->
    down = (val) -> Math.max 0, val - 0.24
    # e ^ (-2x) - 0.2 # (without going below 0)
    for point in [0..SIGNAL_LEN]
        down(Math.pow(Math.E, -2 * (point/SIGNAL_LEN)))
)()

# karplus strong algorithm
string_type_factory = (wave_shape, noise_sample_param) ->
    signal_gen = (freq) ->
        table_len = period_len freq
        table = mkbuf(table_len)
        base_sample = wave_shape_to_sample(wave_shape, table_len)
        # first apply white nose to the base sample
        for s, index in base_sample
            table[index] = base_sample[index] + ks_noise_sample(noise_sample_param)
        signal = mkbuf(SIGNAL_LEN)
        for s, index in signal
            point = index % table_len
            adj = (table_len + index - 1) % table_len
            table[point] = avg(table[point], table[adj])
            signal[index] = table[point]
        return signal

oud_signal_gen = string_type_factory(oud_wave_shape, 0.12)

tonefreq = (tone, base=128) ->
    # use DO=128 (2^7) as a base reference
    # TODO: provide UI to change value
    # It should be noted that:
    #
    #   130.39 would create a LA frequency of ~ 220.00 which is the standard in
    #   western music
    #
    #   130.81 is the western value for the DO note, but would (on our Ajam
    #   scale) create a LA tone with frequency 220.71 which is a bit off from
    #   the western standard
    #
    #   The value of 128 for DO causes the LA note to have a frequency of
    #   215.97 which is rather different from the western LA note of 220
    #
    tones_per_octave = 53 # turkish comma system
    return base * Math.pow(2, tone/tones_per_octave)

tone_signal = {}

tone_gen = (tone) ->
    if tone of tone_signal
        tone_signal[tone]
    else
        tone_signal[tone] = signal_gen_from_freq(tonefreq(tone))

window.signal_gen_from_freq = (freq) ->
    signal_raw = oud_signal_gen(freq)
    signal_raw2 = oud_signal_gen(freq)
    signal = mkbuf(SIGNAL_LEN)
    for s, point in signal
        signal[point] = (signal_raw[point] + signal_raw2[point]) * dampness[point] * GAIN
    make_dual_channel signal

make_dual_channel = (signal) ->
    signal2 = mkbuf(signal.length * 2)
    for s, index in signal2
        signal2[index] = signal[Math.floor(index/2)]
    signal2

window.play_freq = (freq)->
    play_signal signal_gen_from_freq freq

window.playtone = (tone)->
    signal = tone_gen(tone)
    play_signal signal

window.play_signal = (signal) ->
    point = dev.ringOffset
    ringlen = dev.ringBuffer.length
    for sample in signal
        point = (point + 1) % ringlen
        dev.ringBuffer[point] += sample
    true

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

setInterval(mk_ring_cleaner(), 200)
