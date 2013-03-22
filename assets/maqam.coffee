u = _

# jins, scale, mode
#
# a jins (tetrachord) is a series of 4 intervals, spanning a forth or a diminished forth
#
# a scale is a series of jins concatenated together at "fifth" intervals
#
# a mode is a scale with a starting point
#   so itcan be used to build a concrete list of notes
#
# maqam is an abstract concept that not only defines a mode but a playing style
# we don't actually deal with maqams directly, nor do we represent them directly
# if the word maqam is used anywhere in the code, it's a bug and should be fixed

disp_name = (maqam_code) ->
    map = {
        "ajam" : "عجم",
        "kurd": "كرد",
        "nhwnd": "نهاوند"
        "nhwnd-hijaz": "نهاوند حجاز",
        "hijaz": "حجاز"
        "hijaz-bayati": "حجاز بياتي",
        "hijazkar": "حجاز كار"
        "rast": "رست"
        "rast-nhwnd": "رست نهاوند",
        "bayati" : "بياتي",
        "saba" : "صبا"
        "saba-full": "صبا كامل"
        "zamzama": "زمزمة"
        "zamzama-full": "زمزمة كامل"
        "mahuri": "ماهوري"
        "charga": "چهرگاه"
        "huseyni": "حسيني"
    }
    if maqam_code of map
        map[maqam_code]
    else
        maqam_code

scale_desc =
    "ajam": "و هو مماثل لسلم الميجور الغربي"
    "kurd": ""
    "rast": "ابو المقامات الشرقية"
    "bayati": ""
    "hijaz": ""
    "saba": "المقام الحزين المنكسر"
    "nhwnd": "و هو مماثل لسلم المينور الغربي"

window.disp_name = disp_name
ajnas_defs =
    # major
    "ajam": "9 8 5"
    "hijaz": "5 12 5"
    # minor
    "nhwnd": "9 5 8"
    "kurd": "5 8 9"
    "bayati": "7 7 8"
    # neutral
    "rast": "8 7 7"
    # diminished
    "saba": "7 7 5"
    "zamzama": "5 9 5"

FORTH = 22
FIFTH = 31
OCTAVE = 53

class Jins
    constructor: (@name, @p1, @p2, @p3) ->
        total = @p1 + @p2 + @p3
        self = this
        self.disp_name = ko.computed ->
            disp_name(self.name)
        self.disp_intervals = ko.computed ->
            [self.p1, self.p2, self.p3].join("-")

    genTones: (start) ->
        distances = [@p1, @p2, @p3]
        res = [start]
        for displacement in distances
            res.push(u.last(res) + displacement)
        res

window.selected_mode = ko.observable($.cookie('mode') || 'ajam')
selected_mode.subscribe( (val) ->
    $.cookie('mode', val)
)


class Mode # maqam/scale with a starting point
    constructor: (@name, base, @jins1, @jins2, @jins3) ->
        self = this

        self.base = ko.observable(base)

        self.disp_name = ko.computed ->
            disp_name(self.name)

        self.disp_desc = ko.computed ->
            if self.name of scale_desc
                scale_desc[self.name]
            else
                ""

        self.isActive = ko.computed ->
            selected_mode() == self.name

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
        if @jins3
            result = result.concat @jins3.genTones(start + FIFTH + FIFTH)
        return result

    select: ->
        selected_mode(@name)

window.Mode = Mode

ajnas = {}
for key, val of ajnas_defs
    args = (Number n for n in val.split(" "))
    ajnas[key] = new Jins(key, args...)

# The `ajnas` dict maps jins name to a Jins object

# a mode def is starting point and 2 (or 3) jins
maqam_defs =
    "ajam": "0 ajam ajam"
    "kurd": "9 kurd kurd"

    "nhwnd": "0 nhwnd kurd"
    "nhwnd-hijaz": "0 nhwnd hijaz"

    "bayati": "9 bayati kurd"
    "rast": "0 rast rast"

    "hijaz": "9 hijaz kurd"
    "hijaz-bayati": "9 hijaz bayati"

    "saba": "9 saba zamzama zamzama"
    "zamzama": "9 zamzama zamzama zamzama"

    "saba-full": "9 saba kurd"
    "zamzama-full": "9 zamzama kurd"

window.modes = {}
for name, def of maqam_defs
    parts = def.split(" ")
    start = Number parts.shift()
    jins1 = ajnas[parts.shift()]
    jins2 = ajnas[parts.shift()]
    jins3 = ajnas[parts.shift()] || null
    modes[name] = new Mode(name, start, jins1, jins2, jins3)

# just a sanity check
if(window.selected_mode() not of modes)
    window.selected_mode('ajam')
