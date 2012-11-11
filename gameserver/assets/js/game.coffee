g_resources = [
	name: "area03_level_tiles"
	type: "image"
	src: "/images/area03_level_tiles.png"
,
	name: "metatiles32x32"
	type: "image"
	src: "/images/metatiles32x32.png"
,
	name: "sample"
	type: "tmx"
	src: "/data/sample.tmx"
,
	name: "bear"
	type: "image"
	src: "/images/bear.png"
]

game =
	onload: ->
		if !me.video.init 'game-canvas', 640, 480, true, 'auto', true
			alert "Canvas not supported on your browser"
			return

		me.loader.onload = @loaded.bind this

		me.loader.preload g_resources

		me.state.change me.state.LOADING

	loaded: ->
		me.state.set me.state.PLAY, new PlayScreen()

		me.entityPool.add 'localPlayer', LocalPlayerEntity

		me.input.bindKey me.input.KEY.A, 'left'
		me.input.bindKey me.input.KEY.D, 'right'
		me.input.bindKey me.input.KEY.W, 'jump', true

		me.debug.renderHitBox = true

		# start listening for positions
		socket.on 'position_changed', (data) ->
			players[data.id] = data

		socket.on 'player_joined', (data) ->
			console.log "New player: #{data.id}"
			newPlayer = new PlayerEntity data.pos.x, data.pos.y
			newPlayer.GUID = data.id
			me.game.add newPlayer, 4
			me.game.sort()

		me.state.change me.state.PLAY

PlayScreen = me.ScreenObject.extend(
	onResetEvent: ->
		me.levelDirector.loadLevel "sample"

	onDestroyEvent: ->
		alert "Test"
)

# load the game
window.onReady () ->
	window.id = Math.floor ((Math.random() * 1000) + 1)

	window.socket = io.connect()

	socket.on 'player_list', (data) ->
		window.players = data
		console.log data

	game.onload()

PlayerEntity = me.ObjectEntity.extend(
	init: (x, y, settings) ->
		@parent x, y, {image: 'bear', spritewidth: 48}
		@setVelocity 3, 15
		@updateColRect -1, 48, 20, 70
		@collidable = true
		@name = 'remotePlayer'

	update: ->
		player = players[@GUID]
		# console.log "Updating pos for #{player.id}"
		@pos = new me.Vector2d(player.pos.x, player.pos.y)
		@vel = player.vel

		@updateMovement()
		if @vel.x != 0 || @vel.y != 0
			@parent this
			return true

		return false
)


LocalPlayerEntity = me.ObjectEntity.extend(
	init: (x, y, settings) ->
		@parent x, y, {image: 'bear', spritewidth: 48}
		@setVelocity 3, 15
		@updateColRect -1, 48, 20, 70
		@name = 'bear'

		@GUID = window.id

		socket.emit 'player_joining', (
			id: @GUID
			pos: @pos
			vel: @vel
			)
		me.game.viewport.follow @pos, me.game.viewport.AXIS.BOTH
		setInterval (=>

			), 3000

		console.log "GUID: #{@GUID}"

	update: ->
		# horizontal movement
		if me.input.isKeyPressed 'left'
			@flipX true
			@vel.x -= @accel.x * me.timer.tick
		else if me.input.isKeyPressed 'right'
			@flipX false
			@vel.x += @accel.x * me.timer.tick
		else
			this.vel.x = 0

		# jump
		if me.input.isKeyPressed('jump')
			if not @jumping and not @falling
				@vel.y -= @maxVel.y * me.timer.tick
				@jumping = true

		# update movement & animate
		@updateMovement()
		if @vel.x != 0 || @vel.y != 0
			@parent this
			socket.emit 'position_changing',
				id: window.id
				pos: @pos
				vel: @vel
			return true

		return false
)