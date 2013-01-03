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
        return parts
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
