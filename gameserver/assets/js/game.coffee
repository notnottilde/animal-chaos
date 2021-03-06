g_resources = [
	name: "area03_level_tiles_retina"
	type: "image"
	src: "/images/area03_level_tiles_retina.png"
,
	name: "metatiles32x32"
	type: "image"
	src: "/images/metatiles32x32.png"
,
	name: "sample"
	type: "tmx"
	src: "/data/sample_retina.tmx"
,
	name: "bear-sheet"
	type: "image"
	src: "/images/sprites/bear/aMothaFuckinBearSheet_retina.png"
]

AddPlayer = (player) ->
	if not me.game.getEntityByGUID(id)?
		console.log "New player: #{id}"
		newPlayer = new PlayerEntity pos.x, pos.y
		newPlayer.GUID = id
		me.game.add newPlayer, 4

game =
	onload: ->
		if !me.video.init 'game-canvas', 2048,  1536, true, '1.0', false
			alert "Canvas not supported on your browser"
			return
		me.video.getScreenCanvas().style.width = '1024px'
		me.video.getScreenCanvas().style.height = '768px'


		me.loader.onload = @loaded.bind this

		me.loader.preload g_resources

		me.state.change me.state.LOADING

	loaded: ->
		me.state.set me.state.PLAY, new PlayScreen()

		me.entityPool.add 'localPlayer', LocalPlayerEntity

		me.input.bindKey me.input.KEY.LEFT, 'left'
		me.input.bindKey me.input.KEY.A, 'left'
		me.input.bindKey me.input.KEY.D, 'right'
		me.input.bindKey me.input.KEY.RIGHT, 'right'
		me.input.bindKey me.input.KEY.W, 'jump', true
		me.input.bindKey me.input.KEY.UP, 'jump', true

		me.debug.renderHitBox = true

		window.socket = io.connect()

		socket.on 'player_list', (players) ->
			window.players = players
			for player in players
				do (player) ->
					AddPlayer(player)
			me.game.sort()

		# start listening for positions
		socket.on 'position_changed', (data) ->
			window.players[data.id] = data

		socket.on 'player_joined', (player) ->
			AddPlayer player
			window.players[player.id] = player
			me.game.sort()

		socket.on 'player_left', (player) ->
			oldPlayer = me.game.getEntityByGUID(player.id)
			me.game.remove(oldPlayer, true)
			delete window.players[player.id] if window.players[player.id]?

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

	window.counter = 0

	game.onload()

PlayerEntity = me.ObjectEntity.extend(
	init: (x, y, settings) ->
		@parent x, y, {image: 'bear-sheet', spritewidth: 64, spriteheight:128}
		
		# jumping animation
		@addAnimation "jump", [0,1,2,3]
		# pulling animation
		@addAnimation "pull", [4,5,6]
		# pushing animation
		@addAnimation "push", [4,7,8]
		# breathing animation
		@addAnimation "breathe", [4,9,10]
		# walking animation
		@addAnimation "walk", [4,11,12,13,14]
		
		@setVelocity 3, 15
		@updateColRect -1, 310, 20, 620
		@name = 'remotePlayer'

	update: ->
		player = players[@GUID]
		# console.log "Updating pos for #{player.id}"
		if player?
			forceAnimate = true
			@pos.x = player.pos.x
			@pos.y = player.pos.y
			@vel.x = player.vel.x
			@vel.y = player.vel.y
			@updateMovement()
		
		@flipX true if @vel.x < 0
		@flipX false if @vel.x > 0

		if @vel.x != 0 || @vel.y != 0 || forceAnimate
			@parent this
			return true

		return false
)


LocalPlayerEntity = me.ObjectEntity.extend(
	init: (x, y, settings) ->
		@parent x, y, {image: 'bear-sheet', spritewidth: 128, spriteheight:256}
		
		# jumping animation
		@addAnimation "jump", [0,1,2,3]
		# pulling animation
		@addAnimation "pull", [4,5,6]
		# pushing animation
		@addAnimation "push", [4,7,8]
		# breathing animation
		@addAnimation "breathe", [4,9,10]
		# walking animation
		@addAnimation "walk", [4,11,12,13,14]
		
		@setVelocity 3, 15
		#@updateColRect -1, 310, 20, 590
		@name = 'bear'

		@GUID = window.id

		socket.emit 'player_joining', MakePlayerJson(this)
		me.game.viewport.follow @pos, me.game.viewport.AXIS.BOTH

		#console.log "GUID: #{@GUID}"

	update: ->
		oldPos = new me.Vector2d(@pos.x, @pos.y)
		oldVel = new me.Vector2d(@vel.x, @vel.y)

		# horizontal movement
		if me.input.isKeyPressed 'left'
			keypress = true
			#console.log 'animate walking left'
			
			# only animate walk when not jumping
			if not @jumping
				@setCurrentAnimation "walk"
			
			@flipX true
			@vel.x -= @accel.x * me.timer.tick
		else if me.input.isKeyPressed 'right'
			keypress = true
			#console.log 'animate walking right'
			
			# only animate walk when not jumping
			if not @jumping
				@setCurrentAnimation "walk"
			
			@flipX false
			@vel.x += @accel.x * me.timer.tick
		else
			this.vel.x = 0

		# jump
		if me.input.isKeyPressed('jump')
			if not @jumping and not @falling
				@vel.y -= @maxVel.y * me.timer.tick
				@jumping = true
				#console.log 'animate jump'
				@setCurrentAnimation "jump"

		# update movement & animate
		@updateMovement()

		if oldPos.x isnt @pos.x || oldPos.y isnt @pos.y || oldVel.x isnt @vel.x || oldVel.y isnt @vel.y
			socket.emit 'position_changing', MakePlayerJson(this)

		# breathe when standing still
		if @vel.x is 0 and @vel.y is 0
			@setCurrentAnimation "breathe"
		
		# always render an animation
		@parent this
		return true
)

MakePlayerJson = (player) ->
	playerJson = 
		id: player.GUID
		pos: player.pos
		vel: player.vel
		falling: player.falling
		jumping: player.jumping
		timestamp: window.counter++
