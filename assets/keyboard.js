/*

   Virtual Keyboard

   There are 3 components here:

        - The physical keyboard (computer keyboard)
        - The virtual keyboard (onscreen keyboard)
        - The current note layout

    The virtual keyboard essentially maps physical key strokes to notes on the current active layout.

    The note layout is defined in terms of the virtual keyboard; i.e. which note is associated with each virtual key.

    To facilitate this mapping, we use a very simple convention:

    The virtual keyboard consists of rows, each row consists of keys

    Thus, each virtual key can be identified by 2 numbers (a la coordinates) row number, and key number

*/

u = _

// octave row
function OctaveVM(octave, koMaqam) { 
    // octave is the octave index
    // koMaqam is the observable active maqam
    var self = this;
    self.tones = ko.computed( function() {
        var maqam = koMaqam();
        if (maqam) {
            return maqam.tones();
        }
        else {
            return [];
        }
    }
    return self;
}

function MaqamVM() {
    var self = this
    self.maqam = ko.observable(null)
    self.octaves = {}
    for(var i = -1; i <= 1; i++) {
        self.octaves[i] = new OctaveVM(i, self.maqam)
    }

    // find the tone for the key in the octave, returning null if one can't be found
    self.octaveKeyTone = function(octave, key) {
        var ovm = self.octaves[octave]
        if(!ovm) {
            return null;
        }

        var keys = ovm.keys()
        if(!keys) {
            return null;
        }

        var tone = keys[key]
        if(!tone) {
            if(key > 8) {
                // find the key from the next octave ..
                return self.octaveKeyTone(octave+1, key-7);
            } else(if key < 0) {
                // find the key from the previous octave
                return self.octaveKeyTone(octave-1, key+7);
            } else {
                return null;
            }
        }
        return tone
    }

    return self;
}

class VirtualKeyVM
    constructor: (row, column) ->
        # first row is "previous" octave
        @octave_index = row - 1
        # we shift the keyboard by 2 keys
        @key_index = column - 2

        self = this

        @tone = ko.computed ->
            return viewmodel.maqam().octaveKeyTone(self.octave_index, self.key_index)
        @letter = ko.computed ->
            viewmodel.kbLayout().letter(row, column)

        @pressed = ko.observable(false)
        @semi_pressed = ko.observable(false)

        @state_class = ko.computed ->
            if @pressed()
                return "pressed"
            if @semi_pressed()
                return "semi_pressed"
            return "unpressed"

    play: ->
        playtone(@tone())

    press: ->
        @pressed(true)
    unpress: ->
        @pressed(false)

    semi_press: ->
        @semi_pressed(true)
    unsemi_press: ->
        @semi_pressed(false)

class KeyboardLayout
    constructor: (@rows) ->

    letter: (row_index, col_index) ->
        row = @rows[row_index]
        if not row
            return ""
        val = row[col_index]
        if not val
            return ""
        return val

std_layouts = {} # standard keyboard layouts .. to choose from; e.g. qwerty, azerty, .. etc
std_layouts['qwerty'] = ["1234567890-=", "qwertyuiop[]", "asdfghjkl;'"]

qwerty = new KeyboardLayout(std_layouts['qwerty'])

class GlobalViewModel
    constructor: ->
        default_maqam = $.cookie('maqam') ? 'ajam'
        @maqam = ko.observable(maqamat[default_maqam])
        @kbLayout = ko.observable(qwerty)

        key_list = []
        @vkb_rows = []
        for i in [0..2]
            @vkb_rows.push([])
            for j in [0..12]
                kvm = new VirtualKeyVM(i, j)
                @vkb_rows[i].push(kvm)
                key_list.push(kvm)

        

$ ->
    window.viewmodel = new GlobalViewModel()
    ko.applyBindings(window.viewmodel)

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

# ------ keyboard


# what is this mess OMG
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
        {
            by_index: (index) ->
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
    keyvm = viewmodel.findKey(kbkey)
    if not keyvm
        return
    tone = keyvm.tone()
    if not tone
        return
    tone_keys = viewmodel.findKeysByTone(tone)
    callback(keyvm, tone_keys)

$(document).keydown( (e)-> key_handler(e, (keyvm, secondary_keys)->
    if keyvm.pressed() # already pressed, don't handle again
        return false
    for key in secondary_keys
        key.semi_press()
    key.press()
    key.play()
))

$(document).keyup( (e)-> key_handler(e, (keyvm, secondary_keys)->
    for key in secondary_keys
        key.unsemi_press()
    key.unpress()
))

# -------------------------

modulo = (index, length) ->
    while index < 0
        index += length
    index %= length


