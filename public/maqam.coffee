####
# maqam presets

# maqam/scale language: extra keys are marked with +
#   The scale is defined as a sequency of tones
#   each tone is defined by its distance from the previous tone
#   there are "extra" tones
#   extra tones are like black keys on the piano
#   more precisely, they are alternative versions of a certain tone.
#   extra tones are imposed on other tones in the sense
#   they are defined by: which tone they're imposed on, and how different
#   are they from that tone. The value could be negative
#   extra tones are denoted by either a [ or a ] before the tone
#   [ means it's imposed on the previous tone
#   ] means it's imposed on the next tone
#   for example, ]-0.5 means imposed on next tone and is half a tone lower than it
#   we assume a maqam takes exactly 7 elements (not counting imposition)
#   Note: I don't yet have a specific plan on handling special maqams 
#       but saba should be fine with just imposition
#   note names are detected automatically; or rather:
#   the first note is detected automatically
#   the following notes just assume the sequence
maqam_presets = 
    ajam: ["-0.75", "1 1 0.5 1 1 1 0.5"]
    kurd: ["1", "0.5 1 1 1 0.5 1 ]-0.5 1"] # the -0.5 here is a cheat for rafat il hajjan!!
    nahawand: ["0", "1 0.5 1 1 0.5 ]-0.5 1.5 0.5"]
    c_major: ["0", "1 1 0.5 1 1 1 0.5"]
    hijaz_kar: ["0", "0.5 1.5 0.5 1 0.5 1.5 0.5"]
    hijaz: ["1", "0.5 1.5 0.5 1 ]+0.25 0.5 1 1"]
    rast: ["0", "1 0.75 0.75 1 1 ]-0.25 0.75 0.75"]
    bayati: ["1", "0.75 0.75 1 1 0.5 1 1"]
    husseini: ["1", "0.75 0.75 1 1 0.75 0.75 1"]
    jiharkah: ["4", "1 1 0.5 1 1 0.75 0.75"]
    saba: ["1", "0.75 0.75 0.5 1.5 0.5 1 ]-0.5 1"] # not sure what's the proper solution here
    # saba2: ["1", "0.75 0.75 0.5 1.5 0.5 1 0.5 1.5 0.5"]
    sikah:  ["1.25", "0.75 1 1 ]-0.25 0.75 0.75 1 0.75"]
    # sikah1: ["1.25", "0.75 1 1 0.75 0.75 1 0.75"]
    # sikah2: ["1.25", "0.75 1 1 0.5 1 1 0.75"]
    huzam: ["1.25", "0.75 1 0.5 1.5 0.5 1 0.75"]
    rahatelarwah: ["5.25", "0.75 1 0.5 1.5 0.5 1 0.75"]
    iraq: ["5.25", "0.75 1 0.75 0.75 1 1 0.75"]
    nawa_athar: ["0", "1 0.5 1.5 0.5 0.5 1.5 0.5"]

window.parse_scale = (scale_str) ->
    # match [ ] and number tokens
    toks = scale_str.match(/(\]|\[|(-?[\d.]+))/g) 
    tonekey = (dist) -> { dist1: dist, dist2: 0 }
    scale = []
    sc_at = (index) ->
        if index < 0
            console.log "WARNING! bad scale"
            return tonekey(0) # dummy object, punishment for being stupid
        while index >= scale.length
            scale.push tonekey(0)
        return scale[index]
    index = 0
    while toks.length > 0
        t = toks.shift()
        if t == '['
            sc_at(index - 1).dist2 = Number toks.shift()
        else if t == ']'
            # not index+1 .. index already points to the "next" point
            sc_at(index).dist2 = Number toks.shift()
        else
            sc_at(index).dist1 = Number t
            index++
    return scale

# From: http://www.mediacollege.com/internet/javascript/text/case-capitalize.html
String.prototype.capitalize = ->
   @replace /(^|\s)([a-z])/g , (m,p1,p2) -> p1+p2.toUpperCase()

disp_name = (maqam_code) ->
    maqam_code.replace("_", " ").capitalize()

on_choose_maqam = (name) ->
    [start, scale] = maqam_presets[name]
    $("#start").val(start)
    $("#scale").val(scale)
    $("#maqam_name").html("Maqam " + disp_name name)
    $.cookie('maqam', name)
    updkeys()

init_maqams = ->
    console.log 1
    p = $("#presets")
    maqam_btns = {}
    window.choose_maqam = (name) ->
        b = maqam_btns[name]
        console.log b
        $(".selected_option", p).removeClass("selected_option")
        b.addClass("selected_option")
        on_choose_maqam name
        return b
    # building preset list
    shkeys = "1234567890tyuiofghvbnm"
    for name, index in _.keys maqam_presets
        console.log name
        disp = disp_name name
        shortcut = 'ctrl+' + shkeys[index]
        # -> -> is necessary trickery for js closures inside loops!
        clickfn = ((name)-> -> choose_maqam name) name
        option = $("<div>").addClass("option").html(disp_name name)
        option.append $("<div>").addClass("shortcut").html(shortcut)
        option.click(clickfn)
        p.append(option)
        maqam_btns[name] = option
        $(document).bind 'keydown', shortcut, clickfn
    # remember last chosen maqam
    m = $.cookie('maqam') or 'c_major' 
    choose_maqam m # TEST THIS WORKS!!!

$ init_maqams
