# XXX fix this doc comment
# jins, scale, mode
#
# a jins (tetrachord) is a series of 4 intervals, spanning a forth or a diminished forth
#
# a scale is a series of jins concatenated together at "fifth" intervals
#
# maqam is an abstract concept that not only defines a mode but a playing style
# we don't actually deal with maqams directly, nor do we represent them directly
# if the word maqam is used anywhere in the code, it's a bug and should be fixed

# require: notes.js

ABCNotes = "A B C D E F G".split(" ")
window.stdNoteNames = ABCNotes

window.noteNamesMap = { A: "لا", B: "سي", C: "دو", D: "ري", E: "مي", F: "فا", G: "صول" }
class NoteName
    constructor: (@name) ->
        @index = ABCNotes.indexOf(@name)
    add: (n) ->
        return new NoteName(ABCNotes.at(@index+n))
    next: -> @add(1)
    prev: -> @add(-1)
    display: ->
        noteNamesMap[@name]

window.NoteName = NoteName

# where noteCode could be C2 or just C
window.SimpleNoteName = (noteCode) ->
    if !noteCode
        return ""
    return noteNamesMap[noteCode[0]]

maqam_names_map = {
    "ajem" : "عجم",
    "ajem-ajem" : "عجم",
    "kurd": "كرد",
    "kurd-kurd": "كرد",
    "nahawend": "نهاوند"
    "nahawend-kurd": "نهاوند"
    "nahawend-hijaz": "نهاوند حجاز",
    "hijaz": "حجاز"
    "hijaz-kurd": "حجاز"
    "hijaz-beyat": "حجاز بياتي",
    "hijazkar": "حجاز كار"
    "hijaz-hijaz": "حجاز كار"
    "rast": "رست"
    "rast-rast": "رست"
    "rast-nahawend": "رست نهاوند",
    "beyat" : "بياتي",
    "beyat-kurd" : "بياتي",
    "beyat-beyat" : "حسيني",
    "saba" : "صبا",
    "saba-zemzem" : "صبا",
    "saba-full": "صبا كامل",
    "saba-kurd": "صبا كامل",
    "zemzem": "زمزمة",
    "zemzem-zemzem": "زمزمة",
    "zemzem-full": "زمزمة كامل",
    "zemzem-kurd": "زمزمة كامل",
    "full": "كامل",
    "u": "<span class='icon'>u</span>", # HACK
    "d": "<span class='icon'>d</span>", # HACK
}

ScaleArabicName = (maqam_code) ->
    map = maqam_names_map
    if !maqam_code
        return ""
    if maqam_code of map
        map[maqam_code]
    else if maqam_code.has('-')
            parts = maqam_code.split('-').map(ScaleArabicName)
            return parts.join(' ')
    else
        maqam_code

window.ScaleArabicName = ScaleArabicName

class Jins
    constructor: (@name, @p1, @p2, @p3) ->
        self = this
        self.displayName = ko.computed ->
            ScaleArabicName(self.name)
        self.dispIntervals = ko.computed ->
            return "--"
            # [self.p1, self.p2, self.p3].join("-")

    # assuming base is a Note object
    # returns an array of Note objects
    notes: (base) ->
        res = [base]
        for interval in [@p1, @p2, @p3]
            res.push base.addInterval(interval)
        return res

    intervalSteps: ->
        [@p1, @p2.sub(@p1), @p3.sub(@p2)]

    intervals:->
        [@p1, @p2, @p3]

J2 = intervals.tone
j2 = intervals.lessertTone
m2 = intervals.semiTone
M2 = intervals.biggerSemiTone
t2 = intervals.neutralSecond
T2 = intervals.biggerNeutralSecond
J3 = intervals.majorThird
M3 = intervals.minorThird
T3 = intervals.neutralThird
p4 = intervals.forth
d4 = intervals.diminishedForth
D4 = intervals.biggerDiminishedForth
p5 = intervals.fifth

# Define the ajnas
window.ajnas = {}
ajnas.ajem = new Jins('ajem', intervals.lesserTone, intervals.majorThird, intervals.forth)
ajnas.kurd = new Jins('kurd', intervals.semiTone, intervals.minorThird, intervals.forth)
ajnas.hijaz = new Jins('hijaz', intervals.semiTone, intervals.majorThird, intervals.forth)
ajnas.nahawend = new Jins('nahawend', intervals.tone, intervals.minorThird, intervals.forth)
ajnas.beyat = new Jins('beyat', intervals.neutralSecond, intervals.minorThird, intervals.forth)
ajnas.rast = new Jins('rast', intervals.lesserTone, intervals.neutralThird, intervals.forth)
ajnas.saba = new Jins('saba', intervals.neutralSecond, intervals.minorThird, intervals.diminishedForth)
ajnas.zemzem = new Jins('zemzem', intervals.semiTone, intervals.minorThird, intervals.diminishedForth)

# XXX do something about this ..
# window.selected_mode = ko.observable($.cookie('mode') || 'ajem')
# selected_mode.subscribe( (val) ->
#     $.cookie('mode', val)
# )


# just a sanity check
# if(window.selected_mode() not of maqamPresetMap)
#     window.selected_mode('ajem')
