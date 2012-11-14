events = require 'events'
randy = require 'randy'
players = require './players'

class God
  constructor: ->
    console.log 'constructing god class'
    @timer = null
    @authority = {}

  @:: = new events.EventEmitter

  # chose a new player to act as the authority
  choose: =>
    index = 0
    if players.length > 1
      index = randy.randInt players.length

    console.log 'choose a new god at index '+index
    authority = players[index]
    @emit 'chosen', authority

  # start the god
  start: ->
    console.log 'starting the god'
    if not timer?
      timer = setInterval @choose, 1000

  # stop the god
  stop: ->
    console.log 'stopping the god'
    clearInterval(timer)
    timer = null

God.instance = null

God.getInstance = ->
  if not @instance?
    @instance = new God();
  return @instance

module.exports = God.getInstance()