mkbuf = (len) -> 
    new Float32Array(len)

firefox_on_linux = ->
    $.browser.mozilla and (navigator.platform.indexOf("Linux") != -1 or navigator.oscpu.indexOf("Linux") != -1)

mksink = (srate)->
    try
        prebuf_size = if firefox_on_linux() then (srate/2) else srate/10
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

probably = (p) ->
    # return true with probablily p (p is between 0, 1)
    return Math.random() < p

ks_noise_sample = (val=0.5) ->
    # get either val or -val with 50% chance
    if probably(0.5)
        val
    else
        -val

random_sample = ->
    2 * Math.random() - 1

sine = (freq) ->
    k = 2 * Math.PI * freq / SRATE
    (point) -> Math.sin(k * point)

sines = (freqs...) ->
    fns = _.map(freqs, sine)
    (point) ->
        val = 0
        for fn in fns
            val += fn(point)
        return val

precalc_table = _.once (fn, len=4000) ->
    table = new Float32Array(len)
    for point in [0..len]
        table[point] = fn(point)
    table

DURATION = 2.4
GAIN = 0.14
SIGNAL_LEN = DURATION * SRATE

dev.ringBuffer = mkbuf(7 * SRATE)

dampness = (Math.pow(Math.E, -5 * (point/SIGNAL_LEN)) for point in [0..SIGNAL_LEN])

# Base signal shape, which we later add white-noise to it
sines_sig = precalc_table sines(2, 100, 390)

# karplus strong algorithm
oud_signal_gen = (freq) ->
    samples = period_len freq
    table = new Float32Array(samples)
    for index in [0..SIGNAL_LEN]
        point = index % samples
        if index < samples
            table[point] = sines_sig[point] + ks_noise_sample(0.42)
        else
            prev = (index - 1) % samples
            table[point] = avg(table[point], table[prev])

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
        for point in [0..SIGNAL_LEN]
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


