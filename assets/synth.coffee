mkbuf = (len) -> 
    new Float32Array(len)

makemixer = ->
    fns: []
    add: (fn) ->
        @fns.push(fn)
    mix: (buf) ->
        done = []
        for fn in mixer.fns
            b = mkbuf(buf.length / 2) # buf is two channels, b is one channel
            result = fn(b)
            for s, i in buf
                # convert mono-channel signal to dual-channel
                buf[i*2] += b[i]
                buf[i*2+1] += b[i]
            if not result
                done.push(fn)
        mixer.fns = _.difference(mixer.fns, done)
        return true

try
    window.mixer = makemixer()
    dev = Sink(mixer.mix)
    window.srate = -> dev.sampleRate
    if dev.type == "dummy"
        $("#error_box").text("Your browser doesn't support Web Audio. Open this site in Firefox").show()
        if $.browser.webkit
            $("#error_box").after("In Chrome, you can enable web audio from <code>about:flags</code> (only available in beta versions)")
catch error # not sure if the exception would happen here
    $("#error_box").text("Error initializing audio output").show()
    console.log "something failed:\n", error


period_len = (freq) -> Math.round (srate()/freq)

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
    k = 2 * Math.PI * freq / srate()
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
SIGNAL_LEN = DURATION * srate()

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
        return tone_signal[tone]
    else
        signal_raw = oud_signal_gen(tonefreq(tone))
        tone_signal[tone] = (signal_raw[point] * dampness[point] * GAIN for point in [0..SIGNAL_LEN])

now_playing = 0

window.playtone = (tone)->
    duration = DURATION
    current_sample = 0
    signal = tone_gen(tone)
    now_playing += 1
    generator = (out) -> 
        end = false
        if(current_sample >= SIGNAL_LEN) or now_playing > 7 or current_sample >= SIGNAL_LEN
            now_playing -= 1
            return null
        size = out.length
        written = 0
        while(written < size and current_sample < SIGNAL_LEN) 
            out[written] = signal[current_sample]
            current_sample++
            written++
        return written

    mixer.add(generator)

