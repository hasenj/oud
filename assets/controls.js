// helpers for keyboard.js

// a list of possible starting tones:
// each one includes:
//  - display name
//  - note name
//  - note object (frequency)
//  all parsed form the given string, e.g. 'F1', 'A2', etc
BaseNote = function(nameWithOctave) {
    console.log("Argument", nameWithOctave);
    var self = this;
    var raw_name = nameWithOctave[0];
    var octave = Number(nameWithOctave[1]);
    self.raw = nameWithOctave;
    self.noteName = new NoteName(raw_name);
    self.display_name = self.noteName.disp_arabic() + octave;
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
    self.display = key + ' | ' + ScaleArabicName(name);

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

    self.pointerClass = ko.computed(function() {
        return "pointer " + (self.pointer() == self.jins1 ? "first" : "second");
    })

    self.selectFromKey = function(key, uiClicked) {
        var selectedName = self.keyMap[key];
        self.pointer()(ajnas[selectedName]);
        self.advancePointer();

        // simulate click
        if(!uiClicked) {
            var btn = self.buttons().find(function(b) { return b.key == key; });
            btn.simulateClick();
        }
    }
}

