x = require "express"
app = x.createServer()
app.listen(9040)
app.use(x.static(__dirname + "/public"))

app.set 'views', __dirname # same directory!!
app.set 'view engine', 'jade'

app.get('/', (req, res) ->
    res.render("index")
)

s = require "stylus"
fs = require "fs"
app.get("/css", (req, res) ->
    fs.readFile(__dirname + "/public/css.styl", (err, data) ->
        src = String(data)
        s.render(src, (err, css) ->
            res.send(css, {'Content-Type': 'text/css'}))
    ))

# let .coffee files be served as text
mime = require "mime"
mime.define({'text/coffeescript' : ['coffee']})
