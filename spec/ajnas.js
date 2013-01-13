describe("Ratio", function() {
    it("is built out of 2 values, represented as `a` and `b`", function() {
        var r = Ratio(2, 3);
        expect(r.a).toEqual(2);
        expect(r.b).toEqual(3);
    });

    it("has toString which return a string of the form 'a:b'", function() {
        var r = Ratio(3, 2);
        expect(r.toString()).toEqual("3:2");
    });

    it("can be added to other ratios", function() {
        var r1 = Ratio(3,2);
        var r2 = Ratio(4,3);

        var res = r1.add(r2);
        var expected = Ratio(2, 1);
        expect(res.equals(expected)).toBe(true);
    });

    it("Can be split into other ratios", function() {
        var r = Ratio(3, 2);
        var parts = r.split(2);
        expect(parts.length).toEqual(2);
        expect(parts[0].add(parts[1]).equals(r)).toBe(true);
        parts = parts.map('toString');
        expect(parts).toContain("6:5");
        expect(parts).toContain("5:4");
    });


    it("Is always normalized", function() {
        var r = Ratio(6, 4);
        expect(r.a).toEqual(3);
        expect(r.b).toEqual(2);
        expect(r.toString()).toEqual("3:2");
    });

    it("Can be `multiplied`; added to itself multiple times", function() {
        var r = Ratio(2, 1);
        expect(r.mul(4).equals(r.add(r).add(r).add(r))).toBe(true)
        expect(r.mul(4).toString()).toEqual("16:1")
        var r2 = Ratio(4,3);
        expect(r2.mul(2).equals(r2.add(r2))).toBe(true);

    });

    it("Multiplying by `0` return the identity ratio 1:1", function() {
        var r = Ratio(2, 1);
        var r2 = Ratio(5,3);
        var identity = Ratio(1,1);
        expect(r.mul(0).equals(identity)).toBe(true);
        expect(r2.mul(0).equals(identity)).toBe(true);
    });

    it("Multiplying by a negative is like multiplying the inverse", function() {
        var r = Ratio(7, 4);
        var v = r.inverse();
        expect(r.mul(-2).equals(v.mul(2))).toBe(true);
        expect(r.mul(-5).equals(v.mul(5))).toBe(true);
    });
});

describe("Note", function() {

    var baseNote = new Note(128);

    it("Has a frequency", function() {
        expect(baseNote.freq()).toBeDefined();
        expect(baseNote.freq()).toEqual(128);
    });

    it("Can create a new note by applying a ratio", function() {
        var n5 = baseNote.addRatio(Ratio(3, 2));
        expect(n5.freq()).toEqual(128 * 3 / 2);
    });

    /* // let's not do this idea .. (at least for now)
    it("Notes calculated that way are lazy", function() {
        // lazy meaning they never store their "frequency" internally;
        // they just calculated it when requested via .freq()
        expect(baseNote.frequency).toBeDefined();
        var n5 = baseNote.addRatio(Ratio(3, 2));
        expect(n5.frequency).toBeUndefined();
        expect(n5.baseNote).toBeDefined();
        expect(n5.ratio).toBeDefined();
    });
    */

});

describe("Instrument", function() {
    // there's a global 'instrument'; no need to make an instant ourselves
    var instrument = window.oud.instrument;
    it("Contains a list of diwans; 'octave-string-groups'", function() {
        expect(instrument.diwans).toBeDefined();
        expect(instrument.diwans()).toBeDefined();
    });

    var diwan = instrument.diwans().first();
    describe("Diwan", function() {
        it("contains a list of awtar jins", function() {
            expect(diwan.ajnas).toBeDefined();
            expect(diwan.ajnas()).toBeDefined();
            expect(diwan.ajnas().length >= 2).toBe(true);
        });

        var jins = diwan.ajnas().first();
        describe("WatarJins", function() {
            it("Contains 4 groups of keys", function() {
                expect(jins.groups()).toBeDefined();
                expect(jins.groups().length).toEqual(4);
            });

            it("Each group contains some keys", function() {
                expect(jins.groups().first().keys().length > 0).toBe(true);
            });
        });
    });
});

// this should get moved inside the instrument suite
describe("OctaveRow", function() {
    var ocrow;

    /*
    it("Contains always at least 2 ajnas", function() {
        expect(false).toBe(true);
    });

    it("Can add extra ajnas, overflowing outside the octave boundary", function() {
        expect(false).toBe(true);
    });

    it("The ajnas are always separated by perfect fifths", function() {
        expect(false).toBe(true);
        var checkFifths = function(jins_list){
            var prev = jins_list.shift();
            jins_list.each(function(cur) {
                var ratio = cur.baseNote().ratioTo(prev.baseNote());
                var perfectFifth = Ratio(3, 2);
                expect(ratio.equals(perfectFifth)).toBe(true);
                prev = cur;
            }, 0, true);
        }

        checkFifths(ocrow.ajnas());
        // should remain true even after we add ajnas
        ocrow.addJinsRow();
        checkFifths(ocrow.ajnas());
        ocrow.addJinsRow();
        checkFifths(ocrow.ajnas());
    });
    */
});

