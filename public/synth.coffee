
SRATE = 44100
APARAMS = new AudioParameters(1, SRATE)      

# Thanks to 'yury' from #audio@irc.mozilla.org
getmixer = _.once ->
    try
        mixer = new AudioDataMixer(APARAMS)
        audio_output = new AudioDataDestination(APARAMS)
        audio_output.autoLatency = true
        audio_output.writeAsync(mixer)
        window.mixer = mixer
        return mixer
    catch error # not sure if the exception would happen here
        if $.browser.mozilla and $.browser.version >= 2
            $("#error_box").text("Error initializing audio output. Reload the page (if that fails, you might have to restart the browser)!").show()
            console.log "mozSetup failed:", error
        else
            $("#error_box").text("Only Firefox4 is supported").show()
        return { addInputSource: -> } # dummy mixer

$ getmixer

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

# Base signal shape, which we later add white-noise to it
sines_sig = precalc_table sines(2, 100, 390)

# karplus strong algorithm
oudfn = (freq) ->
    samples = period_len freq
    table = new Float32Array(samples)
    sampleat = (point) -> sines_sig[point] + ks_noise_sample(0.26)
    getsample = (index) ->
        point = index % samples
        if index < samples
            noise = sampleat(point)
            table[point] = noise
        else
            prev = (index - 1) % samples
            table[point] = avg(table[point], table[prev])

tonefreq = (tone, base=130.82) ->
   tones_per_octave = 6 # DON'T CHANGE!!
   return base * Math.pow(2, tone/tones_per_octave)

now_playing = 0

# async now thanks to audiodata :)
window.playtone = (tone, fn=oudfn, gain=0.1) ->
    freq = tonefreq(tone)
    duration = 4
    current_sample = 0
    last_sample = duration * SRATE
    sigfn = fn(freq)
    now_playing += 1
    source =
        audioParameters: APARAMS
        read: (out) -> 
            end = false
            if(current_sample >= last_sample) 
                end = true
            if now_playing > 4
                end = true
            if end
                now_playing -= 1
                return null
            size = out.length
            written = 0
            sample_at = (point) ->
                damp = Math.pow(Math.E, -6 * (point/last_sample))
                signal = sigfn(point)
                return gain * damp * signal
            while(written < size and current_sample < last_sample) 
                out[written] = sample_at(current_sample)
                current_sample++
                written++
            return written

    getmixer().addInputSource(source)

