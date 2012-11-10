###
Module dependencies.
###

express = require("express")
routes = require("./routes")
user = require("./routes/user")
http = require("http")
path = require("path")
app = express()
app.configure ->
  app.set "port", process.env.PORT or 3000
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.favicon()
  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser("your secret here")
  app.use express.session()
  app.use app.router
  app.use require('connect-assets')()
  app.use express["static"](path.join(__dirname, "public"))

app.configure "development", ->
  app.use express.errorHandler()

app.get "/", routes.index
app.get "/users", user.list
server = http.createServer(app).listen(app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")
)
io = require("socket.io").listen(server)

#Socket.io emits this event when a connection is made.
io.sockets.on "connection", (socket) ->
  
  # Emit a message to send it to the client.
  socket.emit "ping",
    msg: "Hello. I know socket.io."

  
  # Print messages from the client.
  socket.on "pong", (data) ->
    console.log data.msg