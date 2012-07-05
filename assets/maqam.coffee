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
    "ajam": "1 1 0.5"
    "rast": "1 0.75 0.75"
    "nhwnd": "1 0.5 1"
    "nawather": "1 0.5 1"
    "bayati": "0.75 0.75 1"
    "hijaz": "0.5 1.5 0.5"
    "saba": "0.75 0.75 0.5"
    "kurd": "0.5 1 1"
    "siga": "0.75 1 1"
    "iraq": "0.75 1 0.75"
    "huzam": "0.75 1 0.5"
    "zamzama": "0.5 1 0.5"

ajnas = {}
for key, val of ajnas_defs
    ajnas[key] = (Number n for n in val.split(" "))

# The `ajnas` dict maps jins name to a list representation of the tetrachord

# a maqam def is starting point and 2 jins
maqam_defs =
    "ajam": "0 ajam ajam"
    "kurd": "1 kurd kurd"
    "nhwnd": "0 nhwnd hijaz"
    "hijaz": "1 hijaz kurd"
    "saba": "1 saba zamzama"

maqamat = []
for name, def of maqam_defs
    parts = def.split(" ")
    start = Number parts.shift()
    jins1 = ajnas[parts.shift()]
    jins2 = ajnas[parts.shift()]
    maqamat.push maqam_ctor(name, start, jins1, jins2)


presets = [
        ["ajam", "0", "1 1 0.5 1 1 1 0.5"]
        ["kurd", "1", "0.5 1 1 1 0.5 1 1"] # same as ajam, but keep it
        ["nhwnd", "0", "1 0.5 1 1 0.5 1.5 0.5"]
        # ["nhwnd2", "0", "1 0.5 1 1 0.5 1 1"] # also same as ajam
        ["hijaz", "1", "0.6 1.3 0.6 1 0.5 1 1"]
        #["hijaz2", "1", "0.5 1.5 0.5 1 0.75 0.75 1"]
        ["rast", "0", "1 0.75 0.75 1 1 0.75 0.75"]
        # ["rast2", "0", "1 0.75 0.75 1 1 0.5 1"]
        ["saba", "1", "0.75 0.75 0.5 1.5 0.5 1 1"] 
        # ["saba2", "1", "0.75 0.75 0.5 1.5 0.5 1 0.5"] # TODO seems to work, but should check with professionals
        #["bayati", "1", "0.75 0.75 1 1 0.5 1 1"] # same as rast1
        #["siga" , "1.75", "0.75 1 1 0.75 0.75 1 0.75", "0.75 1 1 0.5 1 1 0.75"] # same as rast?
        #["huzam", "1.75", "0.75 1 0.5 1.5 0.5 1 0.75"] # same as hijaz form 2
        #["jharga", "-2", "1 1 0.5 1 1 0.75 0.75"] # same as bayati, hence rast
        #["hijaz_kar", "0", "0.5 1.5 0.5 1 0.5 1.5 0.5"]
        #["nwathr", "0", "1 0.5 1.5 0.5 0.5 1.5 0.5"]
        # ["user1", $.cookie("user1-start") ? "1",$.cookie("user1-scale") ? "0.5 1.5 0.5 1 0.75 0.75 1"]
        # ["user2", $.cookie("user2-start") ? "1",$.cookie("user2-scale") ? "0.75 0.75 1 1 0.5 1 1"]
        # ["user3", $.cookie("user3-start") ? "-2",$.cookie("user3-scale") ? "1 1 0.5 1 1 0.75 0.75"]
        # ["user4", $.cookie("user4-start") ? "0",$.cookie("user4-scale") ? "0.5 1.5 0.5 1 0.5 1.5 0.5"]
        # ["user5", $.cookie("user5-start") ? "1",$.cookie("user5-scale") ? "0.75 0.75 1 1 0.5 1 1"]
        # ["user6", $.cookie("user6-start") ? "1",$.cookie("user6-scale") ? "0.75 0.75 1 1 0.5 1 1"]
]

disp_name = (maqam) ->
    map = {
        "ajam" : "عجم",
        "kurd": "كرد",
        "nhwnd": "نهاوند",
        "hijaz": "حجاز",
        "rast": "راست",
        "siga" : "سيكاه",
        "bayati" : "بياتي",
        "saba" : "صبا"
    }
    if maqam.name of map
        map[maqam.name]
    else
        maqam.name

if not window.updkeys?
    window.updkeys = ->

set_active_maqam = (maqam) ->
    window.active_maqam = maqam # XXX not a clone, ok?
    # scale_widget.set_val(maqam.scale)
    # start_widget.set_val(maqam.start)
    $("#maqam_name").html("مقام ال" + disp_name maqam)
    $.cookie('maqam', maqam.name)
    updkeys maqam

# closely coupled with set_active_maqam
# XXX overlapping responsibilities
on_user_change_scale = ->
    active_maqam.scale = scale_widget.get_val() # this actually changes the scale for the active maqam directly!
    active_maqam.start = start_widget.get_val()
    if active_maqam.name.match(/^user\d/)
        $.cookie(active_maqam.name + "-start", active_maqam.start)
        $.cookie(active_maqam.name + "-scale", active_maqam.scale.join(" "))
    updkeys active_maqam

init_maqams = ->
    default_maqam = $.cookie('maqam') ? 'ajam'
    ctrls = $("#maqam_ctrls")
    window.scale_widget = new ScaleWidget ctrls, [1,1,0.5,1,1,1,0.5]
    window.start_widget = new StartWidget ctrls, 0
    window.maqam_list = new MaqamList ctrls, maqamat, default_maqam

    evt.bind(scale_widget, "changed", on_user_change_scale)
    evt.bind(start_widget, "changed", on_user_change_scale)

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
    activate_btn: (btn) =>
        @active?.unclick()
        @active = btn
        @active.click()
        set_active_maqam(@active.maqam)
    on_btn_clicked: (btn) =>
        @activate_btn(btn)


$ init_maqams
