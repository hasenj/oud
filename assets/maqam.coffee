####
# maqam presets
#   A scale is defined as a sequency of tone distances
#   Some scales have the special property that they don't end in 6 full tones
#   This is handled in keyboard.coffee in a way that works
#
#   A maqam is a scale + a starting point
#
#   Some maqams have "variations", aka alt_scale

maqam_ctor = (name, start, scale, alt_scale=null) ->
    alt_scale ?= scale
    {name, start, scale, alt_scale}

presets = [
        ["ajam", "0", "1 1 0.5 1 1 1 0.5"]
        ["kurd", "1", "0.5 1 1 1 0.5 1 1"] # same as ajam, but keep it
        ["nahawand", "0", "1 0.5 1 1 0.5 1.5 0.5"]
        ["nahawand2", "0", "1 0.5 1 1 0.5 1 1"]
        ["hijaz", "1", "0.5 1.5 0.5 1 0.5 1 1"]
        ["hijaz2", "1", "0.5 1.5 0.5 1 0.75 0.75 1"]
        ["rast", "0", "1 0.75 0.75 1 1 0.75 0.75"]
        ["rast2", "0", "1 0.75 0.75 1 1 0.5 1"]
        ["saba", "1", "0.75 0.75 0.5 1.5 0.5 1 1"] # TODO check that it works!
        ["saba2", "1", "0.75 0.75 0.5 1.5 0.5 1 0.5"] # TODO check that it works!
        #["bayati", "1", "0.75 0.75 1 1 0.5 1 1"] # same as rast1
        #["siga" , "1.75", "0.75 1 1 0.75 0.75 1 0.75", "0.75 1 1 0.5 1 1 0.75"] # same as rast?
        #["huzam", "1.75", "0.75 1 0.5 1.5 0.5 1 0.75"] # same as hijaz form 2
        #["jiharkah", "-2", "1 1 0.5 1 1 0.75 0.75"] # same as bayati, hence rast
        #["hijaz_kar", "0", "0.5 1.5 0.5 1 0.5 1.5 0.5"]
        #["nawa_athar", "0", "1 0.5 1.5 0.5 0.5 1.5 0.5"]
]

maqamat = []
for preset in presets
    preset = _(preset).clone()
    name = preset.shift()
    start = Number preset.shift()
    scale = (Number n for n in preset.shift().split(" "))
    scale_alt = if preset.length then (Number n for n in  preset.shift().split(" ")) else null
    maqamat.push maqam_ctor(name, start, scale, scale_alt)

find_maqam_by_name = (name, def) ->
    alt = null
    for maqam in maqamat
        if maqam.name == name
            return maqam
        if maqam.name == def
            alt = maqam
    return alt # didn't find name, return alternative as default
            

# From: http://www.mediacollege.com/internet/javascript/text/case-capitalize.html
String.prototype.capitalize = ->
   @replace /(^|\s)([a-z])/g , (m,p1,p2) -> p1+p2.toUpperCase()

disp_name = (maqam) ->
    maqam.name.replace("_", " ").capitalize()

if not window.updkeys?
    window.updkeys = ->

on_choose_maqam = (maqam) ->
    window.active_maqam = maqam # XXX not a clone, ok?
    scale_widget.set_val(maqam.scale)
    start_widget.set_val(maqam.start)
    $("#maqam_name").html("Maqam " + disp_name maqam)
    $.cookie('maqam', maqam.name)
    updkeys maqam

# closely coupled with on_choose_maqam
# XXX overlapping responsibilities
on_user_change_scale = ->
    active_maqam.scale = scale_widget.get_val() # this actually changes the scale for the active maqam directly!
    active_maqam.start = start_widget.get_val()
    updkeys active_maqam

# scratch this off ...
init_maqams = ->
    start_maqam = $.cookie('maqam') ? 'ajam'
    ctrls = $("#maqam_ctrls")
    window.scale_widget = new ScaleWidget ctrls, [1,1,0.5,1,1,1,0.5]
    window.start_widget = new StartWidget ctrls, 0
    window.maqam_list = new MaqamList ctrls, maqamat, start_maqam

    evt.bind(scale_widget, "changed", on_user_change_scale)
    evt.bind(start_widget, "changed", on_user_change_scale)

jdiv = -> $("<div/>")
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
        @el = $("<canvas width='300px' height='40px'></canvas>")
        parent.append(@el)
        @canvas = @el.get(0)
        @ctx = @canvas.getContext('2d')
        @bg_color = "hsl(0,0%,80%)"
        @fg_color = "hsl(0,0%,40%)"
    draw_scale: (scale) =>
        @ctx.clearRect(0, 0, @canvas.width, @canvas.height)
        @draw_line(0, 6, @bg_color)
        @draw_point(0, @bg_color)
        @draw_point(6, @bg_color)
        s = 0
        @draw_point(s, @fg_color)
        for p in scale
            s += p
            @draw_point(s, @fg_color)
        @draw_line(0, s, @fg_color)
    draw_point: (dist, color) =>
        @ctx.fillStyle = color
        @ctx.strokeStyle = color
        @ctx.fillRect(@x_coord(dist)-2, 10, 5, 5)
    draw_line: (start, end, color) =>
        @ctx.fillStyle = color
        @ctx.fillRect(@x_coord(start), 12, @x_coord(end) - @x_coord(start), 1)
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
    constructor: (parent, maqam_list, default_active_name) ->
        @el = jdiv()
        parent.append @el
        @maqam_btns = []
        for maqam in maqam_list
            btn = new MaqamBtn @el, maqam
            evt.bind(btn, "clicked", @on_btn_clicked)
            @maqam_btns.push btn
            if maqam.name == default_active_name
                @active = btn
        @active ?= @maqam_btns[0] # in case no cookie? 
        @active.click()
        on_choose_maqam(@active.maqam)
    on_btn_clicked: (btn) =>
        if btn is @active
            return
        @active.unclick()
        btn.click()
        @active = btn
        on_choose_maqam(@active.maqam)


$ init_maqams
