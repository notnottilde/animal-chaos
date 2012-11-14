# store an array of players
players = []

# add a player to the array
players.add = (p, cb) ->
	players.push p
	cb? players

# update data for a player
players.update = (p, cb) ->
	index = indexOf player for player in players when player.id is id
	if index?
		players[index] = p
	cb? players

# remove a player by id from the array
players.remove = (id, cb) ->
	index = indexOf player for player in players when player.id is id
	if index?
		players.splice index, 1
	cb? players

# get the current list of players
module.exports = players