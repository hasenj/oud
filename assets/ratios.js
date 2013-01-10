// from http://rosettacode.org/wiki/Greatest_common_divisor#JavaScript
gcd = function(a,b) {
    if (a < 0) a = -a;
    if (b < 0) b = -b;
    if (b > a) {var temp = a; a = b; b = temp;}
    while (true) {
        a %= b;
        if (a == 0) return b;
        b %= a;
        if (b == 0) return a;
    }
}

// A ratio is a:b
// we just call the first number a and the second number b
RatioCtor = function(a, b) {
    // XXX assert num and denom are integers
    a = parseInt(a);
    b = parseInt(b);

    // normalize it!
    var f = gcd(a, b);
    a = a/f;
    b = b/f;

    var self = this;
    self.a = a;
    self.b = b;


    self.add = function(other) {
        return Ratio(self.a * other.a, self.b * other.b);
    }

    self.sub = function(other) {
        return Ratio(self.a * other.b, self.b * other.a);
    }

    self.inverse = function() {
        return Ratio(self.b, self.a);
    }

    // @param count: how many parts to split into
    self.split = function(count) {
        var ntop = self.a * count;
        var nbot = self.b * count;
        var step = self.a - self.b;

        var parts = [];
        var cur = ntop;
        for(var i = 0; i < count; i++) {
            parts.push(Ratio(cur, cur-step));
            cur -= step;
        }
        // assert cur == nbot;
        return parts
    }

    // divergent split
    self.dsplit = function() {
        var args = Array.prototype.slice.call(arguments);
        var sumargs = args.reduce(function(a, b) { return a + b; });
        var mul_factor = sumargs / (self.a - self.b);

        var ntop = self.a * mul_factor;
        var nbot = self.b * mul_factor;
        var parts = [];
        var cur = ntop;
        while(args.length) {
            var step = args.shift();
            parts.push(Ratio(cur, cur-step));
            cur -= step;
        }
        // assert cur == nbot;
        return parts;
    }

    self.value = function() {
        return self.a/self.b;
    }

    self.toLinear = function() {
        return Math.log(self.value())/Math.log(2);
    }

    self.semiTones = function() {
        return self.linearize(12);
    }

    self.commas = function() {
        return self.linearize(53);
    }

    self.linearize = function(units) {
        return (self.toLinear() * units).toFixed(2);
    }

    self.toString = function() {
        return "" + self.a + ":" + self.b;
    }

    self.repr = function() {
        return self.toString() + " ~= " + self.value().toFixed(4) + " | " + self.semiTones() + " ET semitones" + " | " + self.commas() + " ET commas";
    }

    self.oud = function(watar_len) {
        return (watar_len * (self.a - self.b)) / self.a;
    }

    self.equals = function(other) {
        return self.a == other.a && self.b == other.b;
    }

    return this;
}

Ratio = function(a, b) {
    return new RatioCtor(a, b);
}

// -------- standard intervals ---------------

var intervals = {
    identity: Ratio(1, 1),
    octave: Ratio(2, 1),
    fifth: Ratio(3, 2),
    forth: Ratio(4, 3),
    majorThird: Ratio(5, 4),
    minorThird: Ratio(6, 5),
}
intervals.tone = intervals.fifth.sub(intervals.forth);
intervals.semitone = intervals.minorThird.sub(intervals.tone);
intervals.neutralSecond = intervals.minorThird.split(2)[0]; // XXX assuming the smaller part comes first!! this should be Ratio(12, 11) maybe we should have "ratio_min" function
intervals.diminishedForth = intervals.minorThird.add(intervals.semitone);


// ----------- utils -----------


// XXX duplicate code!!
_modulo = function(index, length) {
    while(index < 0) {
        index += length
    }
    return index % length
}

modIndex = function(list, index) {
    return list[_modulo(index, list.length)]
}


// -------------------------------------------------------------------------------------------
// -------------------------    Notes   ------------------------------------------------------
// -------------------------------------------------------------------------------------------

Note = function(frequency) {
    // assert 0 <= index < 7
    var self = this;
    self.frequency = frequency;
    self.freq = function() { // interface
        return self.frequency;
    }

    // apply ratio to a note and come up with a new note
    self.addRatio = function(ratio) {
        return new Note(self.freq() * ratio.value());
    }

    self.subRatio = function(ratio) {
        return new Note(self.freq() * ratio.inverse().value());
    }

    var signal = null;
    self.play = function() {
        if(!signal) {
            signal = tone_gen_from_freq(self.freq());
        }
        play_signal(signal);
    }
}

noteNameSystems = {
    'doremi_arabic': "دو ري مي فا صول لا سي".split(" "),
    'doremi_latin': "DO RE ME FA SOL LA SI".split(" "),
    'cde_latin': "C D E F G A B".split(" ")
}

noteNameSystem = ko.observable('doremi_arabic');

NoteName = function(index) {
    var self = this;

    index = _modulo(index, 7);
    // assert 0 <= index < 7
    self.index = index;

    self.name = ko.computed(function() {
        noteNameSystems[noteNameSystem()][self.index];
    });

    self.next = function() {
        return self.add(1);
    }

    self.prev = function() {
        return self.add(-1);
    }

    self.add = function(offset) {
        return new NoteName(_modulo(self.index + offset, 7));
    }
}
