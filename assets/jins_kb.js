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

WatarKey = function(jins, interval) {
    var self = this;

    self.note = ko.computed(function() {
        return jins.baseNote().addRatio(interval);
    });
}

ButtonGroup = function(watarJins, index, intervals) {
    var self = this;

    self.noteName = watarJins.noteName().add(index);
    self.keys = ko.computed(function() {
        var keys = [];
        for(var i = 0; i < intervals.length; i++) {
            keys.push(new WatarKey(watarJins, intervals[i]));
        }
        return keys;
    });
}

// WatarJins = Tetrachord String
// a series of groups of a buttons that represent "frets" on this string
WatarJins = function(diwan, baseNote, noteName) {
    var self = this;

    self.baseNote = baseNote;
    self.noteName = noteName;
    self.diwan = diwan;

    self.groups = [
        new ButtonGroup(self, 0, [intervals.identity]), // First: identity 
        new ButtonGroup(self, 1, [intervals.semitone, intervals.neutralSecond, intervals.tone]), // seconds: semitone, neutral, tone
        new ButtonGroup(self, 2, [intervals.minorThird, intervals.majorThird]),
        new ButtonGroup(self, 3, [intervals.diminishedForth, intervals.forth]),
    ];

    self.buttons = ko.computed(function() {
        var result = [];
        self.groups.each(function(g) {
            g.keys().each(function(key) {
                result.push(key);
            }, 0, true);
        }, 0, true);
        return result;
    });

    self.nextJins = function() {
        return new WatarJins(diwan, self.baseNote().add(intervals.fifth), noteName.add(4));
    }

    // index of this "watar" on the instrument
    self.index = ko.computed(function() {
        return diwan.index() + diwan.ajnas.indexOf(self);
    });
}

// AwtarDiwan = Octave Strings
// a series of Tetrachord strings, separated by a perfect fifth 3:2
// param oud: the instrument
AwtarDiwan = function(oud, baseNote, noteName) {
    var self = this;

    self.oud = oud;
    self.baseNote = baseNote;
    self.noteName = noteName;

    self.index = ko.computed(function() {
        return oud.diwans().indexOf(self);
    });

    var first = new WatarJins(self, self.baseNote, self.noteName);
    self.ajnas = ko.observableArray([first, first.nextJins()]); // start with 2 ajnas

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

    self.nextDiwan = function() {
        return new AwtarDiwan(self.oud, self.baseNote().addRatio(intervals.octave), self.noteName);
    }

    self.prevDiwan = function() {
        return new AwtarDiwan(self.oud, self.baseNote().subRatio(intervals.octave), self.noteName);
    }
}

// The oud instrument constructor
// baseNote and noteName here are observables they are plain values! but inside
// diwan and jins they should be observables!
Instrument = function(baseNote, noteName) {
    var self = this;

    self.baseNote = ko.observable(baseNote);
    self.noteName = ko.observable(noteName);

    // create 3 diwans .. one as the previous octave, one as current, one as next!
    var middleDiwan = new AwtarDiwan(self, self.baseNote, self.noteName);

    self.diwans = ko.observableArray([middleDiwan.prevDiwan(), middleDiwan, middleDiwan.nextDiwan()]);

}


// a list of [frequency, name] pairs
Do = new Note(128);
Re = Do.addRatio(intervals.tone);
Fa = Do.addRatio(intervals.forth);
Sol = Do.addRatio(intervals.fifth);
La = Re.subRatio(intervals.forth);

StartNoteChoices = [
    [La, new NoteName(6)],
    [Do, new NoteName(0)],
    [Re, new NoteName(1)],
    [Fa, new NoteName(4)],
    [Sol, new NoteName(5)],
];

KeyboardWindow = function() {
    // querty
    var qwerty_rows = [
        "12345678",
        "qwertyui",
        "asdfghjk",
        "zxcvbnm,",
        ];

    self.rows = ko.observable(qwerty_rows);
    self.index = ko.observable(1); // start on the second jins from the first diwan

    self.move = function(offset) {
        var newIndex = self.index() + offset;
        if(newIndex < 0) {
            self.index(0);
            return;
        }
        if(newIndex > 5) {
            self.index(5);
            return;
        }
        self.index(newIndex);
    }
}

keyboardWindow = new KeyboardWindow();

var startNoteTuple = StartNoteChoices[1];
instrument = new Instrument(startNoteTuple[0], startNoteTuple[1]);
