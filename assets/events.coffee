# table[obj][event_name] = [list, of, callback, handlers, listeners]
table = {}

check = (obj, evtname) ->
    if not obj of table
        table[obj] = {}
    if not evtname of table[obj]
        table[obj][evtname] = []

defer = (fn) ->
    setTimeout(fn, 0)

bind = (obj, evtname, callback) ->
    check obj, evtname
    table[obj][evtname] += callback

trigger = (obj, evtname, args...) ->
    check obj, evtname
    defer ->
        for callback in table[obj][evtname]
            callback args...

window.evt = {bind, trigger}
