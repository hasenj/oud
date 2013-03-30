/*
    Virtual Keyboard - Adjusts to scales

    This keyboard contains 3 rows, each row is an octave.

    Maqam can be changed and the keyboard keys will change which notes they sound.
*/

u = _

// octave row
function OctaveVM(octave, ko_mode) {
    // octave is the octave index
    // ko_mode is the observable active mode
    var self = this;
    self.tones = ko.computed(function() {
        var mode = ko_mode();
        if (mode) {
            return mode.genTones(octave);
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
window.stdNoteNames = ko.observable(doReMeArabic)

// maps a note number to a note name index
noteIndexMap = {
    '-13': -2,
    '-5': -1,
    0: 0,
    9: 1,
    17: 2,
    22: 3,
    31: 4,
}

zfill = function(str, len) {
    while(str.length < len) {
        str = str + String.fromCharCode(160);
    }
    return str;
}

// option list for starting note along with its name
noteNames = ko.computed(function() {
    // helper functions
    var intfn = function(n) { return parseInt(n); };
    var sortfn = function(a, b) { return a > b; };
    var res = [];
    var sortedKeys = u.keys(noteIndexMap).map(intfn).sort(sortfn);
    for(i in sortedKeys) {
        var note = sortedKeys[i];
        var name = stdNoteNames().at(noteIndexMap[note]);
        var item = {
            note: parseInt(note),
            //name: zfill(name, 10) + note
            name: name
        };
        res.push(item);
    }
    return res;
})

function ModeVM(name) {
    var self = this
    self.name = name // it's an observable
    self.mode = ko.computed(function() {
        return modes[self.name()]
    });

    self.noteName = function(keyIndex) {
        var firstNoteIndex = 0;
        // HACK! works because we only use a starting note from the map above
        if(self.mode()) {
            firstNoteIndex = noteIndexMap[self.mode().base()]
        }
        var noteIndex = keyIndex + firstNoteIndex;
        return stdNoteNames().at(noteIndex);
    }

    self.disp_name = ko.computed(function() {
        return "سلم " + arabic_name(self.name()) + " من ال" + self.noteName(0);
    });


    self.octaves = {}
    for(var i = -1; i <= 1; i++) {
        self.octaves[i] = new OctaveVM(i, self.mode);
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

function VirtualKeyVM(row, column, piano) {
    var self = this;
    // first row is "previous" octave
    self.octave_index = row - 1;
    // we shift the keyboard by 0 keys
    self.key_index = column - 0;

    self.tone = ko.computed(function() {
        return active_mode.octaveKeyTone(self.octave_index, self.key_index);
    })

    self.interval_to_next = ko.computed(function() {
        var mode = active_mode.mode()
        if(mode) {
            return mode.intervals().at(self.key_index);
        } else { // should not happen except briefly during initialization
            return -1;
        }
    });

    self.letter = ko.computed(function() {
        return piano.kbLayout().letterAt(row, column);
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
            var letter = self.letter();
            if(letter && letter != " ") {
                return letter;
            }
        }
        return "&nbsp;"
    });

    self.note_name = ko.computed(function() {
        if(self.disp_letter()) {
            return active_mode.noteName(self.key_index);
        } else {
            return "&nbsp;"
        }
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
kb_layouts['qwerty'] = new KeyboardLayout(["    TYUIOP[]", "ASDFGHJKL;'↩", "ZXCVBNM,./"])
window.active_mode = new ModeVM(selected_mode);

function PianoInstrument() {
    var self = this;

    self.mode_vm = active_mode;
    self.noteNames = noteNames;
    self.kbLayout = ko.observable(kb_layouts['qwerty']);

    // window.modes is a dictionary mapping names to modes
    // mode_list is an array of just the modes
    self.mode_list = ko.observableArray(u.values(window.modes));

    key_list = [];

    self.vkb_rows = [];
    for(var i = 0; i < 3; i++) {
        self.vkb_rows.push([]);
        for(var j=0; j < 12; j++) {
            var kvm = new VirtualKeyVM(i, j, self);
            self.vkb_rows[i].push(kvm);
            key_list.push(kvm);
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

    self.keydown = function(kbkey) {
        var keyvm = piano.findKey(kbkey)
        if (!keyvm) {
            return
        }
        var tone = keyvm.tone()
        if(tone == null) {
            return
        }
        var secondary_keys = piano.findKeysByTone(tone)
        if(keyvm.pressed()) { // already pressed, don't handle again
            return false
        }
        for(var i = 0; i < secondary_keys.length; i++) {
            var key = secondary_keys[i];
            key.semi_press()
        }
        keyvm.press()
        keyvm.play()
    };

    self.keyup = function(kbkey) {
        var keyvm = piano.findKey(kbkey)
        if (!keyvm) {
            return
        }
        var tone = keyvm.tone()
        if(tone == null) {
            return
        }
        var secondary_keys = piano.findKeysByTone(tone)
        for(var i = 0; i < secondary_keys.length; i++) {
            var key = secondary_keys[i];
            key.unsemi_press()
        }
        keyvm.unpress()
    };

    return self;
}

piano = new PianoInstrument();

// this should go else where - not in keyboard.js
function GlobalViewModel() {
    var self = this;

    self.instrument = ko.observable("piano"); // TODO remove oud mode .. only mode is piano mode ..
    var instrument_map = {
        piano: piano,
        oud: oud
    }

    self.active_instrument = ko.computed(function() {
        var instrument = instrument_map[self.instrument()];
        if(instrument) {
            return instrument;
        } else {
            return null;
        }
    });

    self.bindKeyboard = function() {
        $(document).keydown(function(e) {
            var kbkey = kb_key_from_event(e);
            if(!kbkey) return;
            e.preventDefault();
            if(self.active_instrument()) {
                self.active_instrument().keydown(kbkey);
            }
        });

        $(document).keyup(function(e) {
            var kbkey = kb_key_from_event(e);
            if(!kbkey) return;
            e.preventDefault();
            if(self.active_instrument()) {
                self.active_instrument().keyup(kbkey);
            }
        });
    };
}



$(function() {
    window.viewmodel = new GlobalViewModel();
    ko.applyBindings(window.viewmodel);
    viewmodel.bindKeyboard();
});

kb_key_from_event = function(e){
    if(e.ctrlKey || e.metaKey) {
        return
    }
    special = {
        109: '-',
        189: '-', // chrome
        173: '-', // ffox
        61: '=', // ffox
        187: '=',  // chrome
        219: '[',
        221: ']',
        59: ';',
        186: ';',  // chrome
        188: ',',
        190: '.',
        191: '/',
        222: '\'', // apostrophe
        13: '↩', // enter key
    }
    var kbkey;
    if(e.which in special) {
        kbkey = special[e.which]
    } else {
        kbkey = String.fromCharCode(e.which).toUpperCase()
    }
    return kbkey;
}
