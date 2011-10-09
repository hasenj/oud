# table[obj][event_name] = [list, of, callback, handlers, listeners]
table = {}

check = (obj, evtname) ->
    if not obj.id?
        obj.id = _.uniqueId("obj")
    id = obj.id
    if id not of table
        table[id] = {}
    if evtname not of table[id]
        table[id][evtname] = []

defer = (fn) ->
    setTimeout(fn, 0)

bind = (obj, evtname, callback) ->
    check obj, evtname
    table[obj.id][evtname].push callback

trigger = (obj, evtname, args...) ->
    check obj, evtname
    defer ->
        for callback in table[obj.id][evtname]
            callback args...

window.evt = {bind, trigger}
