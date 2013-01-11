/*
    Virtual Keyboard - Adjusts to scales

    This keyboard contains 3 rows, each row is an octave.

    Maqam can be changed and the keyboard keys will change which notes they sound.
*/

u = _

_modulo = function(index, length) {
    while(index < 0) {
        index += length
    }
    return index % length
}

modIndex = function(list, index) {
    return list[_modulo(index, list.length)]
}


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
window.stdNoteNames = ko.observable(doReMeArabic)

// maps a note number to a note name index
noteIndexMap = {
    '-13': -2,
    0: 0,
    9: 1,
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
        var name = modIndex(stdNoteNames(), noteIndexMap[note]);
        var item = {
            note: parseInt(note),
            //name: zfill(name, 10) + note
            name: name
        };
        res.push(item);
    }
    return res;
})

function MaqamVM(name) {
    var self = this
    self.name = name // it's an observable
    self.maqam = ko.computed(function() {
        return maqamat[self.name()]
    });

    self.noteName = function(keyIndex) {
        var firstNoteIndex = 0;
        // HACK! works because we only use a starting note from the map above
        if(self.maqam()) {
            firstNoteIndex = noteIndexMap[self.maqam().base()]
        }
        var noteIndex = keyIndex + firstNoteIndex;
        return modIndex(stdNoteNames(), noteIndex);
    }

    self.disp_name = ko.computed(function() {
        return "سلم ال" + disp_name(self.name()) + " على ال" + self.noteName(0);
    });


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

function VirtualKeyVM(row, column, piano) {
    var self = this;
    // first row is "previous" octave
    self.octave_index = row - 1;
    // we shift the keyboard by 2 keys
    self.key_index = column - 2;

    self.tone = ko.computed(function() {
        return active_maqam.octaveKeyTone(self.octave_index, self.key_index);
    })
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

window.active_maqam = new MaqamVM(selected_maqam);

function PianoMode() {
    var self = this;

    self.maqam = active_maqam;
    self.noteNames = noteNames;
    self.kbLayout = ko.observable(kb_layouts['qwerty']);

    self.maqam_list = ko.observableArray(u.values(window.maqamat));

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
        // TODO
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
        // TODO
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

piano = new PianoMode();

// this should go else where - not in keyboard.js
function GlobalViewModel() {
    var self = this;

    self.mode = ko.observable("piano");
    self.piano = piano;
    self.oud = oud;
    self.active_instrument = ko.computed(function() {
        var mode = self.mode();
        var instrument = self[mode];
        if(instrument) {
            return instrument;
        } else {
            return null;
        }
    });

    self.bindKeyboard = function() {
        $(document).keydown(function(e) {
            e.preventDefault();
            var kbkey = kb_key_from_event(e);
            if(self.active_instrument()) {
                self.active_instrument().keydown(kbkey); 
            }
        });

        $(document).keyup(function(e) {
            e.preventDefault();
            var kbkey = kb_key_from_event(e);
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
    return kbkey;
}

