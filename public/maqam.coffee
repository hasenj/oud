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
    nahawand: ["0", "1 0.5 1 1 0.5 1.5 0.5"]
    c_major: ["0", "1 1 0.5 1 1 1 0.5"]
    hijaz_kar_kurd: ["0", "0.5 1.5 0.5 1 0.5 1.5 0.5"]
    hijaz: ["1", "0.5 1.5 0.5 1 ]-0.25 0.75 0.75 1"]
    rast: ["0", "1 0.75 0.75 1 1 ]-0.25 0.75 0.75"]
    bayati: ["1", "0.75 0.75 1 1 0.5 1 1"]
    husseini: ["1", "0.75 0.75 1 1 0.75 0.75 1"]
    jiharkah: ["4", "1 1 0.5 1 1 0.75 0.75"]
    saba: ["1", "0.75 0.75 0.5 1.5 0.5 1 ]-0.5 1"] # not sure what's the proper solution here
    # saba2: ["1", "0.75 0.75 0.5 1.5 0.5 1 0.5 1.5 0.5"]
    sikah:  ["1.25", "0.75 1 1 ]-0.5 0.75 0.75 1 0.75"]
    # sikah1: ["1.25", "0.75 1 1 0.75 0.75 1 0.75"]
    # sikah2: ["1.25", "0.75 1 1 0.5 1 1 0.75"]
    huzam: ["1.25", "0.75 1 0.5 1.5 0.5 1 0.75"]
    rahatelarwah: ["5.25", "0.75 1 0.5 1.5 0.5 1 0.75"]
    iraq: ["5.25", "0.75 1 0.75 0.75 1 1 0.75"]
    nawa_athar: ["0", "1 0.5 1.5 0.5 0.5 1.5 0.5"]

window.parse_scale = (scale_str) ->
    scale = scale_str.match(/[\d.]+/g) # this sorta works like .split
    scale = _.map(scale, Number)


on_choose_maqam = ->
    name = @value
    [start, scale] = maqam_presets[name]
    $("#start").val(start)
    $("#scale").val(scale)
    $.cookie('maqam', name)
    updkeys()

init_maqams = ->
    # building preset list
    p = $("#presets")
    for name of maqam_presets
        option = $("<option>").html(name).attr("val", name)
        p.append(option)
    p.change(on_choose_maqam)
    # remember last chosen maqam
    m = $.cookie('maqam') or p.val()
    p.val(m)

$ init_maqams
