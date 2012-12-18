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
        "jiharkah": "جهاركاه"
    }
    if maqam_code of map
        map[maqam_code]
    else
        maqam_code

window.disp_name = disp_name
ajnas_defs =
    "ajam": "9 9 4"
    "rast": "8 7 7"
    "nhwnd": "9 4 9"
    "bayati": "6 7 9"
    "hijaz": "5 12 5"
    # "saba": "6 7 5" # will be defined as a broken bayati
    "kurd": "4 9 9"
    "jiharkah": "9 8 5"

FORTH = 22
FIFTH = 31
OCTAVE = 53

class Jins
    constructor: (@p1, @p2, @p3) ->
        total = @p1 + @p2 + @p3
        if total not in [18, 22]
            console.log "Bad Jins", @p1, @p2, @p3, " total:", total

    # return a Jins that's 18 units long (2 full tones) instead of 22
    broken: ->
        return new Jins(@p1, @p2, 18-(@p1+@p2))

    isBroken: ->
        return @p1 + @p2 + @p3 < FORTH

    genTones: (start) ->
        distances = [@p1, @p2, @p3]
        res = [start]
        for displacement in distances
            res.push(u.last(res) + displacement)
        stabilize = (num) -> Number num.toFixed(2)
        u.map(res, stabilize)

class Mode # maqam/scale with a starting point
    constructor: (@name, @base, @jins1, @jins2) ->
        self = this

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
        start = @base + (octave * OCTAVE)
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
    ajnas[key] = new Jins(args...)

# The `ajnas` dict maps jins name to a Jins object

# a maqam def is starting point and 2 jins
maqam_defs =
    "ajam": "0 ajam ajam"
    "kurd": "9 kurd kurd"
    "hijaz1": "9 hijaz bayati"
    "hijaz2": "9 hijaz kurd"
    "rast1": "0 rast rast"
    "rast2": "0 rast nhwnd"
    "nhwnd1": "0 nhwnd hijaz"
    "nhwnd2": "0 nhwnd kurd"
    "bayati": "9 bayati kurd"
    # "saba": "9 saba zamzama" # to be defined as a broken bayati
    "jiharkah": "9 jiharkah jiharkah"

window.selected_maqam = ko.observable($.cookie('maqam') || 'ajam')

selected_maqam.subscribe( (val) ->
    $.cookie('maqam', val)
)

window.maqamat = {}
for name, def of maqam_defs
    parts = def.split(" ")
    start = Number parts.shift()
    jins1 = ajnas[parts.shift()]
    jins2 = ajnas[parts.shift()]
    maqamat[name] = new Mode(name, start, jins1, jins2)

#saba
maqamat["saba"] = (new Mode("saba", 9, ajnas["bayati"].broken(), ajnas["kurd"].broken()))


# TODO get rid of this crap

class ScaleGraph
    constructor: (parent) ->
        @el = $("<canvas id='scale_graph_cvs' width='300px' height='40px'></canvas>")
        parent.append(@el)
        @canvas = @el.get(0)
        @ctx = @canvas.getContext('2d')
        @bg_color = "hsl(0,0%,80%)"
        @fg_color = "hsl(0,0%,40%)"
        @line_color = "hsl(0, 0%, 60%)"
    draw_scale: (scale) =>
        @ctx.clearRect(0, 0, @canvas.width, @canvas.height)
        #draw bg line and points
        @draw_line(0, 6, @bg_color)
        @draw_point(0, @bg_color)
        @draw_point(6, @bg_color)
        # draw a line from start to the last point on scale
        s = 0
        for p in scale
            s += p
        @draw_line(0, s, @line_color)
        #start drawing points
        s = 0
        @draw_point(s, @fg_color)
        for p in scale
            s += p
            @draw_point(s, @fg_color)
    draw_point: (dist, color) =>
        #@ctx.fillStyle = color
        #@ctx.strokeStyle = color
        #@ctx.fillRect(@x_coord(dist)-2, 10, 5, 5)
        artisan.drawCircle('scale_graph_cvs', @x_coord(dist), 13, 3, color, 0, color, 10)
    draw_line: (start, end, color) =>
        @ctx.fillStyle = color
        @ctx.fillRect(@x_coord(start), 12, @x_coord(end) - @x_coord(start), 2)
    x_coord: (point) =>
        10 + point * 40

