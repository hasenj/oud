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

app.get('/browsers', (req, res) ->
    res.render("browsers")
)

app.get('/about', (req, res) ->
    res.render("about")
)
app.get('/feedback', (req, res) ->
    res.render("feedback")
)
