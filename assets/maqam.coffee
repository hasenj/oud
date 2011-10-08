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

# $ init_maqams
