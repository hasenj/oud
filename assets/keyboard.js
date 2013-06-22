/*
    Virtual Keyboard - Adjusts to scales

    This keyboard contains 3 rows, each row is an octave.

    Maqam can be changed and the keyboard keys will change which notes they sound.
*/

u = _

function VirtualKeyVM(row, column, piano) {
    var self = this;
    // first row is "previous" octave
    self.octave_index = row - 1;
    // we shift the keyboard by 2 keys
    self.key_index = column - 2;

    self.note = ko.computed(function() {
        return piano.note_at(self.octave_index, self.key_index);
    })

    self.tone = ko.computed(function() {
        return self.note().freq();
    });

    self.interval_to_next = ko.computed(function() {
        return "5"; // XXX STUB
    });

    self.letter = ko.computed(function() {
        return piano.kbLayout().letterAt(row, column);
    })

    self.enabled = ko.computed(function() {
        return self.note() != null;
    });

    self.disp_tone = ko.computed(function() {
        var t = self.note();
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
        var base = piano.noteName();
        return base.add(self.key_index);
    });

    self.disp_note_name = ko.computed(function() {
        if(self.enabled()) {
            return self.note_name().disp_arabic();
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
        console.log("Tone:", t);
        play_freq(t);
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
kb_layouts['qwerty'] = new KeyboardLayout(["QWERTYUIOP[]", "ASDFGHJKL;'↩", "ZXCVBNM,./"])

function PianoInstrument() {
    var self = this;

    self.jins1 = ko.observable(ajnas.ajem);
    self.jins2 = ko.observable(ajnas.ajem);
    self.jins3 = ko.observable(null);

    self.baseNoteCtrl = new BaseNotesVM();

    self.baseNote = ko.computed(function() {
        return self.baseNoteCtrl.selectedBaseNote();
    });

    self.note = ko.computed(function() {
        return self.baseNote().note;
    });
    self.noteName = ko.computed(function() {
        return self.baseNote().noteName;
    });

    // jins3 is nullified when jins2 is not diminished
    self.jins2.subscribe(function(val) {
        if(self.jins2().p3 == intervals.forth) {
            self.jins3(null);
        } else {
            if(!self.jins3()) {
                self.jins3(val);
            }
        }
    });

    // array of Note objects
    self.jins1_notes = ko.computed(function() {
        return self.jins1().notes(self.note());
    });
    // array of Note objects
    self.jins2_notes = ko.computed(function() {
        return self.jins2().notes(self.note().addInterval(intervals.fifth));
    });
    // array of Note objects
    self.jins3_notes = ko.computed(function() {
        if(self.jins3()) {
            return self.jins3().notes(self.note().addInterval(intervals.fifth.mul(2)));
        } else {
            return [];
        }
    });

    self.octave_notes = ko.computed(function() {
        return Array.create(self.jins1_notes(), self.jins2_notes(), self.jins3_notes());
    });

    self.note_at = function(octave_index, key_index) {
        if(key_index < 0) { // HACK, but works
            return self.note_at(octave_index - 1, key_index + 7)
        }
        var notes = self.octave_notes();
        if(key_index >= notes.length) {
            return self.note_at(octave_index +1, key_index - 7);
        }
        var note = notes.at(key_index);
        note = note.addInterval(intervals.octave.mul(octave_index));
        return note;
    };

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
        if('-=+'.has(kbkey)) { // special keys - not notes
            if(kbkey == '-') {
                self.baseNoteCtrl.prevBase();
            } else if (kbkey == '=') {
                self.baseNoteCtrl.nextBase();
            }
        }
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

    self.instrument = ko.observable("piano");
    var instrument_map = {
        piano: piano,
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
