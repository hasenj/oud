
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

wavetable = (freq) ->
    periods = 8 # how many periods to cache (to lower frequency distortion)
    samples = periods * SRATE / freq
    samples = Math.round(samples)
    freq = SRATE / (samples / periods)
    k = 2 * Math.PI * freq / SRATE
    table = new Float32Array(samples)
    _sample = (point) -> Math.sin(k * point)
    getsample = (point) ->
        point = point % samples
        if table[point] == 0
            table[point] = _sample(point)
        return table[point]
    return getsample

wavetable = _.memoize(wavetable)


tonefreq = (tone, base=138) ->
   tones_per_octave = 6 # DON'T CHANGE!!
   return base * Math.pow(2, tone/tones_per_octave)

# async now thanks to audiodata :)
window.playtone = (tone) ->
    # TODO add random +/- 0.05 for microtonal variations!!!
    freq = tonefreq(tone)
    pink = 50/freq
    duration = 2.4
    current_sample = 0
    last_sample = duration * SRATE # offbyone?
    wtable = wavetable(freq)
    source =
        audioParameters: APARAMS
        read: (out) -> 
            if(current_sample >= last_sample) 
                return null
            size = out.length
            written = 0
            while(written < size and current_sample < last_sample) 
                x = current_sample / last_sample
                smoother = Math.pow(Math.E, -x * 5)
                wave = wtable(current_sample + 1) + wtable(current_sample) >> 1
                out[written] = pink * smoother * wave
                current_sample++
                written++
            return written

    getmixer().addInputSource(source)

