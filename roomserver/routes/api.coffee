mongoose = require 'mongoose'
Room = require('../models').Room

exports.new = (req, res) ->
	format = req.params.format
	if format is 'json' or not format?
		console.log 'new server has registered'
		room = new Room(req.body)
		room.save (err) ->
  			if err then res.json {status: 'NOK', err:err} 
  			else res.json {status:'OK', room:room}
	else
		res.json {status:'Invalid Format'}

exports.list = (req, res) ->
	format = req.params.format
	if format is 'json' or not format?
		console.log 'server list requested'
		Room.find {}, (err,rooms) ->
			if err then res.json {status: 'NOK', err:err} 
			else res.json {status:'OK', rooms:rooms}
	else
		res.json {status:'Invalid Format'}