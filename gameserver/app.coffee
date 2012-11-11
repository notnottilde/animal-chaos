###
Module dependencies.
###

express = require 'express'
routes  = require './routes'
http    = require 'http'
path    = require 'path'
stylus  = require 'stylus'
request = require 'request'

#request {uri:'http://localhost:4000'}, (error, response, body) ->
# if !error && response.statusCode == 200
    


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
  app.use stylus.middleware({ src: __dirname, compile: compile})
  app.use express["static"](path.join(__dirname, "public"))

compile = (str, path) ->
  return stylus(str)
    .set 'filename', path
    .set 'compress', true
    .use nib()

app.configure "development", ->
  app.use express.errorHandler()

app.get "/", routes.index

server = http.createServer(app).listen(app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")
)
io = require("socket.io").listen(server)

players = {}

io.set 'log level', 1

#Socket.io emits this event when a connection is made.
io.sockets.on "connection", (socket) ->
  
  # Emit the current list of players on any new connection
  send_player_list()

  # When a new player joins, add them to the list
  # and notify other connected clients
  socket.on "player_joining", (player) ->
    socket.set "id", player.id
    players[player.id] = player
    socket.broadcast.volatile.emit "player_joined", player

  # When a player leaves, remove them from the list
  # and notify other connected clients
  socket.on "player_leaving", (player) ->
    delete players[player.id]
    socket.broadcast.volatile.emit "player_left", player

  # When a player moves, update the server position
  socket.on "position_changing", (player) ->
    if player.timestamp > players[player.id]?.timestamp
      players[player.id] = player
      socket.broadcast.emit 'position_changed', player

  socket.on "disconnect", ->
    socket.get "id", (err, id) ->
      console.log "Player #{id} left"
      delete players[id]
      socket.broadcast.volatile.emit "player_left", {id: id}


send_player_list = ->
  io.sockets.volatile.emit "player_list",
      players

