x = require "express"
app = x.createServer()
app.listen(9040)
app.use(x.static(__dirname + "/public"))
app.use(require('connect-assets')())

app.set 'views', __dirname # same directory!!
app.set 'view engine', 'jade'

app.get('/', (req, res) ->
    res.render("index")
)

