getscalepoint = (scale, point) ->
    # cycling hack
    while point < 0
      point += scale.length
    point %= scale.length
    Number scale[point]

# startoffset: add a few tones before the starting tone
gentones = (scale, starttone, offset, length) ->
    tone = starttone
    tones = []
    for index in [0..length-offset-1]
      tones.push tone
      tone += getscalepoint scale, index
    if offset < 0
      tone = starttone
      for index in [-1..offset]
        tone -= getscalepoint scale, index
        tones.unshift tone
    if offset > 0
        for index in [0..offset-1]
            tones.shift()
    # console.log tones
    return tones

fval = (id)-> $("#" + id).val() # field value

window.keys = {}
window.keyslayout = "QWERTYUIOPLKJHGFDSAZXCVBNM"
updkeys = () ->
    # TODO: allow custom layout!!
    keys = keyslayout
    scale = fval("scale").match(/[\d.]+/g)
    offset = - Number fval("offset")
    start = Number fval("start")
    tones = gentones scale, start, offset, keys.length
    $("#keys").text("")
    for [key, tone] in _.zip(keys, tones) when key? and tone?
      bindkeytone key, tone
window.updkeys = _.debounce(updkeys, 400)

bindhotkey = (key, downfn, upfn) ->
    $(document).bind('keydown', key, downfn)
    $(document).bind('keyup', key, upfn)

bindkeytone = (key, tone) ->
      window.keys[key] = tone
      tonespan = $("<div/>").addClass("tone").html(tone)
      keydiv = $("<div/>").addClass("key").attr("id", "key_" + key).html(key).append(tonespan)
      $("#keys").append(keydiv)
      # TODO make the shortcut more dynamic: grab all keys and determine tone based on the key
      downfn = ()-> playkey(key)
      upfn = () -> liftkey(key)
      bindhotkey(key, downfn, upfn)

getkeytone = (key) -> window.keys[key] # TODO convert to upper case first?

getkeydiv = (key) -> $("#key_" + key)

tonefreq = (tone) ->
   base = 220 # ok to change (only to experiment with a different base)
   steps = 6 # DON'T CHANGE!!
   return base * Math.pow(2, tone/steps)

SRATE = 44100

makechannel = () ->
    try
        channel = new Audio()
        channel.mozSetup(1, SRATE)
        return channel
    catch error
        console.log "mozSetup failed:", error


channels = []
for i in [0..5] # number of channels
    channels.push makechannel()

#debug
window.cs = channels

_ch = 0
getchannel = () -> # get a free audio channel
    # for c in channels
        # if c.paused
        #    return c
        # # check
        # else
        #    console.log "this channel is busy"
    _ch += 1
    _ch = _ch % channels.length
    # if _ch == 0
    #   console.log "all channels cycled"
    channels[_ch]

getkeychannel = (key) ->
    if not channels[key]
        channels[key] = makechannel()
    channels[key]

samplelog = (i, s) ->
    if i % 700 == 0
        console.log i, " : ", s

genwave = (freq) ->
    duration = 2.4
    length = SRATE * duration
    samples = new Float32Array(length)
    k = 2 * Math.PI * freq / SRATE
    # adapt gain to the frequency (pink noise)
    gain = 200/freq
    sinegen = (i) -> Math.sin(k * i)
    smoothergen = (i) ->
        x = i / length
        s = Math.pow(Math.E, -x * duration * 10)
        # samplelog(i, s)
        s
    for s,i in samples
        w = sinegen(i) # the sine wave of the tone
        s = smoothergen(i) # a smoother (to ger rid of clicking sound)
        samples[i] = w * s * gain
    return samples
# cache results!!
genwave = _.memoize(genwave)

playtone = (tone) ->
    # TODO add random +/- 0.05 for microtonal variations!!!
    channel = getchannel()
    if not channel?
        return false
    freq = tonefreq(tone)
    channel.mozWriteAudio(genwave freq)

downkeys = {}

playkey = (key) ->
    if downkeys[key]
        return # already pressed
    downkeys[key] = true
    tone = getkeytone(key)
    if not tone? 
      return
    getkeydiv(key).stop()
    getkeydiv(key).css("background-color", "hsl(210, 90%, 90%)")
    playtone(tone)

liftkey = (key) ->
    downkeys[key] = false
    tone = getkeytone(key)
    if not tone?
      return
    getkeydiv(key).stop()
    getkeydiv(key).animate({"background-color": "#fdfdfd"}, 300)

updkeys()

####
# maqam presets


maqam_presets = 
    ajam: ["0", "1 1 0.5 1 1 1 0.5", "0"]
    nahawand: ["0", "1 0.5 1 1 0.5 1.5 0.5", "0"]
    hijaz1: ["1", "0.5 1.5 0.5 1 0.75 0.75 1", "2"]
    hijaz2: ["1", "0.5 1.5 0.5 1 0.5 1 1", "2"]
    bayati: ["1", "0.75 0.75 1 1 0.5 1 1", "2"]
    rast1: ["0", "1 0.75 0.75 1 1 0.75 0.75", "0"]
    rast2: ["0", "1 0.75 0.75 1 1 0.5 1", "0"]
    rast_comb: ["0", "1 0.75 0.75 1 1 0.5 0.25 0.75", "0"]
    jiharkah: ["4", "1 1 0.5 1 1 0.75 0.75", "0"]
    saba1: ["1", "0.75 0.75 0.5 1.5 0.5 1 1", "2"]
    saba2: ["1", "0.75 0.75 0.5 1.5 0.5 1 0.5 1.5 0.5 0.75 1", "2"]

choose_maqam = (name) ->
    [start, scale, offset] = maqam_presets[name]
    $("#start").val(start)
    $("#scale").val(scale)
    $("#offset").val(offset)
    updkeys()

# building preset list
p = $("#presets")
for name of maqam_presets
    option = $("<option>").html(name).attr("val", name)
    p.append(option)
p.change(() => choose_maqam(p.val()))
p.change() # trigger the choosing of the first element!
