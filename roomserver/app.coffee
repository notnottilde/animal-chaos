###
Module dependencies.
###

express  = require 'express'
routes   = require './routes'
http     = require 'http'
path     = require 'path'
stylus   = require 'stylus'
mongoose = require 'mongoose'

mongoose.connect "mongodb://ac-user:get$getpaid@alex.mongohq.com:10081/animal-chaos-db", ->
  console.log 'Animal-Chaos room server connected to mongo successfully'


# Bootstrap Models
require './models'

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
app.post "/rooms/new.:format?", routes.api.new
app.get "/rooms/list.:format?", routes.api.list

server = http.createServer(app).listen(app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")
)