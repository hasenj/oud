// This is to be run as a node.js script

// It drops into a shell and allows one to play around with ratios

require("../assets/ratios");

show = function(item, indent) {
    if(!indent) {
        indent = "";
    }
    indent = "" + indent; // force to string

    if(item.repr) {
        console.log(indent + item.repr());
    } else if(item.length) {
        for(var i = 0; i < item.length; i++) {
            console.log(indent + item[i].repr());
        }
    } else {
        console.log("What?");
    }
}

demo = function(title, item) {
    console.log(title + ": ");
    show(item, "  ");
    console.log();
}

et = function(amount, steps) {
    var ctor = function() {
        var self = this;
        self.value = Math.pow(2, amount/steps);
        self.linear = Math.log(self.value) / Math.log(2);
        self.commas = (self.linear * 53).toFixed(2);
        self.semitones = (self.linear * 12).toFixed(2);

        self.repr = function() {
            return self.value.toFixed(4) + " | " + self.semitones + " ET semitones" + " | " + self.commas + " ET commas";
        }
    }
    return new ctor();
}

in_repl = true;
if (in_repl) {

(function() { // do ->
    octave = Ratio(2,1);
    fifth = Ratio(3,2);
    forth = Ratio(4,3);
    major_third = Ratio(5, 4);
    minor_third = Ratio(6, 5);
    tone = fifth.sub(forth);
    semitone = minor_third.sub(tone); // actual semitone
    small_tone = major_third.sub(tone);
    diatone = tone.add(tone);
    pysemi = forth.sub(diatone); // pythagrean semitone
    neutral_second = minor_third.split(2)[0];
    neutral_third = Ratio(11,9)
    hijaz = Ratio(7,6)
    diminished_forth = Ratio(9,7)

    demo("Tone", tone);
    demo("Smaller Tone", small_tone)
    demo("Semitone", semitone);
    demo("Neutral Second", neutral_second);
    demo("Hijaz one-half interval", hijaz);

    demo("Minor Third", minor_third);
    demo("Major Third", major_third);

    demo("Neutral second(s); three-quarter tones", minor_third.split(2));

show_oud = function(len) { // show oud places with proposed watar length
    var places = [
        ["Semitone", semitone],
        ["Neutral Second", neutral_second],
        ["Whole Tone", tone],
        ["Minor Third", minor_third],
        ["Major Third", major_third],
        ["Diminished Forth", minor_third.add(semitone)],
        ["Forth", forth],
        ["Fifth", fifth]
    ];
    places.forEach(function(place) {
        var title = place[0];
        var interval = place[1];
        console.log(title + ":", interval.oud(len).toFixed(2));
    });
}


    // drop into a repl!
    try {
        repl = require("repl");
        repl.start("node.js> ");
    } catch(e) {
        console.log("Trapped: ", e);
    }

}());
}

