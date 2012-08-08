#
#   Virtual Keyboard
#
#   There are 3 components here:
#
#        - The physical keyboard (computer keyboard)
#        - The virtual keyboard (onscreen keyboard)
#        - The current note layout
#
#    The virtual keyboard essentially maps physical key strokes to notes on the current active layout.
#
#    The note layout is defined in terms of the virtual keyboard; i.e. which note is associated with each virtual key.
#
#    To facilitate this mapping, we use a very simple convention:
#
#    The virtual keyboard consists of rows, each row consists of keys
#
#    Thus, each virtual key can be identified by 2 numbers (a la coordinates) row number, and key number
#

u = _

window.active_tones = [] # THE current piano notes, an array of rows, as returned by get_piano_rows

# Generates the pressable keys that the user uses to play the music
# from the given maqam
# returns a list of tones
gen_piano_rows = (maqam) ->
    octaves = []
    for octave_index in [-1..1]
        segments = maqam.gen_fn(octave_index)
        trailing = u.last(segments[-1], 3) # we want last 2 keys, but the very last key is the same as the first key, so we take 3
        octave = u.union(trailing, segments[0], segments[1], segments[2])
        octave = u.first(octave, 12) # pick first 12 keys (discard more keys if they appear for whatever reason (special maqams like saba, etc))
        octaves.unshift(octave)
    return octaves

gen_tone_kb_map = (piano_rows) ->
    map = {}
    for p_key in get_all_pkeys(piano_rows)
        keydiv = getkeydiv(p_key) # jquery object
        tone = active_tones[p_key.row][p_key.key]
        if tone not of map
            map[tone] = keydiv
        else
            map[tone] = map[tone].add keydiv
    return map

set_maqam = (maqam) ->
    window.active_tones = gen_piano_rows(maqam)
    window.tone_kb_map = gen_tone_kb_map(active_tones)

# ------ keyboard

window.active_layout = {} # mapping from kb_keys to piano keys
window.ui_kb_layout = {}

pkey = (row, key) -> {row, key} # for indexing into actives notes .. active_tones[row][key]

gen_key_layout = (key_rows) ->
    layout = {}
    for r, row in key_rows
        for k, key in r
            layout[k] = pkey(row, key)
    return layout

get_all_pkeys = (piano_rows=window.active_tones) ->
    res = []
    for r, row in piano_rows
        for k, key in r
            res.push pkey(row, key)
    return res

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
    

pkey_id = (p_key) -> "pkey_" + p_key.row + "_" + p_key.key
    
jid = (id) -> $("#" + id)

(->
    note_names = "دو ري مي فا صول لا سي دو".split(" ")
    std_tones = u.zip(
        [0, 9, 16, 23, 31, 40, 47, 53]
        note_names)
    std_tones = _(std_tones).map( (note) -> {tone: note[0], name: note[1]})
    tone_to_note_scope = (tone, tones=std_tones) ->
        if tones[1].tone > tone
            [tones[0], tones[1]]
        else
            tone_to_note_scope(tone, tones[1...])
    window.get_note_name = (tone) ->
        tone = modulo tone, 53
        [note0, note1] = tone_to_note_scope(tone)
        dist = (tone-note0.tone) / (note1.tone-note0.tone)
        if dist < 0.5
            note0.name
        else # if dist >= 0.5
            note1.name
    window.get_note_info = (base_tone) ->
        base_note = get_note_name(base_tone)
        base_note_index = note_names.indexOf(base_note)
        {by_index: (index) ->
            index += base_note_index
            if index < 0
                index += 7
            if index > 7
                index %= 7
            return note_names[index]
        }
)()


