
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

round_to = (num, factor) ->
    num *= 1/factor
    num = Math.round(num)
    num *= factor
    return num

avg = (a, b) -> (a + b) / 2

_period_len_of_freq = (freq) ->
    # not accurate; results in a slight change (distortion) of the original frequency, but this change is acceptable
    # returns [samples, freq] where `samples` is the number of samples (period length) and `freq` is the changed frequency
    # TODO perhaps this is a bit of a complication and we can ignore the change in freq?
    periods = 8 # how many periods to cache (to lower frequency distortion)
    samples = periods * SRATE / freq
    samples = Math.round(samples)
    freq = SRATE / (samples / periods)
    return [samples, freq]

_period_len_of_freq = _.memoize(_period_len_of_freq)

# same as above, but only gets the period length in samples
period_len = (freq) -> _period_len_of_freq(freq)[0]

wavetable = (freq) ->
    [samples, freq] = _period_len_of_freq(freq)
    k = 2 * Math.PI * freq / SRATE
    table = new Float32Array(samples)
    sine = (point) -> Math.sin(k * point)
    getsample = (index) ->
        point = index % samples
        if index == point
            table[point] = sine(point)
        else
            prev = (index - 1) % samples
            table[point] = 0.45 * (table[point] + table[prev])

wavetable = _.memoize(wavetable)

tonefreq = (tone, base=138) ->
   tones_per_octave = 6 # DON'T CHANGE!!
   return base * Math.pow(2, tone/tones_per_octave)

# async now thanks to audiodata :)
window.playtone = (tone) ->
    freq = tonefreq(tone)
    gain = 5/Math.pow(freq, 0.5)
    gain *= 0.4
    duration = 3.2
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
                # x = current_sample / last_sample
                # smoother = Math.pow(Math.E, -x * 5)
                signal = wtable(current_sample)
                out[written] = gain * signal
                current_sample++
                written++
            return written

    getmixer().addInputSource(source)

