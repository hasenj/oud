/*
    Flexible oud-like keyboard allowing to play any kind of "Jins" (tetrachord) without adjusting the current active scale.

    The way to do that is to provide options for "seconds" and "thirds", and even "forths".

        Seconds:
            - Minor second (semitone)
            - Neutral second (three quarter tone)
            - Major second (tone)

        Thirds:
            - Minor third (6:5)
            - Major third (5:4)

        Forths:
            - Diminished forth (major third + semitone)
            - Perfect forth

    The keyboard is made up of rows of octaves,

    Each octave is made up of rows of jins (tetrachords). Jins rows are separated by perfect fifths (3:2)
    With the possibility of adding extra rows to the jins (thus overflowing outside of the octave boundary).

    Each Jins row is made up of "groups" of keys:

        First: 1 key
        Seconds: 3 keys
        Thirds: 2 keys
        Forths: 2 keys

    Totalling 8 keys.

 */

ButtonGroup = function(watarJins, index, intervals) {
    var self = this;

    self.noteName = watarJins.noteName.add(index);
    self.keys = ko.computed(function() {
        var keys = [];
        for(var i = 0; i < intervals.length; i++) {
            keys.push(new Key(watarJins.baseNote().addRatio(intervals[i])));
        }
        return keys;
    }
}

// WatarJins = Tetrachord String
// a series of groups of a buttons that represent "frets" on this string
WatarJins = function(baseNote, noteName) {
    var self = this;

    self.baseNote = baseNote;
    self.noteName = noteName;

    self.groups = [
        new ButtonGroup(self, 0, [intervals.identity]), // First: identity 
        new ButtonGroup(self, 1, [intervals.semitone, intervals.neutralSecond, intervals.tone]), // seconds: semitone, neutral, tone
        new ButtonGroup(self, 2, [intervals.minorThird, intervals.majorThird]),
        new ButtonGroup(self, 3, [intervals.diminishedForth, intervals.forth]),
    ];

    self.nextJins = function() {
        return new WatarJins(self.baseNote().add(intervals.fifth), noteName.add(4));
    }

}

// AwtarDiwan = Octave Strings
// a series of Tetrachord strings, separated by a perfect fifth 3:2
AwtarDiwan = function(baseNote, noteName) {
    var self = this;
    self.baseNote = baseNote;
    self.noteName = noteName;
    var first = new WatarJins(self.baseNote, self.noteName);
    self.ajnas = ko.observableArray([first, first.nextJins()]); // start with 2 ajnas

    // previous diwan on the keyboard/intstrument
    self.prev = ko.observable(null);

    self.index = ko.computed(function() {
        if(prev()) {
            return prev().index() + prev().count();
        } else {
            return 0
        }
    });

    // how many awtar we have; i.e. self.ajnas.length
    self.count = ko.computed(function() {
        return self.ajnas().length;
    });

    self.addJins = function() {
        self.ajnas.push(self.ajnas().last().nextJins());
    }

    self.removeJins = function() {
        if(self.ajnas().length <= 2) {
            return; // refuse to become less than 2 ajnas
        }
        self.ajnas.pop();
    }
}
