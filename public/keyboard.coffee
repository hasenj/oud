getscalepoint = (scale, point) ->
    # cycling hack
    while point < 0
      point += scale.length
    point %= scale.length
    Number scale[point]

gentones = (scale, starttone, length) ->
    tone = starttone
    tones = []
    for index in [0..length-1]
      tones.push tone
      dist = getscalepoint scale, index
      tone += dist
    return tones

get_octave_bounds = (tones) ->
    bounds = [0]
    current_tone = tones[0]
    for tone, i in tones
        if tone >= current_tone + 6 # 6 == octave length 
            current_tone = tone
            bounds.push(i)
    bounds

fval = (id)-> $("#" + id).val() # field value

window.keys = {}
# window.keyslayout = "9876543WERTYUIKJHGFDSZXCVBNM" # possible alternative
window.keyslayout = "7654321QWERTYUJHGFDSAZXCVBNM"
updkeys = () ->
    # TODO: allow custom layout!!
    keys = keyslayout
    scale = fval("scale").match(/[\d.]+/g)
    start = Number fval("start")
    start -= 6 # add an octave before
    tones = gentones scale, start, keys.length
    octave_bounds = get_octave_bounds tones
    $("#keys").text("")
    for [key, tone], index in _.zip(keys, tones) when key? and tone?
        if (j = _.indexOf(octave_bounds, index)) != -1
            octavediv = $("<div>").addClass "octave"
            if j % 2 == 0
                octavediv.addClass "octave_bg"
            $("#keys").append(octavediv)
        bindkeytone key, tone
window.updkeys = _.debounce(updkeys, 400)

bindhotkey = (key, downfn, upfn) ->
    $(document).bind('keydown', key, downfn)
    $(document).bind('keyup', key, upfn)

genkeyid = (k) -> "key_" + k.charCodeAt(0)
bindkeytone = (key, tone) ->
      window.keys[key] = tone
      downfn = ()-> playkey(key)
      upfn = () -> liftkey(key)
      tonespan = $("<div/>").addClass("tone").html(tone)
      keydiv = $("<div/>").addClass("key").
          attr("id", genkeyid key).html(key).
          mousedown(downfn).mouseup(upfn).
          append(tonespan)
      $("#keys > .octave:last").append(keydiv)
      # TODO make the shortcut more dynamic: grab all keys and determine tone based on the key
      bindhotkey(key, downfn, upfn)

getkeytone = (key) -> window.keys[key]

getkeydiv = (key) -> $("#" + genkeyid key)

downkeys = {}

playkey = (key) ->
    if downkeys[key]
        return # already pressed
    downkeys[key] = true
    tone = getkeytone(key)
    if not tone? 
      return
    div = getkeydiv(key)
    div.stop()
    div.css("background-color", "hsl(210, 95%, 95%)")
    playtone(tone)

liftkey = (key) ->
    downkeys[key] = false
    tone = getkeytone(key)
    if not tone?
      return
    div = getkeydiv(key)
    div.stop()
    div.animate({"background-color": "#fdfdfd"}, 300)

$ updkeys

