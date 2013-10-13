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

noteNamesMap = {}
noteNamesMap.ar = { A: "لا", B: "سي", C: "دو", D: "ري", E: "مي", F: "فا", G: "صول" }
noteNamesMap.tr = { A: "La", B: "Si", C: "Do", D: "Re", E: "Mi", F: "Fa", G: "Sol" }
noteNamesMap.en = noteNamesMap.tr # { A: "A", B: "B", C: "C", D: "D", E: "E", F: "F", G: "G" }

window.getNoteName = (name) ->
    noteNamesMap[language()][name]

class NoteName
    constructor: (@name) ->
        @index = ABCNotes.indexOf(@name)
    add: (n) ->
        return new NoteName(ABCNotes.at(@index+n))
    next: -> @add(1)
    prev: -> @add(-1)
    display: ->
        getNoteName(@name)

window.NoteName = NoteName

# where noteCode could be C2 or just C
window.SimpleNoteName = (noteCode) ->
    if !noteCode
        return ""
    return getNoteName(noteCode[0])

maqam_names = {}

maqam_names.ar = {
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
    "hijaz-hijaz": "حجاز كار"
    "rast": "رست"
    "rast-rast": "رست"
    "rast-nahawend": "رست نهاوند",
    "beyat" : "بياتي",
    "beyat-kurd" : "بياتي",
    "beyat-beyat" : "حسيني",
    "saba" : "صبا",
    "saba-zemzem" : "صبا",
    "saba-kurd": "صبا كامل",
    "zemzem": "زمزمة",
    "zemzem-zemzem": "زمزمة",
    "zemzem-kurd": "زمزمة كامل",
    "u": "<span class='icon'>u</span>", # HACK
    "d": "<span class='icon'>d</span>", # HACK
}

maqam_names.en = {
    "ajem" : "Ajem",
    "ajem-ajem" : "Major",
    "kurd": "Kurd",
    "kurd-kurd": "Kurd",
    "nahawend": "Nahwnd"
    "nahawend-kurd": "Minor"
    "nahawend-hijaz": "Harmonic Minor",
    "hijaz": "Hijaz"
    "hijaz-kurd": "Hijaz"
    "hijaz-beyat": "Hijaz Beyat",
    "hijaz-hijaz": "Hijaz Kar"
    "rast": "Rast"
    "rast-rast": "Rast"
    "rast-nahawend": "Rast Nahwnd",
    "beyat" : "Beyat",
    "beyat-kurd" : "Beyat",
    "beyat-beyat" : "Huseiny",
    "saba" : "Saba",
    "saba-zemzem" : "Saba",
    "saba-kurd": "Saba Kurd",
    "zemzem": "Zemzem",
    "zemzem-zemzem": "Zemzem",
    "zemzem-kurd": "Zemzem Kurd",
    "u": "<span class='icon'>u</span>", # HACK
    "d": "<span class='icon'>d</span>", # HACK
}

maqam_names.tr = {
    "ajem" : "Acem",
    "ajem-ajem" : "Acem",
    "kurd": "Kürdi",
    "kurd-kurd": "Kürdi",
    "nahawend": "Buselik"
    "nahawend-kurd": "Buselik"
    "nahawend-hijaz": "Buselik Hicaz",
    "hijaz": "Hicaz"
    "hijaz-kurd": "Hicaz"
    "hijaz-beyat": "Hicaz Uşşak",
    "hijaz-hijaz": "Hicaz Kar"
    "rast": "Rast"
    "rast-rast": "Rast"
    "rast-nahawend": "Rast Nahawend",
    "beyat" : "Uşşak",
    "beyat-kurd" : "Uşşak",
    "beyat-beyat" : "Hüseyni",
    "saba" : "Saba",
    "saba-zemzem" : "Saba",
    "saba-kurd": "Saba Kurd",
    "zemzem": "Zemzeme",
    "zemzem-zemzem": "Zemzeme",
    "zemzem-kurd": "Zemzeme Kurd",
    "u": "<span class='icon'>u</span>", # HACK
    "d": "<span class='icon'>d</span>", # HACK
}

# Get the display name for a maqam/jins based on the 'code' (e.g. 'ajem', 'hijaz', etc)
getScaleName = (maqam_code) ->
    map = maqam_names[language()]
    if !maqam_code
        return ""
    if maqam_code of map
        map[maqam_code]
    else if maqam_code.has('-')
            parts = maqam_code.split('-').map(getScaleName)
            return parts.join(' ')
    else
        maqam_code

window.getScaleName = getScaleName

class Jins
    constructor: (@name, @p1, @p2, @p3) ->
        self = this
        self.displayName = ko.computed ->
            getScaleName(self.name)
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
M2 = intervals.semiTone
T2 = intervals.neutralSecond
J3 = intervals.majorThird
M3 = intervals.minorThird
T3 = intervals.neutralThird
P4 = intervals.forth
D4 = intervals.biggerDiminishedForth
P5 = intervals.fifth

# Define the ajnas
window.ajnas = {}
ajnas.ajem = new Jins('ajem', J2, J3, P4)
ajnas.kurd = new Jins('kurd', M2, M3, P4)
ajnas.hijaz = new Jins('hijaz', M2, J3, P4)
ajnas.nahawend = new Jins('nahawend', J2, M3, P4)
ajnas.beyat = new Jins('beyat', T2, M3, P4)
ajnas.rast = new Jins('rast', J2, T3, P4)
ajnas.saba = new Jins('saba', T2, M3, D4)
ajnas.zemzem = new Jins('zemzem', M2, M3, D4)
