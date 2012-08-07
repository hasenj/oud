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
    "saba": "6 7 5"
    "kurd": "4 9 9"
    "huzam": "7 9 4"
    "jiharkah": "9 8 5"
    "zamzama": "4 9 5"
    "ushaq": "9 3 10"


# helper function for note generators
gen_tones = (start, distances) ->
    res = [start]
    for displacement in distances
        res.push(u.last(res) + displacement)
    stabilize = (num) -> Number num.toFixed(2)
    u.map(res, stabilize)

FIFTH = 31
OCTAVE = 53

ajnas = {}
for key, val of ajnas_defs
    ajnas[key] = (Number n for n in val.split(" "))

# The `ajnas` dict maps jins name to a list representation of the tetrachord

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
    "saba": "9 saba zamzama"
    "jiharkah": "9 jiharkah jiharkah"
    "ushaq": "9 ushaq bayati"

maqamat = []
for name, def of maqam_defs
    parts = def.split(" ")
    start = Number parts.shift()
    jins1 = ajnas[parts.shift()]
    jins2 = ajnas[parts.shift()]
    maqamat.push maqam_ctor(name, start, jins1, jins2)

# Generic function that generates the notes for a maqam on a given octave
# octave_index is how many octaves higher/lower than the maqam's starting point
# e.g if maqam starts on 1, and octave_index is -1, then generate starting from -5
# if octave_index is 0, generate from 1
# if octave_index is 1, generate from 7
# and so on
# This is the function that works on most maqams (except for saba)
#
# @returns a list of segments indexed from -1 to 2
# segment 0 is the start of the maqam 
# segment -1 is the previous segment
# segment 1 is the second part of the maqam
# and so on ..
# this is all just for this one octave
# naturally, segment -1 is the trailing part of the previous octave
# segment 2 is the starting part of the next octave
generate_maqam_notes_generic = (maqam, octave_index) ->
    start = maqam.start - OCTAVE * octave_index
    seg_info = {
        '-1':
            start: start - OCTAVE + FIFTH
            dists: maqam.jins2
        '0':
            start: start
            dists: maqam.jins1
        '1':
            start: start + FIFTH
            dists: maqam.jins2
        '2':
            start: start + OCTAVE
            dists: maqam.jins1
        }
    segments = {}
    for key, val of seg_info
        segments[key] = gen_tones(val.start, val.dists)
    return segments

# special generator for saba
generate_saba_notes = (maqam, octave_index) ->
    start = maqam.start - OCTAVE * octave_index
    seg_info = {
        '-1':
            start: start - OCTAVE + FIFTH
            dists: ajnas['kurd']
        '0':
            start: start
            dists: maqam.jins1
        '1':
            start: start + FIFTH
            dists: maqam.jins2
        '2':
            start: start + FIFTH + FIFTH
            dists: ajnas['hijaz']
        }
    segments = {}
    for key, val of seg_info
        segments[key] = gen_tones(val.start, val.dists)
    return segments

for maqam in maqamat
    do (maqam) ->
        maqam.gen_fn = (octave_index) -> generate_maqam_notes_generic(maqam, octave_index)
        if maqam.name == 'saba' 
            maqam.gen_fn = (octave_index) -> generate_saba_notes(maqam, octave_index)

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
        "ushaq": "عشاق"
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


$ init_maqams

make_div_floating = (div, topvalue, float_top_value) ->
    $(window).on('scroll', ->
        console.log("we're scrolling!")
        if $(window).scrollTop() > topvalue - float_top_value
            div.css({position: "fixed", top: float_top_value})
        else
            div.css({position: "absolute", top: topvalue})
    )

$ ->
    make_div_floating($(".maqam_list"), 150, 40)
