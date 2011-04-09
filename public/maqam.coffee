####
# maqam presets

maqam_presets = 
    ajam: ["0", "1 1 0.5 1 1 1 0.5", "0"]
    kurd: ["1", "0.5 1 1 1 0.5 1 1"]
    hijaz_kar_kurd: ["0", "0.5 1.5 0.5 1 0.5 1.5 0.5"]
    hijaz1: ["1", "0.5 1.5 0.5 1 0.75 0.75 1"]
    hijaz2: ["1", "0.5 1.5 0.5 1 0.5 1 1"]
    nahawand: ["0", "1 0.5 1 1 0.5 1.5 0.5"]
    rast1: ["0", "1 0.75 0.75 1 1 0.75 0.75"]
    rast2: ["0", "1 0.75 0.75 1 1 0.5 1"]
    rast_comb: ["0", "1 0.75 0.75 1 1 0.5 0.25 0.75"]
    bayati: ["1", "0.75 0.75 1 1 0.5 1 1"]
    husseini: ["1", "0.75 0.75 1 1 0.75 0.75 1"]
    jiharkah: ["4", "1 1 0.5 1 1 0.75 0.75"]
    saba1: ["1", "0.75 0.75 0.5 1.5 0.5 1 1"]
    saba2: ["1", "0.75 0.75 0.5 1.5 0.5 1 0.5 1.5 0.5 0.75 1"]
    sikah1: ["1.25", "0.75 1 1 0.75 0.75 1 0.75"]
    sikah2: ["1.25", "0.75 1 1 0.5 1 1 0.75"]
    huzam: ["1.25", "0.75 1 0.5 1.5 0.5 1 0.75"]
    rahatelarwah: ["5.25", "0.75 1 0.5 1.5 0.5 1 0.75"]
    iraq: ["5.25", "0.75 1 0.75 0.75 1 1 0.75"]
    nawa_athar: ["0", "1 0.5 1.5 0.5 0.5 1.5 0.5"]

on_choose_maqam = () ->
    name = @value
    [start, scale] = maqam_presets[name]
    $("#start").val(start)
    $("#scale").val(scale)
    $.cookie('maqam', name)
    updkeys()

init_maqams = () ->
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