init_ui = -> # assumes active_layout and active_tones are already set
    # XXX
    make_key = (p_key)->
        id = pkey_id(p_key)
        keydiv = jQuery(
            "<div class='ib'>
                <div id='#{id}' class='key unpressed'>
                    <div class='kb_key'>&nbsp;</div>
                    <div class='tone'>&nbsp;</div>
                    <div class='note_name'>&nbsp;</div>
                </div>
            </div>")
        keydiv.mousedown(-> play_key(p_key))
        keydiv.mouseup(-> lift_key(p_key))
    jid("keys").text("")
    for r, row in active_tones
        el = $("<div class='row'>")
        for k, key in r
            keydiv = make_key pkey(row, key)
            is_outside_octave_bounds = key not in [2..8]
            if is_outside_octave_bounds
                keydiv.addClass("outside_octave")
            el.append keydiv
        jid("keys").append(el)

update_ui = ->
    base_tone = window.active_tones[1][2] # hack/coupling with kb layout
    note_name_helper = get_note_info(base_tone)
    update_key_div_ui = (p_key) ->
        keydiv = getkeydiv(p_key)
        id = keydiv.attr("id")
        kb_key = ui_kb_layout[id] ? '&nbsp;'
        tone = active_tones[p_key.row][p_key.key]
        note_index = p_key.key - 2 # coupling with kb layout
        note_name = note_name_helper.by_index(note_index)
        $(".kb_key", keydiv).html(kb_key)
        $(".tone", keydiv).html(tone)
        $(".note_name", keydiv).html(note_name)

    for p_key in get_all_pkeys()
        update_key_div_ui p_key
            
init = ->
    init_ui()
    set_kb_layout('qwerty')
    console.log 'init keyboard module'
    updkeys(window.active_maqam) # HACK/RACE

$ init

# ---- handle keyboard presses

key_handler = (e, callback) ->
    if e.ctrlKey or e.metaKey
        return
    special = 
        109: '-'
        189: '-' # chrome
        61: '='
        187: '=' # chrome
        219: '['
        221: ']'
        59: ';'
        186: ';' # chrome
        222: '\''
    if e.which of special
        kbkey = special[e.which]
    else
        kbkey = String.fromCharCode(e.which).toLowerCase()
    e.preventDefault()
    p_key = active_layout[kbkey]
    if not p_key?
        return
    callback(p_key)


down_keys = {}
$(document).keydown( (e)-> key_handler(e, (p_key)->
    if down_keys[e.which] # already pressed, don't handle again
        return false
    down_keys[e.which] = true
    play_key(p_key)
))

play_key = (p_key) ->
    tone = active_tones[p_key.row][p_key.key]
    press_tone(tone)
    playtone(tone)
    div = getkeydiv(p_key)
    j_press(div)

$(document).keyup( (e)-> key_handler(e, (p_key)->
    down_keys[e.which] = false
    lift_key(p_key)
))

lift_key = (p_key) ->
    tone = active_tones[p_key.row][p_key.key]
    unpress_tone(tone)
    div = getkeydiv(p_key)
    j_unpress(div)

press_tone = (tone) ->
    j_semipress tone_kb_map[tone]

unpress_tone = (tone) ->
    j_unpress tone_kb_map[tone]

getkeydiv = (p_key) -> jid(pkey_id(p_key))

tone_class = (tone) ->
    't_' + tone.toString().replace('.', '_')[0...10]

j_press = (jq) ->
    jq.removeClass("semi_pressed").removeClass("unpressed").addClass("pressed")
j_semipress = (jq) ->
    jq.removeClass("unpressed").not(".pressed").addClass("semi_pressed") # what if has class "pressed"??
j_unpress = (jq) ->
    jq.removeClass("pressed").removeClass("semi_pressed").addClass("unpressed")


# -------------------------

modulo = (index, length) ->
    while index < 0
        index += length
    index %= length

fval = (id)-> $("#" + id).val() # field value

window.updkeys = (maqam) ->
    console.log 'Updating keyboard'
    set_maqam(maqam)
    update_ui()

#window.updkeys = u.debounce(updkeys, 100)

