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
    {name, start, scale, alt_scale}

presets = [
        ["ajam", "0", "1 1 0.5 1 1 1 0.5"]
        ["kurd", "1", "0.5 1 1 1 0.5 1 1"] # same as ajam, but keep it
        ["nahawand", "0", "1 0.5 1 1 0.5 1.5 0.5", "1 0.5 1 1 0.5 1 1"]
        ["hijaz", "1", "0.5 1.5 0.5 1 0.5 1 1",  "0.5 1.5 0.5 1 0.75 0.75 1"]
        ["rast", "0", "1 0.75 0.75 1 1 0.75 0.75", "1 0.75 0.75 1 1 0.5 1"]
        ["saba", "1", "0.75 0.75 0.5 1.5 0.5 1 1", "0.75 0.75 0.5 1.5 0.5 1 0.5"] # TODO check that it works!
        ["bayati", "1", "0.75 0.75 1 1 0.5 1 1"] # same as rast1
        #["siga" , "1.75", "0.75 1 1 0.75 0.75 1 0.75", "0.75 1 1 0.5 1 1 0.75"] # same as rast?
        #["huzam", "1.75", "0.75 1 0.5 1.5 0.5 1 0.75"] # same as hijaz form 2
        #["jiharkah", "-2", "1 1 0.5 1 1 0.75 0.75"] # same as bayati, hence rast
        ["hijaz_kar", "0", "0.5 1.5 0.5 1 0.5 1.5 0.5"]
        ["nawa_athar", "0", "1 0.5 1.5 0.5 0.5 1.5 0.5"]
]

maqamat = []
for preset in presets
    name = preset.shift()
    start = Number preset.shift()
    scale = preset.shift().split(" ")
    scale_alt = if preset.length then preset.shift().split(" ") else null
    maqamat.push maqam_ctor(name, start, scale, scale_alt)

# From: http://www.mediacollege.com/internet/javascript/text/case-capitalize.html
String.prototype.capitalize = ->
   @replace /(^|\s)([a-z])/g , (m,p1,p2) -> p1+p2.toUpperCase()

disp_name = (maqam_code) ->
    maqam_code.replace("_", " ").capitalize()

if not window.updkeys?
    window.updkeys = ->

on_choose_maqam = (maqam) ->
    $("#start").val(maqam.start)
    $("#scale").val(maqam.scale)
    $("#maqam_name").html("Maqam " + disp_name name)
    $.cookie('maqam', name)
    maqam = 
        start: start
        scale: parse_scale scale
    updkeys maqam

window.apply_user_maqam = -> # applies custom maqam ..
    maqam =
        start: Number $("#start").val()
        scale: parse_scale $("#scale").val()
    updkeys maqam

# scratch this off ...
init_maqams = ->
    p = $("#presets")
    maqam_btns = {}
    window.choose_maqam = (name) ->
        b = maqam_btns[name]
        $(".active", p).removeClass("active")
        b.addClass("active")
        on_choose_maqam name
        return b
    # building preset list
    shkeys = "1234567890asdfghjvbnm"
    for name, index in _.keys maqam_presets
        disp = disp_name name
        do(name) ->
            clickfn = (e)-> 
                e.preventDefault()
                choose_maqam name
            option = $("<div>").addClass("option").html(disp_name name)
            if shkey = shkeys[index]
                shortcut = 'ctrl+' + shkey
                option.append $("<div>").addClass("shortcut").html('ctrl-' + shkey)
                $(document).bind 'keydown', shortcut, clickfn
            option.click(clickfn)
            p.append(option)
            maqam_btns[name] = option
    # remember last chosen maqam
    m = $.cookie('maqam') 
    if not m or m not of maqam_presets
        m = 'ajam'
    choose_maqam m 

jdiv = -> $("<div/>")

class StepperWidget
    constructor: (parent, @value=0, @step=0.25, @orientation='vertical') ->
        @el = jdiv()
        parent.append(@el)
        @render_ui()
        evt.bind(this, "changed", @update_ui)
    _inc: (amt) =>
        @value += amt
        evt.trigger(this, "changed", @value)
    inc: => @_inc(@step)
    dec: => @_inc(-@step)
    get_val: => @value
    render_ui: ->
        orn = @orientation
        first = 'inc'
        second = 'dec'
        first_sym = '&#9650;'
        second_sym = '&#9660;'
        if orn == 'horizontal'
            [first,second] = [second, first]
            first_sym = '&#0017;'
            second_sym = '&#0016;'
        @el.addClass("widget_stepper")
        @el.addClass(@orientation)
        @el.html("
            <div class='button #{first}'> #{first_sym} </div>
            <div class='val'> #{@value} </div>
            <div class='button #{second}'> #{second_sym} </div>"
        )
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
            evt.bind(s, "changed", @on_change)
        @vis = new ScaleGraph @el
        @render_ui()
    get_val: =>
        (s.get_val() for s in @steppers)
    render_ui: =>
        # steppers will auto-render 
        @update_ui() # render the scale display
    on_change: =>
        @update_ui()
    update_ui: =>
        scale = @get_val()
        @vis.draw_scale(scale)
        
        


$ -> 
    tw = new ScaleWidget $("#test_mv"), [1,1,0.5,1,1,1,0.5]

# $ init_maqams
