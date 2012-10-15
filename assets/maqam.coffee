u = _
####
# maqam presets
#   A scale is defined as a sequency of tone distances
#   Some scales have the special property that they don't end in 6 full tones
#   This is handled in keyboard.coffee in a way that works
#
#   A maqam is a scale + a starting point

maqam_ctor = (name, start, jins1, jins2) ->
    {name, start, jins1, jins2}

ajnas_defs =
    "ajam": "9 9 4"
    "rast": "9 7 6"
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
    constructor: (@base, @jins1, @jins2) ->

    genTones: (octave) ->
        start = @base + (octave * OCTAVE)
        result = []
        result.contact @jins1.genTones(start)
        result.contact @jins2.genTones(start + FIFTH)
        if @jins2.isBroken
            result.concat @jins2.genTones(start + FIFTH + FIFTH)


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

window.maqamat = {}
for name, def of maqam_defs
    parts = def.split(" ")
    start = Number parts.shift()
    jins1 = ajnas[parts.shift()]
    jins2 = ajnas[parts.shift()]
    maqamat[name] = new Mode(start, jins2, jins2)

#saba
maqamat["saba"] = (new Mode(9, ajnas["bayati"].broken(), ajnas["kurd"].broken()))

disp_name = (maqam) ->
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
    if maqam.name of map
        map[maqam.name]
    else
        maqam.name

if not window.updkeys?
    window.updkeys = ->

set_active_maqam = (maqam) ->
    window.active_maqam = maqam # XXX not a clone, ok?
    $("#maqam_name").html("مقام ال" + disp_name maqam)
    $.cookie('maqam', maqam.name)
    updkeys maqam

init_maqams = ->
    default_maqam = $.cookie('maqam') ? 'ajam'
    el = $("#maqam_section")
    # window.start_widget = new StartWidget el, 0
    window.maqam_list = new MaqamList el, maqamat, default_maqam

jimg = (src) -> $("<img>").attr('src', src)

arrow = (dir) -> jimg("/arr_#{dir}.png")

# TODO get rid of this crap
class StepperWidget
    constructor: (parent, @value=0, @step=0.25, @orientation='vertical') ->
        @el = jdiv()
        parent.append(@el)
        @render_ui()
        evt.bind(this, "changed", @update_ui)
    _inc: (amt) =>
        @set_val(@get_val() + amt)
    inc: => @_inc(@step)
    dec: => @_inc(-@step)
    get_val: => @value
    set_val: (val) =>
        @value = val
        evt.trigger(this, "changed", @value)
    render_ui: ->
        orn = @orientation
        first = 'inc'
        second = 'dec'
        first_sym = arrow('up')
        second_sym = arrow('down')
        if orn == 'horizontal'
            [first,second] = [second, first]
            second_sym = arrow('right')
            first_sym = arrow('left')
        @el.addClass("widget_stepper")
        @el.addClass(@orientation)
        @el.append jdiv().addClass("button").addClass(first).append(first_sym)
        @el.append jdiv().addClass("val").html(@value)
        @el.append jdiv().addClass("button").addClass(second).append(second_sym)
        $(".inc", @el).click(@inc)
        $(".dec", @el).click(@dec)
        $(".button", @el).css('visibility', 'hidden')
        @el.mouseenter => $(".button", @el).css('visibility', 'visible')
        @el.mouseleave => $(".button", @el).css('visibility', 'hidden')
    update_ui: =>
        $(".val", @el).html(@value)

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

class ScaleWidget
    constructor: (parent, scale) ->
        @el = jdiv()
        parent.append(@el)
        @steppers = ((new StepperWidget(@el, tone)) for tone in scale)
        for s in @steppers
            evt.bind(s, "changed", @on_stepper_change)
        @vis = new ScaleGraph @el
        @render_ui()
    set_val: (scale) =>
        for s, i in @steppers
            s.set_val(scale[i])
    get_val: =>
        (s.get_val() for s in @steppers)
    render_ui: =>
        # steppers will auto-render 
        @update_ui() # render the scale display
    on_stepper_change: =>
        evt.trigger(this, "changed", @get_val())
        @update_ui()
    update_ui: =>
        scale = @get_val()
        @vis.draw_scale(scale)

class StartWidget
    constructor: (parent, @value) ->
        @el = jdiv()
        @el.addClass("start_widget")
        parent.append(@el)
        @el.append("<span class='text'>On</span>")
        @stepper = new StepperWidget @el, @value, 0.25, 'horizontal'
        @el.append("<span class='text note_info'></span>")
        @update_ui()
        evt.bind(@stepper, "changed", @on_stepper_change)
    get_val: => @stepper.get_val()
    set_val: (val) => @stepper.set_val(val)
    on_stepper_change: =>
        evt.trigger(this, "changed", @get_val())
        @update_ui()
    update_ui: =>
        # figure out the note name
        info = get_note_info(@get_val())
        diff_disp = (diff) ->
            map = 
                "-0.25" : "half bemol"
                "-0.5"  : "bemole"
                "0"     : "natural"
                "0.25"  : "half diese"
                "0.5"   : "diese"
            if "" + diff of map
                map[diff]
            else if diff > 0
                "+" + diff
            else
                "" + diff
        $(".note_info", @el).html(info.note.name + "&nbsp;" + diff_disp info.diff)


class MaqamBtn
    constructor: (parent, @maqam) -> # TODO shortcuts?
        @el = jdiv()
        @el.addClass("maqam_btn")
        @el.html(disp_name @maqam)
        @el.click(@on_click)
        parent.append(@el)
    on_click: =>
        evt.trigger(this, "clicked", this)
    click: => # to be called by parent or other manager
        @el.addClass("active")
    unclick: => # ditto
        @el.removeClass("active")


class MaqamList
    constructor: (parent, maqam_list, default_active_name="") ->
        @el = jdiv()
        @el.addClass("maqam_list")
        parent.append @el
        @maqam_btns = []
        for maqam in maqam_list
            btn = new MaqamBtn @el, maqam
            evt.bind(btn, "clicked", @on_btn_clicked)
            @maqam_btns.push btn
            if maqam.name == default_active_name
                @activate_btn(btn)
        if not @active?
            @activate_btn @maqam_btns[0] # in case no default provided
        @el.find(".maqam_btn:last").addClass("last")
    activate_btn: (btn) =>
        @active?.unclick()
        @active = btn
        @active.click()
        set_active_maqam(@active.maqam)
    on_btn_clicked: (btn) =>
        @activate_btn(btn)


# $ init_maqams

