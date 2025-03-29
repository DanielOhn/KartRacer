extends VehicleBody3D


@export var SPEED = 200.0
@export var JUMP_VELOCITY = 4.5
@export var  ROTATE_speed = 0.5
@onready var camera: Camera3D = $Camera3D

const MAX_STEER = 0.8 
const ENGINE_POWER = 300
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
	

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		# Add the gravity.
		steering = Input.get_axis("ui_right","ui_left") * MAX_STEER
		engine_force = Input.get_axis("ui_down","ui_up") * ENGINE_POWER
		
