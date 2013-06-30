// set the observable to false when any click event occurs on the document
var falseOnDocumentClick = function(ob) {
    var hideIt = function() {
        if(ob()) {
            ob(false);
        }
    }

    var eventHandler = function() {
        setTimeout(function() {
            hideIt();
            document.removeEventListener('click', eventHandler);
        }, 100);
    }

    setTimeout(function() {
        document.addEventListener('click', eventHandler);
    }, 100);
}


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
    lesserTone: Ratio(10,9),
    neutralSecond: Ratio(12,11),
    biggerSemiTone: Ratio(15,14),
    semiTone: Ratio(16,15),
    neutralThird: Ratio(11,9),
    // neutralThird: Ratio(27, 22), // zalzal's
    // diminishedForth: Ratio(9, 7)
    diminishedForth: Ratio(32, 25)
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

    var signal = null;
    self.play = function() {
        if(!signal) {
            signal = signal_gen_from_freq(self.freq());
        }
        play_signal(signal);
    }
}

// standard notes
notes = {}
notes.A1 = new Note(110);
notes.B1 = notes.A1.addInterval(intervals.tone);
notes.C = notes.A1.addInterval(intervals.minorThird);
notes.D = notes.A1.addInterval(intervals.forth);
notes.E = notes.A1.addInterval(intervals.fifth);
notes.F = notes.D.addInterval(intervals.majorThird);
notes.G = notes.D.addInterval(intervals.forth);
notes.A = notes.A1.addInterval(intervals.octave);
notes.B = notes.B1.addInterval(intervals.octave);

