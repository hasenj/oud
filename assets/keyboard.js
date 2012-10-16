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
    self.tones = ko.computed(function() {
        var maqam = koMaqam();
        if (maqam) {
            return maqam.tones();
        }
        else {
            return [];
        }
    })
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

        var keys = ovm.tones()
        if(!keys) {
            return null;
        }

        var tone = keys[key]
        if(!tone) {
            if(key > 8) {
                // find the key from the next octave ..
                return self.octaveKeyTone(octave+1, key-7);
            } else if(key < 0) {
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

function VirtualKeyVM(row, column, viewmodel) {
    var self = this;
    // first row is "previous" octave
    self.octave_index = row - 1;
    // we shift the keyboard by 2 keys
    self.key_index = column - 2;

    self.tone = ko.computed(function() {
        return viewmodel.maqam().octaveKeyTone(self.octave_index, self.key_index);
    })
    self.letter = ko.computed(function() {
        return viewmodel.kbLayout().letterAt(row, column)
    })

    self.pressed = ko.observable(false)
    self.semi_pressed = ko.observable(false)

    self.state_class = ko.computed(function() {
        if(self.pressed()) {
            return "pressed";
        }
        if(self.semi_pressed()) {
            return "semi_pressed";
        }
        return "unpressed";
    })

    self.play = function() {
        playtone(self.tone());
    }

    self.press = function() {
        self.pressed(true)
    }
    self.unpress = function() {
        self.pressed(false)
    }

    self.semi_press = function() {
        self.semi_pressed(true)
    }
    self.unsemi_press = function() {
        self.semi_pressed(false)
    }

    return self;
}

function KeyboardLayout(rows) {
    var self = this;
    self.letterAt = function(row_index, col_index){
        var row = rows[row_index];
        if(!row) {
            return "";
        }
        val = row[col_index]
        if(!val) {
            return "";
        }
        return val;
    }

    return self;
}

var kb_layouts = {} // standard keyboard layouts .. to choose from; e.g. qwerty, azerty, .. etc
kb_layouts['qwerty'] = new KeyboardLayout(["1234567890-=", "qwertyuiop[]", "asdfghjkl;'"])

function GlobalViewModel() {
    var self = this;
    default_maqam = $.cookie('maqam') || 'ajam';
    maqamvm = new MaqamVM(maqamat[default_maqam])
    self.maqam = ko.observable(maqamvm)
    self.kbLayout = ko.observable(kb_layouts['qwerty'])

    key_list = []
    self.vkb_rows = []
    for(var i = 0; i <= 2; i++) {
        self.vkb_rows.push([])
        for(var j=0; j <= 12; j++) {
            var kvm = new VirtualKeyVM(i, j, self)
            self.vkb_rows[i].push(kvm)
            key_list.push(kvm)
        }
    }

    self.findKey = function(letter) {
        return u.find(key_list, function(key) {
            return key.letter() == letter;
        })
    };

    self.findKeysByTone = function(tone) {
        return u.filter(key_list, function(key) {
            return key.tone() == tone;
        });
    };

    return self;
}

        

$(function() {
    window.viewmodel = new GlobalViewModel();
    ko.applyBindings(window.viewmodel);
});

/*
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
*/

// ---- handle keyboard presses

key_handler = function(e, callback){
    if(e.ctrlKey || e.metaKey) {
        return
    }
    special = {
        109: '-',
        189: '-', // chrome
        61: '=',
        187: '=',  // chrome
        219: '[',
        221: ']',
        59: ';',
        186: ';',  // chrome
        222: '\'',
    }
    var kbkey;
    if(e.which in special) {
        kbkey = special[e.which]
    } else {
        kbkey = String.fromCharCode(e.which).toLowerCase()
    }
    e.preventDefault()
    var keyvm = viewmodel.findKey(kbkey)
    if (!keyvm) {
        return
    }
    tone = keyvm.tone()
    if(!tone) {
        return
    }
    tone_keys = viewmodel.findKeysByTone(tone)
    callback(keyvm, tone_keys)
}

$(document).keydown(function(ev) {
    var handler = function(keyvm, secondary_keys) {
        if(keyvm.pressed()) { // already pressed, don't handle again
            return false
        }
        for(var i = 0; i <= secondary_keys.length; i++) {
            key = secondary_keys[i];
            key.semi_press()
        }
        key.press()
        key.play()
    }
    key_handler(ev, handler)
})

$(document).keyup(function(ev) {
    var handler = function(keyvm, secondary_keys) {
        for(var i = 0; i <= secondary_keys.length; i++) {
            key = secondary_keys[i];
            key.unsemi_press()
        }
        key.unpress()
    }
    key_handler(ev, handler)
})


/*
# -------------------------

modulo = (index, length) ->
    while index < 0
        index += length
    index %= length

*/
