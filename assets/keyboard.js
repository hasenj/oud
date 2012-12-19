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
            return maqam.genTones(octave);
        }
        else {
            return [];
        }
    })
    return self;
}

doReMeArabic = "دو ري مي فا صول لا سي".split(" ")
doReMeLatin = "DO RE ME FA SOL LA SI".split(" ")
CDELatin = "C D E F G A B".split(" ")
stdNoteNames = ko.observable(doReMeArabic)

function MaqamVM(name) {
    var self = this
    self.name = name // it's an observable
    self.maqam = ko.computed(function() {
        return maqamat[self.name()]
    });

    self.disp_name = ko.computed(function() {
        return "مقام ال" + disp_name(self.name())
    });

    self.noteName = function(keyIndex) {
        var firstNoteIndex = 0;
        var noteIndexMap = {
            0: 0,
            9: 1,
            22: 3,
            31: 4,
        }
        // HACK! works because we only use either 0 or 9 as a first note so far XXX
        if(self.maqam()) {
            firstNoteIndex = noteIndexMap[self.maqam().base]
        }
        var noteIndex = keyIndex + firstNoteIndex;
        return modIndex(stdNoteNames(), noteIndex);
    }

    self.octaves = {}
    for(var i = -1; i <= 1; i++) {
        self.octaves[i] = new OctaveVM(i, self.maqam);
    }

    // find the tone for the key in the octave, returning null if one can't be found
    self.octaveKeyTone = function(octave, key) {
        var ovm = self.octaves[octave];
        if(!ovm) {
            return null;
        }

        var keys = ovm.tones();
        if(!keys) {
            return null;
        }

        var tone = keys[key];
        if(tone == null) {
            if(key > 7) {
                // find the key from the next octave ..
                return self.octaveKeyTone(octave+1, key-7);
            } else if(key < 0) {
                // find the key from the previous octave
                return self.octaveKeyTone(octave-1, key+7);
            } else {
                return null;
            }
        }
        return tone;
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
        return active_maqam.octaveKeyTone(self.octave_index, self.key_index);
    })
    self.letter = ko.computed(function() {
        return viewmodel.kbLayout().letterAt(row, column);
    })

    self.enabled = ko.computed(function() {
        return self.tone() != null;
    });

    self.disp_tone = ko.computed(function() {
        var t = self.tone();
        return t == null? "&nbsp;" : t;
    });

    self.disp_letter = ko.computed(function() {
        if(self.enabled()) {
            return self.letter() || "&nbsp;";
        } else {
            return "&nbsp;"
        }
    });

    self.note_name = ko.computed(function() {
        return active_maqam.noteName(self.key_index);
    });

    self.disp_note_name = ko.computed(function() {
        if(self.enabled()) {
            return self.note_name();
        } else {
            return "&nbsp;";
        }
    });

    self.pressed = ko.observable(false);
    self.semi_pressed = ko.observable(false);

    self.state_class = ko.computed(function() {
        if(self.pressed()) {
            return "pressed";
        }
        if(self.semi_pressed()) {
            return "semi_pressed";
        }
        return "unpressed";
    })

    self.el_class = ko.computed(function() {
        return "key " + self.state_class();
    })

    self.container_class = ko.computed(function() {
        var cls = "ib ";
        if(self.key_index < 0 || self.key_index > 7) {
            cls += "outside_octave";
        }
        return cls;
    })

    self.play = function() {
        var t = self.tone();
        if(t==null) {
            return
        }
        playtone(t);
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
kb_layouts['qwerty'] = new KeyboardLayout(["1234567890-=", "QWERTYUIOP[]", "ASDFGHJKL;'"])

window.active_maqam = new MaqamVM(selected_maqam)

function GlobalViewModel() {
    var self = this;
    self.maqam = active_maqam
    self.kbLayout = ko.observable(kb_layouts['qwerty'])

    self.maqam_list = ko.observableArray(u.values(window.maqamat))

    key_list = []
    self.vkb_rows = []
    for(var i = 0; i < 3; i++) {
        self.vkb_rows.push([])
        for(var j=0; j < 12; j++) {
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
        kbkey = String.fromCharCode(e.which).toUpperCase()
    }
    e.preventDefault()
    var keyvm = viewmodel.findKey(kbkey)
    if (!keyvm) {
        return
    }
    tone = keyvm.tone()
    if(tone == null) {
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
        for(var i = 0; i < secondary_keys.length; i++) {
            var key = secondary_keys[i];
            key.semi_press()
        }
        keyvm.press()
        keyvm.play()
    }
    key_handler(ev, handler)
})

$(document).keyup(function(ev) {
    var handler = function(keyvm, secondary_keys) {
        for(var i = 0; i < secondary_keys.length; i++) {
            var key = secondary_keys[i];
            key.unsemi_press()
        }
        keyvm.unpress()
    }
    key_handler(ev, handler)
})


_modulo = function(index, length) {
    while(index < 0) {
        index += length
    }
    return index % length
}

modIndex = function(list, index) {
    return list[_modulo(index, list.length)]
}

