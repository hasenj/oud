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
nib = require "nib"
app.get("/css", (req, res) ->
    fs.readFile(__dirname + "/css/index.styl", (err, data) ->
        src = String(data)
        s(src).use(nib()).render(
            (err, css) ->
                if err
                    console.log "stylus rendering error:"
                    console.log err
                res.send(css, {'Content-Type': 'text/css'})
            )

    ))

# let .coffee files be served as text
mime = require "mime"
mime.define({'text/coffeescript' : ['coffee']})
