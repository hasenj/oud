std_scale = (scale, limit=false) ->
    # returns the scale applies to 0 as starting point
    # assumes 'scale' is nothing more than a list of distances
    scale = _.clone(scale)
    res = [0]
    while scale.length
        res.push(scale.shift() + res[res.length-1])
    if limit
        res[1...limit+1] # HACK: if we want a limit, we're making a continuation and we don't want to repeat the last note!!
    else
        res

#console.log std_scale [1, 1, 0.5, 1, 1, 1, 0.5]
#console.log std_scale [1, 1, 0.5, 1, 1, 0.5]

rev_scale = (scale, limit) ->
    scale = _.clone(scale)
    scale.reverse()
    res = [0]
    while scale.length
        res.push(res[res.length-1] - scale.shift())
    if limit
        res = res[1...limit+1]
    else
        res = res[1...res.length]
    res.reverse()

# unit tests?
#console.log rev_scale [1,1,0.5, 1,1,0.5] # [-5, -4, -3, -2.5, -1.5, -0.5]
#console.log rev_scale [1,1,0.5, 1,1,0.5], 3 # [-2.5, -1.5, -0.5]


shift_notes_by = (notes, x) ->
    n + x for n in notes

gen_key_row = (scale, start, backlimit, forelimit) ->
    s0 = rev_scale(scale, backlimit)
    s1 = std_scale(scale)
    s2 = std_scale(scale, forelimit)
    s2 = shift_notes_by(s2, s1[s1.length-1])
    row = s0.concat(s1).concat(s2)
    shift_notes_by(row, start)

window.active_notes = [] # THE current piano notes, an array of rows, as returned by get_piano_rows
window.alt_notes = [] # when shift is pressed

gen_piano_rows = (scale, start) ->
    [gen_key_row(scale, start-6, 2, 2)
    gen_key_row(scale, start, 2, 2)
    gen_key_row(scale, start+6, 2, 1)]

#console.log gen_piano_rows [1, 1, 0.5, 1, 1, 1, 0.5], 0

set_maqam = (maqam) ->
    window.active_notes = gen_piano_rows(maqam.scale, maqam.start)
    window.alt_notes = gen_piano_rows(maqam.alt_scale, maqam.start)


# ------ keyboard

window.active_layout = {} # mapping from kb_keys to piano keys
window.ui_kb_layout = {}

pkey = (row, key) -> {row, key} # for indexing into actives notes .. active_notes[row][key]

gen_key_layout = (key_rows) ->
    layout = {}
    for r, row in key_rows
        for k, key in r
            layout[k] = pkey(row, key)
    return layout

#console.log gen_key_layout ["1234567890-=", "qwertyuiop[]", "asdfghjkl;'"]

std_layouts = {} # standard keyboard layouts .. to choose from; e.g. qwerty, azerty, .. etc
std_layouts['qwerty'] =  gen_key_layout ["1234567890-=", "qwertyuiop[]", "asdfghjkl;'"]

gen_ui_kb_mapping = (layout) ->
    mapping = {}
    for kb_key of layout
        if kb_key.charCodeAt(0) < 255
            id = pkey_id(layout[kb_key])
            mapping[id] = kb_key.toUpperCase()
    return mapping

set_kb_layout = (layout_code) ->
    if not layout_code of std_layouts
        console.log "invalid layout code:", layout_code
        return
    window.active_layout = std_layouts[layout_code]
    window.ui_kb_layout = gen_ui_kb_mapping(active_layout)
    

pkey_id = (pkey) -> "pkey_" + pkey.row + "_" + pkey.key
    
jid = (id) -> $("#" + id)

update_ui = -> # assumes active_layout and active_notes are already set
    # XXX
    make_key = (p_key)->
        id = pkey_id(p_key)
        kb_key = ui_kb_layout[id] # TODO: a global var
        tone = active_notes[p_key.row][p_key.key]
        alt_tone = alt_notes[p_key.row][p_key.key]
        note_name = get_note_name(tone) #"DO"
        "<div id='#{id}' class='key unpressed'>
            <div class='bk_key'>#{kb_key}</div>
            <div class='tone'>#{tone}</div>
            <div class='tone_shift'>#{alt_tone}</div>
            <div class='note_name'>#{note_name}</div>
        </div>"
    jid("keys").text("")
    for r, row in active_notes
        el = $("<div class='row'>")
        for k, key in r
            el.append make_key pkey(row, key)
        jid("keys").append(el)
            
init = ->
    set_maqam( {scale: [1, 1, 0.5, 1, 1, 1, 0.5], alt_scale:[1, 0.75, 0.75, 1, 1, 0.75, 0.75], start: 0} )
    set_kb_layout('qwerty')
    update_ui()

$ init


get_note_name = (tone) ->
    std_tones = [0, 1, 2, 2.5, 3.5, 4.5, 5.5, 6]
    names = "DO RE MI FA SOL LA SI".split(" ")
    tone = modulo tone, 6
    for t0, index in std_tones
        t1 = std_tones[index+1]
        if t0 <= tone < t1
            dist = (tone-t0) / (t1-t0)
            if dist < 0.5
                return names[index]
            else
                return names[index+1]
# --------------------------------------------------------------------------

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
window.keyslayout = "1234567QWERTYUIOPASDF"
# entry point of this module (exposed below)
updkeys = (maqam) ->
    return
    # TODO: allow custom layout!!
    keys = keyslayout
    scale = maqam.scale
    start = maqam.start
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


