// helpers for keyboard.js

// a list of possible starting tones:
// each one includes:
//  - display name
//  - note name
//  - note object (frequency)
//  all parsed form the given string, e.g. 'F1', 'A2', etc
BaseNote = function(nameWithOctave) {
    var self = this;
    var raw_name = nameWithOctave[0];
    var octave = Number(nameWithOctave[1]);
    self.raw = nameWithOctave;
    self.noteName = new NoteName(raw_name);
    self.display = self.noteName.display() + " " + octave;
    octave -= 2; // shift by 2 ..
    self.note = notes[raw_name].addInterval(intervals.octave.mul(octave));
}

// list base notes and select one
BaseNotesVM = function() {
    var self = this;
    self.rawBaseNotes = 'E1 F1 G1 A1 B1 C2 D2 E2 F2 G2 A2 B2 C3 D3 E3'.split(' ');
    self.baseNotes = ko.observableArray(self.rawBaseNotes.map(function(n) {
        return new BaseNote(n);
    }));
    self.selected = ko.observable('C2');

    self.selectedDisplayName = ko.computed(function() {
        var name = self.selected()[0];
        var octaveNumber = self.selected()[1];
        return note_names_map[name] + " " + octaveNumber;
    });

    self.selectedIndex = ko.computed(function() {
        return self.rawBaseNotes.indexOf(self.selected());
    });

    self.selectedBaseNote = ko.computed(function() {
        /*
        return self.baseNotes().find(function(bn) {
            return bn.raw == self.selected();
        });
        */
        return self.baseNotes().at(self.selectedIndex());
    });

    self.nextBase = function() {
        var nextIndex = self.selectedIndex() + 1;
        if(nextIndex < self.rawBaseNotes.length) {
            self.selected(self.rawBaseNotes.at(nextIndex));
        }
    }

    self.prevBase = function() {
        var prevIndex = self.selectedIndex() - 1;
        if(prevIndex >= 0) {
            self.selected(self.rawBaseNotes.at(prevIndex));
        }
    }

    self.dropmenuVisible = ko.observable(false);
    self.toggleDropmenu = function() {
        self.dropmenuVisible(!self.dropmenuVisible());
        if(self.dropmenuVisible()) {
            falseOnDocumentClick(self.dropmenuVisible);
        }
    }
}

JinsButton = function(key, name) {
    var self = this;
    self.key = key;
    self.jins = ajnas[name];
    self.displayName = ScaleArabicName(name);
    // self.display = key + ' | ' + ScaleArabicName(name);

    var unclick = 0;
    self.btnClicked = ko.observable(false);
    self.simulateClick = function() {
        self.btnClicked(true);
        clearTimeout(unclick);
        unclick = setTimeout( function() {
            self.btnClicked(false);
        }, 200);
    }
}

