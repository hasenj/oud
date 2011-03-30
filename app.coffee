x = require "express"
app = x.createServer()
app.listen(9040)

app.get('/', (req, res) ->
    res.send("Web Oud")
)
