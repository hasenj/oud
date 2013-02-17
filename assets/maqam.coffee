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
        "nhwnd": "نهاوند"
        "nhwnd1": "نهاوند صعودا",
        "nhwnd2": "نهاوند هبوطا",
        "hijaz": "حجاز"
        "hijaz1": "حجاز صعودا",
        "hijaz2": "حجاز هبوطا",
        "hijazkar": "حجاز كار"
        "rast": "رست"
        "rast1": "رست صعودا",
        "rast2": "رست هبوطا",
        "bayati" : "بياتي",
        "saba" : "صبا"
        "saba-full": "صبا كامل"
        "zamzama": "زمزمة"
        "mahuri": "ماهوري"
        "huseni": "حسيني"
        "chaharga": "چهرگاه"
        "nairuz": "نيروز"
    }
    if maqam_code of map
        map[maqam_code]
    else
        maqam_code

maqam_desc =
    "ajam": "و هو مماثل لسلم الميجور الغربي"
    "kurd": ""
    "rast": "ابو المقامات الشرقية"
    "bayati": ""
    "hijaz": ""
    "saba": "المقام الحزين المنكسر"
    "nhwnd": ""
    "huseni": ""
    "mahuri": "من مشتقات العجم، و يستعمل في العراق في الاعياد في التكبيرات و قرائة القرآن"

window.disp_name = disp_name
ajnas_defs =
    "ajam": "9 8 5"
    "nhwnd": "9 5 8"
    "bayati": "7 7 8"
    "rast": "8 7 7"
    "hijaz": "5 12 5"
    "kurd": "5 8 9"
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

    # return a Jins with a broken forth
    broken: ->
        if @p3 <= 5
            console.log "Jins can't be broken!"
            # return a copy of self!
            return new Jins(@name, @p1, @p2, @p3)
        return new Jins(@name + "-broken", @p1, @p2, 5)

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

        self.disp_desc = ko.computed ->
            if self.name of maqam_desc
                maqam_desc[self.name]
            else
                ""

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
    "huseni": "31 bayati bayati"
    "hijaz1": "9 hijaz bayati"
    "hijaz2": "9 hijaz kurd"
    "hijazkar": "9 hijaz hijaz"
    "nhwnd1": "0 nhwnd hijaz"
    "nhwnd2": "0 nhwnd kurd"
    "bayati": "9 bayati kurd"
    "saba": "9 saba zamzama"
    "saba-full": "9 saba kurd"
    "zamzama": "9 zamzama zamzama"
    # "chaharga": "22 ajam rast"
    # "nairuz": "0 rast bayati"

window.maqamat = {}
for name, def of maqam_defs
    parts = def.split(" ")
    start = Number parts.shift()
    jins1 = ajnas[parts.shift()]
    jins2 = ajnas[parts.shift()]
    maqamat[name] = new Mode(name, start, jins1, jins2)

selected_maqam.subscribe( (val) ->
    $.cookie('maqam', val)
)

if(window.selected_maqam() not of maqamat)
    window.selected_maqam('ajam')
