u = _
####
# maqam presets
#   A scale is defined as a sequency of tone distances
#   Some scales have the special property that they don't end in 6 full tones
#   This is handled in keyboard.coffee in a way that works
#
#   A maqam is a scale + a starting point

disp_name = (maqam_code) ->
    map = {
        "ajam" : "عجم",
        "kurd": "كرد",
        "nhwnd1": "نهاوند صعودا",
        "nhwnd2": "نهاوند هبوطا",
        "hijaz1": "حجاز صعودا",
        "hijaz2": "حجاز هبوطا",
        "rast1": "رست صعودا",
        "rast2": "رست هبوطا",
        "bayati" : "بياتي",
        "saba" : "صبا"
        "mahuri": "ماهوري"
        "huseni": "حسيني"
    }
    if maqam_code of map
        map[maqam_code]
    else
        maqam_code

window.disp_name = disp_name
ajnas_defs =
    "ajam": "9 8 5"
    "rast": "9 7 6"
    "nhwnd": "9 5 8"
    "bayati": "7 7 8"
    "hijaz": "5 12 5"
    # "saba": "6 7 5" # will be defined as a broken bayati
    "kurd": "5 9 8"

FORTH = 22
FIFTH = 31
OCTAVE = 53

class Jins
    constructor: (@name, @p1, @p2, @p3) ->
        total = @p1 + @p2 + @p3
        if total not in [19, 22]
            console.log "Bad Jins", @p1, @p2, @p3, " total:", total

    # return a Jins that's 19 units long (2 full tones) instead of 22
    broken: ->
        return new Jins(@name, @p1, @p2, 19-(@p1+@p2))

    isBroken: ->
        return @p1 + @p2 + @p3 < FORTH

    genTones: (start) ->
        distances = [@p1, @p2, @p3]
        res = [start]
        for displacement in distances
            res.push(u.last(res) + displacement)
        stabilize = (num) -> Number num.toFixed(2)
        u.map(res, stabilize)

window.selected_maqam = ko.observable($.cookie('maqam') || 'ajam')

class Mode # maqam/scale with a starting point
    constructor: (@name, base, @jins1, @jins2) ->
        self = this

        self.base = ko.observable(base)

        self.disp_name = ko.computed ->
            disp_name(self.name)

        self.isActive = ko.computed ->
            selected_maqam() == self.name

        # for the maqam button
        self.el_class = ko.computed ->
            cls = "maqam_btn"
            if self.isActive()
                cls += " active"
            return cls


    genTones: (octave) ->
        start = @base() + (octave * OCTAVE)
        result = []
        result = result.concat @jins1.genTones(start)
        result = result.concat @jins2.genTones(start + FIFTH)
        if @jins2.isBroken()
            result = result.concat @jins2.genTones(start + FIFTH + FIFTH)
        return result

    select: ->
        selected_maqam(@name)



window.Mode = Mode

ajnas = {}
for key, val of ajnas_defs
    args = (Number n for n in val.split(" "))
    ajnas[key] = new Jins(key, args...)

# The `ajnas` dict maps jins name to a Jins object

# a maqam def is starting point and 2 jins
maqam_defs =
    "ajam": "0 ajam ajam"
    "kurd": "9 kurd kurd"
    "mahuri": "0 ajam nhwnd"
    "rast1": "0 rast rast"
    "rast2": "0 rast nhwnd"
    "bayati": "9 bayati kurd"
    "hijaz1": "9 hijaz bayati"
    "hijaz2": "9 hijaz kurd"
    "saba": "9 bayati kurd" # saba -- will be overriden later; here for ordering purposes only
    "nhwnd1": "0 nhwnd hijaz"
    "nhwnd2": "0 nhwnd kurd"
    "huseni": "31 bayati bayati"

window.maqamat = {}
for name, def of maqam_defs
    parts = def.split(" ")
    start = Number parts.shift()
    jins1 = ajnas[parts.shift()]
    jins2 = ajnas[parts.shift()]
    maqamat[name] = new Mode(name, start, jins1, jins2)

#saba
maqamat["saba"] = (new Mode("saba", 9, ajnas.bayati.broken(), ajnas.kurd.broken()))

selected_maqam.subscribe( (val) ->
    $.cookie('maqam', val)
)

if(window.selected_maqam() not of maqamat)
    window.selected_maqam('ajam')
