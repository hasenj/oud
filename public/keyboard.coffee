window.cycle_index = (list, index) ->
    while index < 0
        index += list.length
    index %= list.length
    list[index]

gentones = (scale, starttone, length) ->
    tone = starttone
    tones = []
    for index in [0..length-1]
      tones.push tone
      dist = cycle_index scale, index
      tone += dist.dist1
    return tones

get_octave_bounds = (tones) ->
    bounds = [0]
    current_tone = tones[0]
    for tone, i in tones
        if tone >= current_tone + 6 # 6 == octave length 
            current_tone = tone
            bounds.push(i)
    bounds

note_enum_fn = (start_tone) ->
    canonical_notes = [0, 1, 2, 2.5, 3.5, 4.5, 5.5, 6]
    note_names_C = "C D E F G A B".split(" ")
    note_names_DO = "DO RE MI FA SOL LA SI".split(" ")
    # find the start index accordin to starting tone
    first_note = ->
        while start_tone < 0
            start_tone += 6
        start_tone %= 6
        for tone, index in canonical_notes
            nexttone = canonical_notes[index+1]
            if tone <= start_tone < nexttone
                return index
    index = first_note()
    enumer = ->
        note_names_DO[index++ % note_names_DO.length]




fval = (id)-> $("#" + id).val() # field value

window.keys = {}
# window.keyslayout = "9876543WERTYUIKJHGFDSZXCVBNM" # possible alternative
window.keyslayout = "7654321QWERTYUJHGFDSAZXCVBNM"
updkeys = ->
    # TODO: allow custom layout!!
    keys = keyslayout
    scale = parse_scale fval("scale")
    start = Number fval("start")
    tones = gentones scale, start - 6, keys.length # start - 6 for previous octave
    octave_bounds = get_octave_bounds tones
    note_enumer = note_enum_fn(start)
    $("#keys").text("")
    for [key, tone], index in _.zip(keys, tones) when key? and tone?
        if (j = _.indexOf(octave_bounds, index)) != -1
            octavediv = $("<div>").addClass "octave"
            if j % 2 == 0
                octavediv.addClass "octave_bg"
            $("#keys").append(octavediv)
        bindkeytone key, tone, note_enumer()
window.updkeys = _.debounce(updkeys, 400)

bindhotkey = (key, downfn, upfn) ->
    $(document).bind('keydown', key, downfn)
    $(document).bind('keyup', key, upfn)

genkeyid = (k) -> "key_" + k.charCodeAt(0)
bindkeytone = (key, tone, notename) ->
      window.keys[key] = tone
      downfn = -> playkey(key)
      upfn = -> liftkey(key)
      tone_e = $("<div/>").addClass("tone").html(tone)
      notename_e = $("<div/>").addClass("notename").html(notename)
      keydiv = $("<div/>").addClass("key").
          attr("id", genkeyid key).html(key).
          mousedown(downfn).mouseup(upfn).
          append(tone_e).append(notename_e)
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

