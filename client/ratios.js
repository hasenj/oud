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

log_n = function(a,n) {
    return Math.log(a)/Math.log(n);
}
log2 = function(a) {
    return log_n(a, 2);
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

    self.mul = function(times) {
        if(times == 0) {
            return Ratio(1, 1);
        }
        var m = self;
        if(times < 0) {
            times = Math.abs(times);
            m = m.inverse();
        }
        var res = m;
        while(times > 1) {
            times--;
            res = res.add(m);
        }
        return res;
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

    self.quarters = function() {
        return self.linearize(24);
    }

    // how many 'quarter' tones are in there roughly?
    self.quarter_count = function() {
        var lin = self.toLinear() * 24;
        return Math.round(lin);
    }

    // how many 'commas' tones are in there roughly?
    self.comma_count = function() {
        var lin = self.toLinear() * 53;
        return Math.round(lin);
    }

    // how many 'steps' are roughly in there, assuming we divide octave to `units` units?
    self.step_count = function(units) {
        if(!units) {
            units = 1;
        }
        var lin = self.toLinear() * units;
        return Math.round(lin);
    }


    self.commas = function() {
        return self.linearize(53);
    }

    self.percent = function() {
        return self.linearize(100);
    }

    self.linearize = function(units) {
        if(!units) {
            units = 1;
        }
        return (self.toLinear() * units).toFixed(2);
    }

    self.in = function(other) { // how many units of other ratio?
        return (Math.log(self.value())/Math.log(other.value())).toFixed(2);
    }

    self.toString = function() {
        return "" + self.a + ":" + self.b;
    }

    self.repr = function() {
        return self.toString() + " ~= " + self.value().toFixed(4) + " | " + self.semiTones() + " ET semitones" + " | " + self.commas() + " ET commas" + " | " + self.percent() + " octave percent";
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
    tone: Ratio(9,8),
    // lesserTone: Ratio(10,9),
    neutralSecond: Ratio(12,11),
    // biggerNeutralSecond: Ratio(11,10),
    // biggerSemiTone: Ratio(15,14),
    semiTone: Ratio(16,15),
    neutralThird: Ratio(11,9),
    // neutralThird: Ratio(27, 22), // zalzal's
    diminishedForth: Ratio(32, 25),
    // biggerDiminishedForth: Ratio(9, 7),
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
    self.addInterval = function(ratio) {
        return new Note(self.freq() * ratio.value());
    }
    self.addRatio = self.addInterval; // for backward compatibility

    self.subInterval = function(ratio) {
        return new Note(self.freq() * ratio.inverse().value());
    }
    self.subRatio = self.subInterval;

    // return a note similar to this but in first la octave
    self.inFirstLaOctave = function() {
        var f = self.freq();
        while(f < 110) {
            f = f * 2;
        }
        while(f >= 220) {
            f = f / 2;
        }
        // XXX do something about LA being either LA1 or LA2 ..
        return new Note(f);
    }

    // what octave are we in? assuming we start from la 110
    self.laOctave = function() {
        return log2(self.freq() / self.inFirstLaOctave().freq()) + 1; // add 1 because this would be 0 indexed
    }
}

// like Ratio, but accept non-integers, and accept note objects too
NoteRatio = function(a, b) {
    if(a.freq) a = a.freq();
    if(b.freq) b = b.freq();
    a = parseInt(a * 1000);
    b = parseInt(b * 1000);
    return Ratio(a, b);
}

// standard notes
notes = {};
notes.A1 = new Note(110);
notes.B1 = notes.A1.addInterval(intervals.tone);
notes.C = notes.A1.addInterval(intervals.minorThird);
notes.D = notes.A1.addInterval(intervals.forth);
notes.E = notes.A1.addInterval(intervals.fifth);
notes.F = notes.C.addInterval(intervals.forth);
notes.G = notes.D.addInterval(intervals.forth);
notes.A = notes.A1.addInterval(intervals.octave);
notes.B = notes.B1.addInterval(intervals.octave);

// each key maps to its interval to the next in quarter counts!
stdIntervals = {
    'A': 4,
    'B': 2,
    'C': 4,
    'D': 4,
    'E': 2,
    'F': 4,
    'G': 4,
};
