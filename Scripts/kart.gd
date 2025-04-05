extends VehicleBody3D


@export var SPEED = 200.0
@export var JUMP_VELOCITY = 4.5
@export var  ROTATE_speed = 0.5
@onready var camera: Camera3D = $Camera3D

const MAX_STEER = 0.8 
const ENGINE_POWER = 400
#@onready var InputSync: MultiplayerSynchronizer = 

@export var player := 1:
	set(id):
		player = id

func _ready():
	if str(name).is_valid_int():
		print("Player has spawned: ", name)
		
	if player == multiplayer.get_unique_id():
		camera.current = true
	
	if OS.has_feature("dedicated_server"):
		%InputSynchronizer.set_multiplayer_authority(player)

@rpc("any_peer", "call_local")
func set_authority(id: int) -> void:
	player = id
	
	set_multiplayer_authority(id)
	%InputSynchronizer.set_multiplayer_authority(id)

var on_floor_time: int = 0 #

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var i := 0
	while i < state.get_contact_count():
		var normal := state.get_contact_local_normal(i)
		var this_contact_on_floor = normal.dot(Vector3.UP) > 0.99

		if this_contact_on_floor:
			on_floor_time = Time.get_ticks_msec()
			break
		i += 1

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		# Add the gravity.

		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and on_floor_time > 0:
			apply_central_impulse(Vector3(0.0,750.0,0.0))
			on_floor_time = 0
		steering = move_toward(Input.get_axis("ui_right","ui_left") * MAX_STEER,0,delta*10)
		engine_force = Input.get_axis("ui_down","ui_up") * ENGINE_POWER
		
