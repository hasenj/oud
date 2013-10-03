mkbuf = (len) ->
    new Float32Array Math.floor len

CHANNELS = 1

SRATE = 44100

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

DURATION = 2
GAIN = 0.8
SIGNAL_LEN = DURATION * SRATE * CHANNELS

# just for the dampness
dampness = do ->
    down = (val) -> Math.max 0, val - 0.3
    # e ^ (-2x) - 0.2 # (without going below 0)
    for point in [0..SIGNAL_LEN]
        down(Math.pow(Math.E, -2 * (point/SIGNAL_LEN)))

# karplus strong algorithm
string_type_factory = (wave_shape, noise_sample_param) ->
    signal_gen = (freq) ->
        buffer = mkAudioBuf(SIGNAL_LEN)
        signal = buffer.getChannelData(0)
        table_len = period_len freq
        table = mkbuf(table_len)
        base_sample = wave_shape_to_sample(wave_shape, table_len)
        # first apply white nose to the base sample
        for s, index in base_sample
            table[index] = base_sample[index] + ks_noise_sample(noise_sample_param)
        for s, index in signal
            point = index % table_len
            adj = (table_len + index - 1) % table_len
            table[point] = avg(table[point], table[adj])
            # XXX maybe the dampness can be done by a wave shaper node or something?!
            signal[index] = table[point] * dampness[index] * GAIN
        return buffer

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

window.play_freq = (freq) ->
    buffer = oud_signal_gen(freq)
    play_signal(buffer)

# Based on code from: http://www.html5rocks.com/en/tutorials/webaudio/intro/
# Fix up prefixing
window.AudioContext = window.AudioContext || window.webkitAudioContext
window.context = null

init_context = ->
    console.log("Initializing Audio Context")
    try
        window.context = new AudioContext()
    catch error # AudioContext not available
        alert("Your browser does not implement Web Audio API")

window.addEventListener('load', init_context)

mkAudioBuf = (len) ->
    context.createBuffer(CHANNELS, len, SRATE)

# buffer: an AudioBuffer instance
window.play_signal = (buffer)->
    if not context
        console.log("Audio Context not Initialized yet!")
        # retry = -> play_signal(buffer)
        # setTimeout(retry, 500)
        return
    source = context.createBufferSource();    # creates a sound source
    source.buffer = buffer
    source.connect(context.destination) # connect the source to the context's destination (the speakers)
    if source.start
        source.start(0)
    else if source.noteOn
        source.noteOn(0)
