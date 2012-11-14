###
Module dependencies.
###

express = require 'express'
routes  = require './routes'
http    = require 'http'
path    = require 'path'
stylus  = require 'stylus'
request = require 'request'
config  = require './config'
god     = require './lib/god'
console.log(god)
players = require './lib/players'


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

io.set 'log level', 1

#Socket.io emits this event when a connection is made.
io.sockets.on "connection", (socket) ->
  
  # Emit the current list of players on any new connection
  send_player_list()

  # When a new player joins, add them to the list
  # and notify other connected clients
  socket.on "player_joining", (player) ->
    socket.set "id", player.id
    players.add player, (players) ->
        if players.length is 1
          god.start()
    socket.broadcast.volatile.emit "player_joined", player

  # When a player moves, update the server position
  socket.on "position_changing", (player) ->
    if player.timestamp > players[player.id]?.timestamp
      players.update player
      socket.broadcast.emit 'position_changed', player

  # When a player disconnects, notify the other players
  socket.on "disconnect", ->
    socket.get "id", (err, id) ->
      console.log "Player #{id} left"
      players.remove id, (players) ->
        if players.length is 0
          god.stop()

      socket.broadcast.volatile.emit "player_left", {id: id}

# Socket.io methods
send_player_list = ->
  io.sockets.volatile.emit "player_list", players

# Send Room Server Updates
room_server = config.room_server[app.get('env')]+'/rooms/checkin'
console.log 'sent an update to the room server '+room_server

request.post { uri:room_server, json:config.info }, (e, r, b) ->
  if not e and r.statusCode == 200
    console.log "checkin response #{JSON.stringify(b)}"
  else
    console.log "checkin error #{e}"

god.on 'chosen', (player) ->
  if player?
    console.log "player #{player.id} chosen as new god"
  else
    console.log "no player available to play god"




