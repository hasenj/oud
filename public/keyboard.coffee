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
    return tones

get_octave_bounds = (offset, tones) ->
    res = [0, offset]
    cur = tones[offset]
    for t, i in tones
        if t >= cur + 6
            cur = t
            res.push(i)
    res

fval = (id)-> $("#" + id).val() # field value

window.keys = {}
window.keyslayout = "7654321QWERTYUJHGFDSAZXCVBNM"
updkeys = () ->
    # TODO: allow custom layout!!
    keys = keyslayout
    scale = fval("scale").match(/[\d.]+/g)
    # offset = - Number fval("offset")
    offset = -7
    start = Number fval("start")
    tones = gentones scale, start, offset, keys.length
    octave_bounds = get_octave_bounds -offset, tones
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

