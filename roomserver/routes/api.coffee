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
	Room.find {}, (err,rooms) ->
		console.log 'server list requested'
		if format is 'json'
				if err then res.json {status: 'NOK', err:err} 
				else res.json {status:'OK', rooms:rooms}
		else
			res.render "index", { title: "Animal Chaos Rooms", rooms: rooms }

exports.info = (req, res) ->
	format = req.params.format
	id = req.params.id
	Room.findOne {_id:id}, (err,room) ->
		console.log 'room info requested'
		if format is 'json'
				if err then res.json {status: 'NOK', err:err} 
				else res.json {status:'OK', room:room}
		else
			res.render "show", { title: room.name, room: room }