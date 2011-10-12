last = (array) -> 
    array[array.length-1]

from_end = (array, start, end) -> # subarray from end
    # start and end must be given as negative numbers
    len = array.length
    array[len+start...len+end]

window.std_scale = (scale, start=0) ->
    # applies 'scale' (a list of tonal distances) to 'start' (a tone)
    # and return a list of tones
    res = [start]
    for tone in scale
        res.push(tone + last(res))
    return res

#console.log std_scale [1, 1, 0.5, 1, 1, 1, 0.5]
#console.log std_scale [1, 1, 0.5, 1, 1, 0.5]

window.active_tones = [] # THE current piano notes, an array of rows, as returned by get_piano_rows

gen_piano_rows = (scale, start) ->
    octaves = {}
    get_octave_start = (i) -> start + i * 6
    octave_starts = (start + (i * 6) for i in [-2..2])
    for i in [-2..2]
        octave_start = get_octave_start(i)
        octaves[octave_start] = std_scale(scale, octave_start)
    get_row = (octave_start) ->
        res = []
        # last two keys of previous octave
        prev_o = octaves[octave_start-6]
        curr_o = octaves[octave_start]
        next_o = octaves[octave_start+6]
        res = from_end(prev_o, -3, -1).concat(curr_o).concat(next_o[1...3])

    for i in [-1..1]
        get_row(get_octave_start(i))

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

#console.log gen_piano_rows [1, 1, 0.5, 1, 1, 1, 0.5], 0

set_maqam = (maqam) ->
    window.active_tones = gen_piano_rows(maqam.scale, maqam.start)
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


update_key_div_ui = (p_key) ->
    keydiv = getkeydiv(p_key)
    id = keydiv.attr("id")
    kb_key = ui_kb_layout[id] ? '&nbsp;'
    tone = active_tones[p_key.row][p_key.key]
    note_name = get_note_name(tone) #"DO"
    $(".kb_key", keydiv).html(kb_key)
    $(".tone", keydiv).html(tone)
    $(".note_name", keydiv).html(note_name)

init_ui = -> # assumes active_layout and active_tones are already set
    # XXX
    make_key = (p_key)->
        id = pkey_id(p_key)
        keydiv = jQuery(
            "<div id='#{id}' class='key unpressed'>
                <div class='kb_key'>&nbsp;</div>
                <div class='tone'>&nbsp;</div>
                <div class='tone_shift'>&nbsp;</div>
                <div class='note_name'>&nbsp;</div>
            </div>")
        keydiv.mousedown(-> play_key(p_key))
        keydiv.mouseup(-> lift_key(p_key))
    jid("keys").text("")
    for r, row in active_tones
        el = $("<div class='row'>")
        for k, key in r
            el.append make_key pkey(row, key)
        jid("keys").append(el)

update_ui = ->
    for r, row in active_tones
        for k, key in r
            update_key_div_ui(pkey(row, key))
            
init = ->
    set_maqam( {scale: [0.75, 0.75, 0.5, 1.5, 0.5, 1, 1], alt_scale:[0.75, 0.75, 0.5, 1.5, 0.5, 1, 0.5], start: 1} )
    set_kb_layout('qwerty')
    init_ui()
    update_ui()

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
    div.stop(true, true)
    j_press(div)

$(document).keyup( (e)-> key_handler(e, (p_key)->
    down_keys[e.which] = false
    lift_key(p_key)
))

lift_key = (p_key) ->
    tone = active_tones[p_key.row][p_key.key]
    unpress_tone(tone)
    div = getkeydiv(p_key)
    div.stop(true, true)
    j_unpress(div)

press_tone = (tone) ->
    j_semipress tone_kb_map[tone]

unpress_tone = (tone) ->
    j_unpress tone_kb_map[tone]

getkeydiv = (p_key) -> jid(pkey_id(p_key))

jcls = (cls) -> $('.' + cls)
tone_class = (tone) ->
    't_' + tone.toString().replace('.', '_')[0...10]

j_press = (jq) ->
    jq.removeClass("semi_pressed").removeClass("unpressed").addClass("pressed")
j_semipress = (jq) ->
    jq.removeClass("unpressed").not(".pressed").addClass("semi_pressed") # what if has class "pressed"??
j_unpress = (jq) ->
    jq.removeClass("pressed").removeClass("semi_pressed").addClass("unpressed")


# --------------------------------------------------------------------------

modulo = (index, length) ->
    while index < 0
        index += length
    index %= length

fval = (id)-> $("#" + id).val() # field value

window.updkeys = (maqam) ->
    set_maqam(maqam)
    update_ui()

#window.updkeys = _.debounce(updkeys, 100)

