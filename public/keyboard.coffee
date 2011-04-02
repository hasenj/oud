getscalepoint = (scale, point) ->
    # cycling hack
    while point < 0
      point += scale.length
    point %= scale.length
    Number scale[point]

# startoffset: add a few tones before the starting tone
gennotes = (scale, starttone, offset, length) ->
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
    console.log tones
    return tones

fval = (id)-> $("#" + id).val() # field value

window.keys = {}
updkeys = () ->
    keys = "QWERTYUIOPASDFGH"
    scale = fval("scale").match(/[\d.]+/g)
    offset = Number fval("offset")
    start = Number fval("start")
    tones = gennotes scale, start, offset, keys.length
    $("#keys").text("")
    for [key, tone] in _.zip(keys, tones) when key and tone
      bindkeytone key, tone
window.updkeys = _.debounce(updkeys, 400)

bindhotkey = (key, downfn, upfn) ->
    shortcut.add(key, downfn)
    shortcut.add(key, upfn, {"type": "keyup"})

bindkeytone = (key, tone) ->
      window.keys[key] = tone
      $("#keys").append("<div class='key' id='key_" + key + "'> " + key + " <br> " + tone)
      # TODO make the shortcut more dynamic: grab all keys and determine tone based on the key
      downfn = ()-> playkey(key)
      upfn = () -> liftkey(key)
      bindhotkey(key, downfn, upfn)

getkeytone = (key) -> window.keys[key] # TODO convert to upper case first

getkeydiv = (key) -> $("#key_" + key)

playkey = (key) ->
    tone = getkeytone(key)
    if not tone 
      return
    getkeydiv(key).stop()
    getkeydiv(key).css("background-color", "hsl(200, 40%, 80%)")

liftkey = (key) ->
    tone = getkeytone(key)
    if not tone 
      return
    getkeydiv(key).stop()
    getkeydiv(key).animate({"background-color": "white"}, 300)

updkeys()

