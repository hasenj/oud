/*
    Virtual Keyboard - Adjusts to scales

    This keyboard contains 3 rows, each row is an octave.

    Maqam can be changed and the keyboard keys will change which notes they sound.
*/

function VirtualKeyVM(row, column, piano) {
    var self = this;
    // first row is "previous" octave
    self.octave_index = row - 1;
    // we shift the keyboard by 2 keys
    self.key_index = column - 2;

    self.note = ko.computed(function() {
        return piano.note_at(self.octave_index, self.key_index);
    })

    self.freq = ko.computed(function() {
        return self.note().freq();
    });

    // how many quarter tones to next key in scale
    self.distanceToNext = ko.computed(function() {
        var next_note = piano.note_at(self.octave_index, self.key_index + 1);
        var this_note = self.note();
        // NOTE: use use NoteRatio instead of Ratio because Ratio expects integers only
        var ratio = NoteRatio(next_note, this_note);
        return ratio.quarter_count() - 2; // sub semitone because it's min default
    });

    self.letter = ko.computed(function() {
        return piano.kbLayout().letterAt(row, column);
    })

    self.dispFreq = ko.computed(function() {
        var t = self.note();
        return t == null? "&nbsp;" : t;
    });

    self.dispLetter = ko.computed(function() {
        var letter = self.letter();
        if(letter.trim()) {
            return letter;
        }
        return "&nbsp;"
    });

    self.noteName = ko.computed(function() {
        var base = piano.noteName();
        return base.add(self.key_index);
    });

    // get how much is this note shifted from its standard (version on la minor scale)
    self.noteShift = ko.computed(function() {
        return piano.shift_at(self.octave_index, self.key_index);
    });

    self.dispNoteName = ko.computed(function() {
        return self.noteName().display()
    });

    self.dispNoteAccidental = ko.computed(function() {
        var shift = self.noteShift();
        var symbols = {
            'sharp': '&#9839;',
            'flat': '&#9837;',
            'h_flat': '&#119091;',
            'h_sharp': '&#119090;'
        }
        var map = {
            '0': '',
            '1': symbols.h_sharp,
            '2': symbols.sharp,
            '-1': symbols.h_flat,
            '-2': symbols.flat,
        }
        shift = shift.toString();
        if(shift in map) { shift = map[shift] }
        return shift;
    });

    self.pressed = ko.observable(false);
    self.semi_pressed = ko.observable(false);

    self.stateClass = ko.computed(function() {
        if(self.pressed()) {
            return "pressed";
        }
        if(self.semi_pressed()) {
            return "semi_pressed";
        }
        return "unpressed";
    })

    self.positionClass = ko.computed(function() {
        var pos = self.key_index + 1;
        if(pos == 1) {
            return "first mark";
        } else if (pos == 5) {
            return "fifth mark";
        } else if (pos == 9) {
            return "ninth mark";
        } else {
            return "";
        }
    })

    self.elClass = ko.computed(function() {
        return "key " + self.stateClass() + " " + self.positionClass();
    })

    self.containerClass = ko.computed(function() {
        var cls = "ib ";
        if(self.key_index < 0 || self.key_index > 7) {
            cls += "outside_octave";
        }
        return cls;
    })

    self.play = function() {
        var t = self.freq();
        if(t==null) {
            return
        }
        console.log("note:", self.noteName().name, "freq:", t);
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

    self.jinsSetCtrl = new JinsSetControls();
    // alises ...
    self.jins1 = self.jinsSetCtrl.jins1;
    self.jins2 = self.jinsSetCtrl.jins2;
    self.jins3 = self.jinsSetCtrl.jins3;

    self.baseNoteCtrl = new BaseNotesVM();

    self.baseNote = self.baseNoteCtrl.selectedBaseNote;

    self.note = ko.computed(function() {
        return self.baseNote().note;
    });
    self.noteName = ko.computed(function() {
        return self.baseNote().noteName;
    });

    self.scaleDisplayName = ko.computed(function() {
        var jins1Name = self.jins1().name;
        var jins2Name = self.jins2().name;
        var compoundName = jins1Name + '-' + jins2Name;
        var scaleName = getScaleName(compoundName);
        if(scaleName == compoundName) {
            scaleName = getScaleName(jins1Name) + ' ' + getScaleName(jins2Name);
        }
        var baseName = self.baseNote().noteName.display();
        return scaleName + ' ' + getText('on') + ' ' + baseName;
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

    ko.unwrap = ko.utils.unwrapObservable; // TEMP
    // XXX TODO update ko version

    // intervals in quarter-tones
    self.quarter_intervals = ko.computed(function() {
        var intervals = [];
        var notes = self.octave_notes();
        for(var i = 0; i < notes.length - 1; i++) {
            var n0 = notes[i]; // this note
            var n1 = notes[i+1]; // next note
            var qs = NoteRatio(n1, n0).quarter_count();
            if(qs == 5) { qs = 6; } // HACK against hijaz interval
            intervals.push(qs);
        }
        return intervals;
    });

    // std intervals starting from base note
    self.std_intervals = ko.computed(function() {
        var result = [];
        var noteName = self.baseNote().noteName; // XXX these object names / hirarchies are so fucking confusing
        // console.log("Base:", noteName);
        var notes = self.octave_notes();
        // loop notes and find shifts
        for(var i = 0; i < notes.length - 1; i++) {
            result.push(stdIntervals[noteName.name]);
            noteName = noteName.next();
        }
        return result;
    });

    // how much is each key shifted from the std version (do re mi ...)
    self.note_shifts = ko.computed(function() {
        var intervals = self.quarter_intervals();
        var std_intervals = self.std_intervals();
        // console.log("std:", std_intervals);
        // console.log("our:", intervals);
        var result = [];
        var carry = 0;
        // first one is known: 0
        // XXX: this is only true because we only start from std notes ... if
        // we change to support other starting notes .. this logic will break!
        result.push(0);
        // loop notes and find shifts
        for(var i = 0; i < intervals.length; i++) {
            var std_shift = std_intervals[i];
            var scale_shift = intervals[i];
            var expected = std_shift + carry;
            var carry = expected - scale_shift;
            // console.log("index:", i, " carry:", carry);
            result.push(-carry);
        }
        return result;
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
        // adjust by octave
        note = note.addInterval(intervals.octave.mul(octave_index));
        return note;
    };


    // accidentals ..
    self.shift_at = function(octave_index, key_index) {
        // XXX logic copied mostly from note_at
        if(key_index < 0) { // HACK, but works
            return self.shift_at(octave_index - 1, key_index + 7)
        }
        var shifts = self.note_shifts();
        if(key_index >= shifts.length) {
            return self.shift_at(octave_index +1, key_index - 7);
        }
        var shift = shifts.at(key_index);
        return shift
    };


    // this is kind cheating .. it doesn't need to be inside the piano actually
    // but we'll do it this way to keep things grouped together
    self.maqamPresetsCtrl = new MaqamPresetsCtrl();

    self.kbLayout = ko.observable(kb_layouts['qwerty']);

    self.key_list = [];

    self.vkb_rows = [];
    for(var i = 0; i < 3; i++) {
        self.vkb_rows.push([]);
        for(var j=0; j < 12; j++) {
            var kvm = new VirtualKeyVM(i, j, self);
            self.vkb_rows[i].push(kvm);
            self.key_list.push(kvm);
        }
    }

    self.findKey = function(letter) {
        return self.key_list.find(function(key) {
            return key.letter() == letter;
        })
    };

    self.findKeysByFreq = function(freq) {
        return self.key_list.filter(function(key) {
            return key.freq() == freq;
        });
    };

    self.keydown = function(kbkey) {
        if('-=+'.has(kbkey)) { // special keys - not notes
            if(kbkey == '-') {
                self.baseNoteCtrl.prevBase();
            } else if (kbkey == '=') {
                self.baseNoteCtrl.nextBase();
            }
            return;
        }
        if('12345678'.has(kbkey)) { // jins selector
            self.jinsSetCtrl.selectFromKey(kbkey);
            return;
        }
        if(kbkey == '9') {
            self.jinsSetCtrl.toggleLock();
            return;
        }
        if(kbkey == '0') {
            self.jinsSetCtrl.advancePointer();
            return;
        }
        var keyvm = piano.findKey(kbkey)
        if (!keyvm) {
            return
        }
        var freq = keyvm.freq()
        if(freq == null) {
            return
        }
        var secondary_keys = piano.findKeysByFreq(freq)
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
        var freq = keyvm.freq()
        if(freq == null) {
            return
        }
        var secondary_keys = piano.findKeysByFreq(freq)
        for(var i = 0; i < secondary_keys.length; i++) {
            var key = secondary_keys[i];
            key.unsemi_press()
        }
        keyvm.unpress()
    };

    return self;
}

piano = new PianoInstrument();

// for cookies
jinsToString = function(jins) {
    return jins.name;
}
jinsFromString = function(name) {
    return ajnas[name] || null;
}
boolToString = String
stringToBool = function(s) {
    if(s == "false") {
        return false;
    } else if(s == "true") {
        return true;
    }
    // default to true
    console.log("warning: cookie value is niether 'true' nor 'false'. Falling back to true");
    return true;
}

bindCookies(piano.jins1, 'jins1', jinsToString, jinsFromString);
bindCookies(piano.jins2, 'jins2', jinsToString, jinsFromString);
bindCookies(piano.baseNoteCtrl.selected, 'baseNote');
bindCookies(piano.jinsSetCtrl.locked, 'locked', boolToString, stringToBool);

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
        229: 'B' // arabic keyboard in chrome (لا key) XXX HACK
    }
    // console.log(e.which);
    var kbkey;
    if(e.which in special) {
        kbkey = special[e.which]
    } else {
        kbkey = String.fromCharCode(e.which).toUpperCase()
    }
    return kbkey;
}