JinsSetControls = function() {
    var self = this;
    self.keyMap = {
        '1': 'ajem',
        '2': 'kurd',
        '3': 'nahawend',
        '4': 'hijaz',
        '5': 'rast',
        '6': 'beyat',
        '7': 'saba',
        '8': 'zemzem'
    }
    self.buttons = ko.observableArray(
        Object.keys(self.keyMap).map(
            function(key){
                var name = self.keyMap[key];
                return new JinsButton(key, name);
            })
        );

    // default to beyat
    self.jins1 = ko.observable(ajnas.beyat);
    self.jins2 = ko.observable(ajnas.kurd);
    self.jins3 = ko.observable(null);

    // jins is an observable pointing to something from the ajnas map
    self.jinsCtrl = function(jins, label) {
        var parent = self;
        var c = {}
        c.label = label;
        c.jins = jins;
        c.dispName = ko.computed(function() {
            return jins().dispName();
        });
        c.select = function() {
            if(!parent.locked()) {
                parent.pointer(jins);
            }
        }
        c.isSelected = ko.computed(function() {
            return parent.pointer() === jins;
        });
        c.isLocked = ko.computed(function() {
            return c.isSelected() && parent.locked();
        });
        c.toggleLock = function() {
            if(c.isLocked()) {
                parent.locked(false);
            } else {
                parent.locked(false);
                c.select();
                setTimeout(function() {
                parent.locked(true);
                }, 200);
            }
        }

        // almost copy paste from the basenote menu
        // XXX maybe refactor?
        c.jinsMenuVisible = ko.observable(false);
        c.toggleJinsMenu = function() {
            console.log("Toggling jins menu");
            c.jinsMenuVisible(!c.jinsMenuVisible());
            if(c.jinsMenuVisible()) {
                falseOnDocumentClick(c.jinsMenuVisible);
            }
        }

        c.hovered = ko.observable(false);
        c.shadowArrowHover = ko.observable(false);
        c.shadowLockHover = ko.observable(false);
        c.shadowArrowVisible = ko.computed(function() {
            return !c.isSelected() && !parent.locked() && (c.shadowArrowHover() || c.shadowLockHover());
        });
        c.shadowLockVisible = ko.computed(function() {
            return c.shadowLockHover() || c.hovered();
        });

        return c;
    }

    // jins3 is nullified when jins2 is not diminished
    self.jins2.subscribe(function(val) {
        if(self.jins2().p3 == intervals.forth) {
            self.jins3(null);
        } else {
            self.jins3(val);
        }
    });

    self.pointer = ko.observable(self.jins1); // observable to observable (pointer to pointer)
    self.advancePointer = function() {
        if(self.pointer() == self.jins1) {
            self.pointer(self.jins2);
            return;
        } else {
            self.pointer(self.jins1);
            return;
        }
    }

    self.locked = ko.observable(false);
    self.toggleLock = function() {
        self.locked(!self.locked());
    }

    self.pointerClass = ko.computed(function() {
        return "pointer " + (self.pointer() == self.jins1 ? "first" : "second");
    })

    self.selectFromKey = function(key, uiClicked) {
        var selectedName = self.keyMap[key];
        self.pointer()(ajnas[selectedName]);
        if(!self.locked()) {
            self.advancePointer();
        }

        // simulate click
        if(!uiClicked) {
            var btn = self.buttons().find(function(b) { return b.key == key; });
            btn.simulateClick();
        }
    }
}


// base is a raw string, e.g. 'C2'
PresetMaqam = function(name, base, jins1, jins2) {
    var self = this;
    self.name = name;
    self.base = base;
    self.jins1 = jins1;
    self.jins2 = jins2;

    // this is computed because it could change depending on active language (in the future)
    self.maqamName = ko.computed(function() {
        return ScaleArabicName(self.name);
    });

    // simple as in: no octave number
    self.simpleNoteName = ko.computed(function() {
        return SimpleNoteName(self.base);
    });

    // create a version of this object bound to a piano object
    // HACK to make it usable in templates without having this model itself
    // depend on the existance of the piano object
    self.pianoBound = function(piano) {
        var clone = Object.clone(self);
        clone.apply = function() {
            piano.jins1(clone.jins1);
            piano.jins2(clone.jins2);
        }

        clone.applyWithBase = function() {
            clone.apply();
            piano.baseNoteCtrl.selected(clone.base);
        }

        clone.isApplied = ko.computed(function() {
            return piano.jins1().name == clone.jins1.name && piano.jins2().name == clone.jins2.name;
        });

        clone.isAppliedWithBase = ko.computed(function() {
            return clone.isApplied() && piano.baseNote().raw == clone.base;
        });

        return clone;
    }

}


// do we actually need a map?!
var preset_def_map = {
    "ajem": "C2 ajem ajem",
    "kurd": "D2 kurd kurd",

    "nahawend-u": "C2 nahawend hijaz",
    "nahawend-d": "C2 nahawend kurd",

    "hijaz-u": "D2 hijaz beyat",
    "hijaz-d": "D2 hijaz kurd",

    "beyat": "D2 beyat kurd",
    "saba": "D2 saba zemzem",

    "rast-u": "C2 rast rast",
    "rast-d": "C2 rast nahawend",

    // "zemzem": "D2 zemzem zemzem",

    // "saba-full": "D2 saba kurd",
    // "zemzem-full": "D2 zemzem kurd",
}

var maqamPresetMap = {}
Object.keys(preset_def_map).map(function(key) {
    var name = key;
    var def = preset_def_map[key];
    var parts = def.split(" ")
    var base = parts.shift();
    var jins1 = ajnas[parts.shift()]
    var jins2 = ajnas[parts.shift()]
    maqamPresetMap[name] = new PresetMaqam(name, base, jins1, jins2);
});

MaqamPresetsCtrl = function() {
    var self = this;
    // maqamPresetMap is a dict
    // XXX do we need the dict acutally? Probably just the list will do
    self.presets = ko.observableArray(Object.values(window.maqamPresetMap));
}

