require "./config"
x = require "express"
app = x.createServer()
app.listen(9040)
app.use x.bodyParser()
app.use(x.static(__dirname + "/public"))
app.use(require('connect-assets')(src:__dirname+'/assets'))

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

mail = require('mail').Mail host: process.env.SMTP_HOST, username: process.env.SMTP_LOGIN
# async/ajax
app.post '/feedback', (req, res) ->
    mail.message({from: req.param("email") or process.env.EMAIL, to: process.env.EMAIL, subject: 'oud feedback from ' + req.param('name') or  '<user>'}).body(req.param('feedback')).send( (err) ->
        if (err)
            res.send({success: false, err:err})
        else
            res.send({success: true})
    )


