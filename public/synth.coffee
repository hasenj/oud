
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

ks_noise_sample = (val) ->
    # get either val or -val with 50% chance
    if probably(0.5)
        val
    else
        -val

random_sample = ->
    2 * Math.random() - 1

log_freq_off = (freq, per_len) ->
    freq0 = SRATE / per_len
    diff = Math.abs(freq0 - freq)
    r = 100 * diff / freq
    console.log "From %s to %s: %s", freq, freq0, r
    if r > 1
        console.log "Warning, frequency off by more than 1%"
        console.log "From %s to %s: %s", freq, freq0, r
    
sine = (freq) ->
    k = 2 * Math.PI * freq / SRATE
    g = 0.7
    console.log "sine of", freq
    (point) -> g * Math.sin(k * point)

sines = (freqs...) ->
    fns = _.map(freqs, sine)
    (point) ->
        val = 0
        for fn in fns
            val += fn(point)
        return val

sig = _.memoize sines(1, 4, 100)

# karplus strong algorithm
oudfn = (freq) ->
    samples = period_len freq
    # log_freq_off(freq, samples)
    table = new Float32Array(samples)
    # console.log repeat
    sampleat = (point) -> sig(point) + ks_noise_sample(0.3)
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

# async now thanks to audiodata :)
window.playtone = (tone, fn=oudfn, gain=0.2) ->
    freq = tonefreq(tone)
    duration = 2
    current_sample = 0
    last_sample = duration * SRATE
    sigfn = fn(freq)
    source =
        audioParameters: APARAMS
        read: (out) -> 
            if(current_sample >= last_sample) 
                return null
            size = out.length
            written = 0
            while(written < size and current_sample < last_sample) 
                damp = Math.pow(Math.E, -4 * (current_sample/last_sample))
                signal = sigfn(current_sample) + sigfn(current_sample + 3200) * 0.4
                out[written] = gain * signal * damp
                current_sample++
                written++
            return written

    getmixer().addInputSource(source)

