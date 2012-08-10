process.chdir(__dirname)
x = require "express"
app = x()
app.listen(9040)
app.use x.bodyParser()
app.use(x.static(__dirname + "/public"))
app.use(require('connect-assets')())

app.set 'views', __dirname # same directory!!
app.set 'view engine', 'jade'

app.get('/', (req, res) ->
    res.render("index")
)

