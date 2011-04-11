
SRATE = 96000
APARAMS = new AudioParameters(1, SRATE)      

# Thanks to 'yury' from #audio@irc.mozilla.org
getmixer = () ->
    try
        if window.mixer 
            return window.mixer
        mixer = new AudioDataMixer(APARAMS)
        audio_output = new AudioDataDestination(APARAMS)
        audio_output.autoLatency = true
        audio_output.writeAsync(mixer)
        window.mixer = mixer
        return mixer
    catch error # not sure if the exception would happen here
        if $.browser.mozilla and $.browser.version >= 2
            console.log "mozSetup failed:", error
            $("#error_box").text("Error initializing audio output. Reload the page (if that fails, you might have to restart the browser)!").show()
        else
            $("#error_box").text("Only Firefox4 is supported").show()
        return { addInputSource: () -> } # dummy mixer

$ getmixer

period_len = (freq) -> Math.floor (SRATE/freq)

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

# karplus strong algorithm
guitar = (freq) ->
    samples = period_len freq
    table = new Float32Array(samples)
    getsample = (index) ->
        point = index % samples
        if index == point
            table[point] = ks_noise_sample(1)
        else
            prev = (index - 1) % samples
            table[point] = avg(table[point], table[prev])

tonefreq = (tone, base=138) ->
   tones_per_octave = 6 # DON'T CHANGE!!
   return base * Math.pow(2, tone/tones_per_octave)

# async now thanks to audiodata :)
window.playtone = (tone) ->
    freq = tonefreq(tone)
    gain = 0.5
    duration = 3
    current_sample = 0
    last_sample = duration * SRATE
    sigfn = guitar(freq)
    source =
        audioParameters: APARAMS
        read: (out) -> 
            if(current_sample >= last_sample) 
                return null
            size = out.length
            written = 0
            while(written < size and current_sample < last_sample) 
                damp = Math.pow(Math.E, -2 * (current_sample/last_sample))
                signal = sigfn(current_sample)
                out[written] = gain * signal * damp
                current_sample++
                written++
            return written

    getmixer().addInputSource(source)

