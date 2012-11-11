mongoose = require 'mongoose'
schema = mongoose.Schema(
	name: { type: String, index: {unique: true} },
	location: { type: String, index: {unique: true} },
	users:[String],
	info:{
		capacity:{ type: Number, min: 2, max: 8 },
		count:{ type: Number, min: 0, max: 8 }
	},
	alive:  Boolean
)

module.exports = mongoose.model("Room", schema)