// Generated by CoffeeScript 1.4.0
(function() {
  var CHANNELS, DURATION, GAIN, SIGNAL_LEN, SRATE, avg, dampness, firefox_on_linux, interpolate, ks_noise_sample, make_dual_channel, mk_point, mk_ring_cleaner, mk_wave_shape, mkbuf, mksink, oud_signal_gen, oud_wave_shape, period_len, probability, random_sample, string_type_factory, tone_gen, tone_signal, tonefreq, wave_shape_to_sample;

  mkbuf = function(len) {
    return new Float32Array(Math.floor(len));
  };

  firefox_on_linux = function() {
    return $.browser.mozilla && (navigator.platform.indexOf("Linux") !== -1 || navigator.oscpu.indexOf("Linux") !== -1);
  };

  CHANNELS = 2;

  mksink = function(srate) {
    var prebuf_size;
    try {
      prebuf_size = firefox_on_linux() ? srate / 2 : 2048;
      prebuf_size = Math.floor(prebuf_size);
      return Sink(null, CHANNELS, prebuf_size, srate);
    } catch (error) {
      alert("الرجاء فتح الموقع فيمتصفح كووكل كروم");
      return {
        sampleRate: srate,
        ringOffset: 0
      };
    }
  };

  window.dev = mksink(44100);

  SRATE = dev.sampleRate;

  period_len = function(freq) {
    return Math.round(SRATE / freq);
  };

  avg = function(a, b) {
    return (a + b) / 2;
  };

  probability = function(p) {
    return Math.random() < p;
  };

  ks_noise_sample = function(val) {
    if (val == null) {
      val = 0.5;
    }
    if (probability(0.5)) {
      return val;
    } else {
      return -val;
    }
  };

  random_sample = function() {
    return 2 * Math.random() - 1;
  };

  mk_point = function(x, y) {
    return {
      x: x,
      y: y
    };
  };

  mk_wave_shape = function(points) {
    if (points[0].x !== 0) {
      points.unshift(mk_point(0, 0));
    }
    if (points[points.length - 1].x !== 1) {
      points.push(mk_point(1, 0));
    }
    return points;
  };

  interpolate = function(v1, v2, dist) {
    return (v2 - v1) * dist + v1;
  };

  wave_shape_to_sample = function(shape, len) {
    var dist, i, next, prev, s, sample, x, _i, _len;
    shape = Object.clone(shape);
    sample = mkbuf(len);
    prev = shape.shift();
    for (i = _i = 0, _len = sample.length; _i < _len; i = ++_i) {
      s = sample[i];
      next = shape[0];
      x = i / len;
      dist = (x - prev.x) / (next.x - prev.x);
      sample[i] = interpolate(prev.y, next.y, dist);
      if (x > next.x) {
        prev = shape.shift();
      }
    }
    return sample;
  };

  oud_wave_shape = mk_wave_shape([mk_point(0.1, 0.1), mk_point(0.16, 0.22), mk_point(0.26, -0.26), mk_point(0.4, -0.22), mk_point(0.5, 0.1), mk_point(0.6, 0.34), mk_point(0.7, 0.24), mk_point(0.84, 0), mk_point(0.91, -0.04)]);

  DURATION = 1.1;

  GAIN = 0.7;

  SIGNAL_LEN = DURATION * SRATE * CHANNELS;

  dev.ringBuffer = mkbuf(7 * CHANNELS * SRATE);

  dampness = (function() {
    var down, point, _i, _results;
    down = function(val) {
      return Math.max(0, val - 0.24);
    };
    _results = [];
    for (point = _i = 0; 0 <= SIGNAL_LEN ? _i <= SIGNAL_LEN : _i >= SIGNAL_LEN; point = 0 <= SIGNAL_LEN ? ++_i : --_i) {
      _results.push(down(Math.pow(Math.E, -2 * (point / SIGNAL_LEN))));
    }
    return _results;
  })();

  string_type_factory = function(wave_shape, noise_sample_param) {
    var signal_gen;
    return signal_gen = function(freq) {
      var adj, base_sample, index, point, s, signal, table, table_len, _i, _j, _len, _len1;
      table_len = period_len(freq);
      table = mkbuf(table_len);
      base_sample = wave_shape_to_sample(wave_shape, table_len);
      for (index = _i = 0, _len = base_sample.length; _i < _len; index = ++_i) {
        s = base_sample[index];
        table[index] = base_sample[index] + ks_noise_sample(noise_sample_param);
      }
      signal = mkbuf(SIGNAL_LEN);
      for (index = _j = 0, _len1 = signal.length; _j < _len1; index = ++_j) {
        s = signal[index];
        point = index % table_len;
        adj = (table_len + index - 1) % table_len;
        table[point] = avg(table[point], table[adj]);
        signal[index] = table[point];
      }
      return signal;
    };
  };

  oud_signal_gen = string_type_factory(oud_wave_shape, 0.12);

  tonefreq = function(tone, base) {
    var tones_per_octave;
    if (base == null) {
      base = 128;
    }
    tones_per_octave = 53;
    return base * Math.pow(2, tone / tones_per_octave);
  };

  tone_signal = {};

  tone_gen = function(tone) {
    if (tone in tone_signal) {
      return tone_signal[tone];
    } else {
      return tone_signal[tone] = signal_gen_from_freq(tonefreq(tone));
    }
  };

  window.signal_gen_from_freq = function(freq) {
    var point, s, signal, signal_raw, signal_raw2, _i, _len;
    signal_raw = oud_signal_gen(freq);
    signal_raw2 = oud_signal_gen(freq);
    signal = mkbuf(SIGNAL_LEN);
    for (point = _i = 0, _len = signal.length; _i < _len; point = ++_i) {
      s = signal[point];
      signal[point] = (signal_raw[point] + signal_raw2[point]) * dampness[point] * GAIN;
    }
    return make_dual_channel(signal);
  };

  make_dual_channel = function(signal) {
    var index, s, signal2, _i, _len;
    signal2 = mkbuf(signal.length * 2);
    for (index = _i = 0, _len = signal2.length; _i < _len; index = ++_i) {
      s = signal2[index];
      signal2[index] = signal[Math.floor(index / 2)];
    }
    return signal2;
  };

  window.play_freq = function(freq) {
    return play_signal(signal_gen_from_freq(freq));
  };

  window.playtone = function(tone) {
    var signal;
    signal = tone_gen(tone);
    return play_signal(signal);
  };

  window.play_signal = function(signal) {
    var point, ringlen, sample, _i, _len;
    point = dev.ringOffset;
    ringlen = dev.ringBuffer.length;
    for (_i = 0, _len = signal.length; _i < _len; _i++) {
      sample = signal[_i];
      point = (point + 1) % ringlen;
      dev.ringBuffer[point] += sample;
    }
    return true;
  };

  mk_ring_cleaner = function() {
    var clean_ring, len, prev_offset;
    prev_offset = 0;
    len = dev.ringBuffer.length;
    return clean_ring = function() {
      var end, offset, point;
      offset = dev.ringOffset;
      point = prev_offset;
      end = offset < prev_offset ? len + offset : offset;
      while (point < end) {
        dev.ringBuffer[point % len] = 0;
        point++;
      }
      return prev_offset = offset;
    };
  };

  setInterval(mk_ring_cleaner(), 200);

}).call(this);
// Generated by CoffeeScript 1.4.0
(function() {
  var ABCNotes, Jins, NoteName, ScaleArabicName, maqam_names_map;

  ABCNotes = "A B C D E F G".split(" ");

  window.stdNoteNames = ABCNotes;

  window.note_names_map = {
    A: "لا",
    B: "سي",
    C: "دو",
    D: "ري",
    E: "مي",
    F: "فا",
    G: "صول"
  };

  NoteName = (function() {

    function NoteName(name) {
      this.name = name;
      this.index = ABCNotes.indexOf(this.name);
    }

    NoteName.prototype.add = function(n) {
      return new NoteName(ABCNotes.at(this.index + n));
    };

    NoteName.prototype.next = function() {
      return this.add(1);
    };

    NoteName.prototype.prev = function() {
      return this.add(-1);
    };

    NoteName.prototype.display = function() {
      return note_names_map[this.name];
    };

    return NoteName;

  })();

  window.NoteName = NoteName;

  window.SimpleNoteName = function(noteCode) {
    if (!noteCode) {
      return "";
    }
    return note_names_map[noteCode[0]];
  };

  maqam_names_map = {
    "ajem": "عجم",
    "ajem-ajem": "عجم",
    "kurd": "كرد",
    "kurd-kurd": "كرد",
    "nahawend": "نهاوند",
    "nahawend-kurd": "نهاوند",
    "nahawend-hijaz": "نهاوند حجاز",
    "hijaz": "حجاز",
    "hijaz-kurd": "حجاز",
    "hijaz-beyat": "حجاز بياتي",
    "hijazkar": "حجاز كار",
    "hijaz-hijaz": "حجاز كار",
    "rast": "رست",
    "rast-rast": "رست",
    "rast-nahawend": "رست نهاوند",
    "beyat": "بياتي",
    "beyat-kurd": "بياتي",
    "beyat-beyat": "حسيني",
    "saba": "صبا",
    "saba-zemzem": "صبا",
    "saba-full": "صبا كامل",
    "saba-kurd": "صبا كامل",
    "zemzem": "زمزمة",
    "zemzem-zemzem": "زمزمة",
    "zemzem-full": "زمزمة كامل",
    "zemzem-kurd": "زمزمة كامل",
    "full": "كامل",
    "u": "<span class='icon'>u</span>",
    "d": "<span class='icon'>d</span>"
  };

  ScaleArabicName = function(maqam_code) {
    var map, parts;
    map = maqam_names_map;
    if (!maqam_code) {
      return "";
    }
    if (maqam_code in map) {
      return map[maqam_code];
    } else if (maqam_code.has('-')) {
      parts = maqam_code.split('-').map(ScaleArabicName);
      return parts.join(' ');
    } else {
      return maqam_code;
    }
  };

  window.ScaleArabicName = ScaleArabicName;

  Jins = (function() {

    function Jins(name, p1, p2, p3) {
      var self;
      this.name = name;
      this.p1 = p1;
      this.p2 = p2;
      this.p3 = p3;
      self = this;
      self.disp_name = ko.computed(function() {
        return ScaleArabicName(self.name);
      });
      self.disp_intervals = ko.computed(function() {
        return "--";
      });
    }

    Jins.prototype.notes = function(base) {
      var interval, res, _i, _len, _ref;
      res = [base];
      _ref = [this.p1, this.p2, this.p3];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        interval = _ref[_i];
        res.push(base.addInterval(interval));
      }
      return res;
    };

    Jins.prototype.intervalSteps = function() {
      return [this.p1, this.p2.sub(this.p1), this.p3.sub(this.p2)];
    };

    Jins.prototype.intervals = function() {
      return [this.p1, this.p2, this.p3];
    };

    return Jins;

  })();

  window.ajnas = {};

  ajnas.ajem = new Jins('ajem', intervals.lesserTone, intervals.majorThird, intervals.forth);

  ajnas.kurd = new Jins('kurd', intervals.semiTone, intervals.minorThird, intervals.forth);

  ajnas.hijaz = new Jins('hijaz', intervals.semiTone, intervals.majorThird, intervals.forth);

  ajnas.nahawend = new Jins('nahawend', intervals.tone, intervals.minorThird, intervals.forth);

  ajnas.beyat = new Jins('beyat', intervals.neutralSecond, intervals.minorThird, intervals.forth);

  ajnas.rast = new Jins('rast', intervals.lesserTone, intervals.neutralThird, intervals.forth);

  ajnas.saba = new Jins('saba', intervals.neutralSecond, intervals.minorThird, intervals.diminishedForth);

  ajnas.zemzem = new Jins('zemzem', intervals.semiTone, intervals.minorThird, intervals.diminishedForth);

}).call(this);
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

    "beyat": "D2 beyat kurd",
    "saba": "D2 saba zemzem",

    "nahawend-u": "C2 nahawend kurd",
    "nahawend-d": "C2 nahawend hijaz",


    "rast-u": "C2 rast rast",
    "rast-d": "C2 rast nahawend",

    "hijaz-u": "D2 hijaz beyat",
    "hijaz-d": "D2 hijaz kurd",

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

    self.interval_to_next = ko.computed(function() {
        return "5"; // XXX STUB
    });

    self.letter = ko.computed(function() {
        return piano.kbLayout().letterAt(row, column);
    })

    self.disp_freq = ko.computed(function() {
        var t = self.note();
        return t == null? "&nbsp;" : t;
    });

    self.disp_letter = ko.computed(function() {
        var letter = self.letter();
        if(letter != " ") {
            return letter;
        }
        return "&nbsp;"
    });

    self.note_name = ko.computed(function() {
        var base = piano.noteName();
        return base.add(self.key_index);
    });

    self.disp_note_name = ko.computed(function() {
        return self.note_name().display();
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

    self.position_class = ko.computed(function() {
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

    self.el_class = ko.computed(function() {
        return "key " + self.state_class() + " " + self.position_class();
    })

    self.container_class = ko.computed(function() {
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
        console.log("freq:", t);
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
        var scaleName = ScaleArabicName(compoundName);
        if(scaleName == compoundName) {
            scaleName = ScaleArabicName(jins1Name) + ' ' + ScaleArabicName(jins2Name);
        }
        var baseName = self.baseNote().noteName.display();
        return scaleName + ' على ' + baseName;
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

    self.note_at = function(octave_index, key_index) {
        if(key_index < 0) { // HACK, but works
            return self.note_at(octave_index - 1, key_index + 7)
        }
        var notes = self.octave_notes();
        if(key_index >= notes.length) {
            return self.note_at(octave_index +1, key_index - 7);
        }
        var note = notes.at(key_index);
        note = note.addInterval(intervals.octave.mul(octave_index));
        return note;
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
    }
    var kbkey;
    if(e.which in special) {
        kbkey = special[e.which]
    } else {
        kbkey = String.fromCharCode(e.which).toUpperCase()
    }
    return kbkey;
}
