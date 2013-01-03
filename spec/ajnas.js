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
        expect(res).toEqual(Ratio(2, 1));
    });

    it("Can be split into other ratios", function() {
        var r = Ratio(3, 2);
        var parts = r1.split(2);
        expect(parts.length).toEqual(2);
        expect(parts[0].add(parts[1])).toEqual(r);
        expect(parts).toContain(Ratio(6,5));
        expect(parts).toContain(Ratio(5,4));
    });


    it("Is always normalized", function() {
        expect(Ratio(3, 2)).toEqual(Ratio(6, 4));
    });
});


describe("OctaveRow", function() {
    var ocrow;

    beforeEach( function() {
        ocrow = new OctaveRow();
    });

    it("Contains a list of ajnas", function() {
        expect(ocrow.ajnas).toBeDefined();
        expect(ocrow.ajnas()).toBeDefined();
        // TODO: expect it to be a list!!
    });

    it("Contains always at least 2 ajnas", function() {
        expect(ocrow.ajnas().length).toEqual(2);
    });

    it("Can add extra ajnas, overflowing outside the octave boundary", function() {
        expect(ocrow.ajnas().length).toEqual(2);
        ocrow.addJinsRow();
        expect(ocrow.ajnas().length).toEqual(3);
    });

    it("The ajnas are always separated by perfect fifths", function() {
        expect(false).toBe(true);
        var checkFifths = function(jins_list){
            var prev = jins_list.shift();
            jins_list.each(function(cur) {
                expect(cur.distanceTo(prev)).toEqual(Ratio(3, 2));
            });
        }
    });
});

