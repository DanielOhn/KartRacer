extends MultiplayerSynchronizer

@export var camera : Camera3D

@export var jumping := false
@export var input_motion := Vector2()
@export var do_jump := false

var paused = false
signal pause
signal unpause

func _ready():
	# Disables camera on non-host server setups, or dedicated server builds
	#camera.current = false
		
	if get_multiplayer_authority() == multiplayer.get_unique_id():
		camera.make_current()
		
	else: 
		set_process(false)
		set_process_input(false)

func _process(_delta):
	# handle game pause with esc key
	if Input.is_action_just_released("ui_cancel"):
		paused = !paused
		if paused:
			input_motion = Vector2(0,0)
			pause_game()
		else:
			unpause_game()

	if not paused:
		input_motion = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		
		if Input.is_action_just_pressed("ui_accept"):
			jump.rpc()



@rpc("call_local")
func jump():
	# We have to use call_local to allow for hosting configurations, but we don't need to call this 
	# locally on the client since our server has authority over player movement
	if multiplayer.is_server():
		do_jump = true

@rpc("call_local")
func quit_game():
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()

		# Disconnection logic follows here


# pause / mouse capture 
func pause_game():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#get_tree().paused = true #In case you want to pause the game
	pause.emit()

func unpause_game():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#get_tree().paused = false
	unpause.emit()

func _quit_pressed():
	# need players to be able to use mouse for menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 
	quit_game.rpc()
	
	
