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

tonefreq = (tone, base=138*2) ->
   tones_per_octave = 6 # DON'T CHANGE!!
   return base * Math.pow(2, tone/tones_per_octave)

SRATE = 44100
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
        console.log "mozSetup failed:", error
        $("#error_box").text("Error initializing audio output. Reload the page (if that fails, you might have to restart the browser)!").show()
        return { addInputSource: () -> } # dummy mixer

samplelog = (id, s...) ->
    if id not of samplelog
        samplelog[id] = 0
    samplelog[id] += 1
    if samplelog[id] % 20 == 0
        console.log s...


# async now thanks to audiodata :)
playtone = (tone) ->
    # TODO add random +/- 0.05 for microtonal variations!!!
    freq = tonefreq(tone)
    duration = 4
    gain = _.min([0.2, 160/freq])
    currentSoundSample = 0
    last_sample = duration * SRATE
    # @falloff_start = last_sample * 0.6
    calls_to_read = 0
    source =
        audioParameters: APARAMS
        read: (out) -> 
            calls_to_read++
            if(currentSoundSample >= last_sample) 
                # console.log(currentSoundSample)
                console.log("ok, calls to read:", calls_to_read)
                return null
            size = out.length
            samplelog("os", "output size:", size)
            k = 2 * Math.PI * freq / SRATE
            written = 0
            while(written < size and currentSoundSample < last_sample) 
                x = currentSoundSample / last_sample
                s = Math.pow(Math.E, -x * 4)
                # s = 1
                out[written] = s * gain * Math.sin(k * currentSoundSample)
                currentSoundSample++
                written++
            return written

    getmixer().addInputSource(source)

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
    kurd: ["1", "0.5 1 1 1 0.5 1 1", "0"]
    hijaz_kar_kurd: ["0", "0.5 1.5 0.5 1 0.5 1.5 0.5", "0"]
    hijaz1: ["1", "0.5 1.5 0.5 1 0.75 0.75 1", "2"]
    hijaz2: ["1", "0.5 1.5 0.5 1 0.5 1 1", "2"]
    nahawand: ["0", "1 0.5 1 1 0.5 1.5 0.5", "0"]
    rast1: ["0", "1 0.75 0.75 1 1 0.75 0.75", "0"]
    rast2: ["0", "1 0.75 0.75 1 1 0.5 1", "0"]
    rast_comb: ["0", "1 0.75 0.75 1 1 0.5 0.25 0.75", "0"]
    bayati: ["1", "0.75 0.75 1 1 0.5 1 1", "2"]
    husseini: ["1", "0.75 0.75 1 1 0.75 0.75 1", "0"]
    jiharkah: ["4", "1 1 0.5 1 1 0.75 0.75", "0"]
    saba1: ["1", "0.75 0.75 0.5 1.5 0.5 1 1", "2"]
    saba2: ["1", "0.75 0.75 0.5 1.5 0.5 1 0.5 1.5 0.5 0.75 1", "2"]
    sikah1: ["1.25", "0.75 1 1 0.75 0.75 1 0.75", "0"]
    sikah2: ["1.25", "0.75 1 1 0.5 1 1 0.75", "0"]
    huzam: ["1.25", "0.75 1 0.5 1.5 0.5 1 0.75", "0"]
    rahatelarwah: ["5.25", "0.75 1 0.5 1.5 0.5 1 0.75", "0"]
    iraq: ["5.25", "0.75 1 0.75 0.75 1 1 0.75", "0"]
    nawa_athar: ["0", "1 0.5 1.5 0.5 0.5 1.5 0.5", "0"]

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
