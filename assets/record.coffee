# assumes there's such a thing as a recording object
recordings = []

add_recording = (rec) -> recordings.push rec

play_recording = (rec) ->
    # to be figured out when we decide how we store recordings ..

window.recording = 
    rec: null
    buf: null
    start: -> 
        console.log "recording"
        $.event.trigger('recording_start')
        @rec = dev.record()
    stop: -> 
        console.log "stopped"
        $.event.trigger('recording_stop')
        @rec.stop()
        @buf = @rec.join()
    play: ->
        console.log "playing"
        $.event.trigger('recording_play')
        dev.writeBuffer @buf, 1000 # TEMP HACK
        # should play using a proper audio element that's fed the buffer as though it was a file
    stop_playing: ->
        $.event.trigger('recording_play_stop')
        # todo

keybind = (key, fn) ->
    $(document).bind('keydown', key, (e) ->
        e.preventDefault()
        fn())

keybind 'z', recording.start
keybind 'x', recording.stop
keybind 'c', recording.play
keybind 'v', recording.stop_playing

rec_btn = $("#rec_btn")
play_btn = $("#play_btn")

start_rec_click = ->
    recording.start()
    rec_btn.val("Stop")
    rec_btn.unbind('click')
    rec_btn.click(stop_rec_click)
    play_btn.attr("disabled", "disabled")


stop_rec_click = ->
    recording.stop()
    rec_btn.val("Record")
    rec_btn.unbind('click')
    rec_btn.click(start_rec_click)
    play_btn.removeAttr("disabled", "disabled")

rec_btn.click(start_rec_click)

play_click = ->
    recording.play()
    #TODO

play_btn.click(play_click)
