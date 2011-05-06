modulo = (index, length) ->
    while index < 0
        index += length
    index %= length

window.cycle_index = (list, index) ->
    index = modulo index, list.length
    list[index]

# array of tone objects. json objects with:
#   w: the tone value (white)
#   b: the super imposed tone value (black) 
gentones = (scale, starttone, length) ->
    starttone -= 6 # start an octave early!
    ctor = (w) -> {w: w, b: w}
    tones = []
    tones.push ctor(starttone)
    last = -> tones[tones.length-1]
    for index in [0..length-1]
      prev = last()
      dist = cycle_index scale, index
      w = prev.w + dist.dist1
      b = w + dist.dist2
      tones.push {w : w, b: b}
    return tones

get_octave_bounds = (tones, start) ->
    bounds = [0]
    while tones[0].w < start
        start -= 6
    for tone, i in tones
        if tone.w >= start + 6 # 6 == octave length 
            start += 6
            bounds.push(i)
    bounds

# TODO fix this!!!!
note_enum_fn = (start_tone) ->
    canonical_notes = [0, 1, 2, 2.5, 3.5, 4.5, 5.5, 6]
    note_names_C = "C D E F G A B".split(" ")
    note_names_DO = "DO RE MI FA SOL LA SI".split(" ")
    # find the start index accordin to starting tone
    first_note = ->
        start_tone = modulo start_tone, 6
        for tone, index in canonical_notes
            nexttone = canonical_notes[index+1]
            if tone <= start_tone < nexttone
                dist1 = Math.abs(start_tone - tone)
                dist2 = Math.abs(nexttone - start_tone)
                if dist1 < dist2
                    return index
                else
                    return index + 1
    index = first_note()
    enumer = ->
        note_names_DO[index++ % note_names_DO.length]

fval = (id)-> $("#" + id).val() # field value

window.keys = {}
window.keyslayout = "7654321QWERTYUIOP;LKJ"
updkeys = ->
    # TODO: allow custom layout!!
    keys = keyslayout
    scale = parse_scale fval("scale")
    start = Number fval("start")
    tones = gentones scale, start, 40
    octave_bounds = get_octave_bounds tones, start
    note_enumer = note_enum_fn(start)
    $("#keys").text("")
    for [key, tone], index in _.zip(keys, tones) when key? and tone?
        if (j = _.indexOf(octave_bounds, index)) != -1
            octavediv = $("<div>").addClass "octave"
            if j % 2 == 0
                octavediv.addClass "alt"
            $("#keys").append(octavediv)
        bindkeytone key, tone, note_enumer()
window.updkeys = _.debounce(updkeys, 400)

bindhotkey = (key, downfn, upfn) ->
    $(document).bind('keydown', key, downfn)
    $(document).bind('keyup', key, upfn)
    $(document).bind('keydown', 'Shift+'+key, downfn)
    $(document).bind('keyup', 'Shift+'+key, upfn)

genkeyid = (k) -> "key_" + k.charCodeAt(0)
bindkeytone = (key, tone, notename) ->
      window.keys[key] = tone
      has_variation = tone.w != tone.b
      downfn = (e) -> playkey(key, e.shiftKey)
      upfn = (e) -> liftkey(key, e.shiftKey)
      tone_e = $("<div/>").addClass("tone")
      tone_w = $("<div/>").addClass("tone_w").html(tone.w)
      tone_b = $("<div/>").addClass("tone_b").html(tone.b).hide()
      tone_e.append(tone_w).append(tone_b)
      notename_e = $("<div/>").addClass("notename").html(notename)
      keydiv = $("<div/>").addClass("key unpressed").
          attr("id", genkeyid key).html(key).
          mousedown(downfn).mouseup(upfn).
          append(tone_e).append(notename_e)
      if has_variation
          vhint = $("<div/>").addClass("has_variation").hide()
          keydiv.append(vhint)
      $("#keys > .octave:last").append(keydiv)
      bindhotkey(key, downfn, upfn)

show_maqam_variation = ->
    $(".tone_w").hide()
    $(".tone_b").show()
    $(".has_variation").parent().addClass("vhint")

show_maqam_original = ->
    $(".tone_w").show()
    $(".tone_b").hide()
    $(".has_variation").parent().removeClass("vhint")

$(document).bind('keydown', 'shift', show_maqam_variation)
$(document).bind('keyup', 'shift', show_maqam_original)

getkeytone = (key) -> window.keys[key]

getkeydiv = (key) -> $("#" + genkeyid key)

downkeys = {}

playkey = (key, black) ->
    if downkeys[key]
        return # already pressed
    downkeys[key] = true
    tone = getkeytone(key)
    if not tone? 
      return
    if black
        tone = tone.b
    else
        tone = tone.w
    div = getkeydiv(key)
    div.stop(true, true)
    # div.css("background-color", "hsl(210, 95%, 95%)")
    div.addClass("pressed").removeClass("unpressed")
    playtone(tone)

liftkey = (key) ->
    downkeys[key] = false
    tone = getkeytone(key)
    if not tone?
      return
    div = getkeydiv(key)
    div.stop(true, true)
    # div.animate({"background-color": "#fdfdfd"}, 300)
    div.removeClass("pressed").addClass("unpressed")

$ updkeys

