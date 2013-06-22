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
    self.rawBaseNotes = 'E1 F1 G1 A2 B2 C2 D2 E2 F2 G2 A3 B3 C3 D3 E3'.split(' ');
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
}
