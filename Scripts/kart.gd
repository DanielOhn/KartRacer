extends CharacterBody3D


@export var SPEED = 200.0
@export var JUMP_VELOCITY = 4.5
@export var  ROTATE_speed = 0.5
@onready var camera: Camera3D = $Camera3D
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
	set_multiplayer_authority(id)
	player = id

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction := (transform.basis * Vector3(0, 0, input_dir.y))
		if direction:
			velocity.x = direction.x * SPEED * delta
			velocity.z = direction.z * SPEED * delta
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
			
		if Input.is_action_pressed("ui_right") :
			rotate_y(-ROTATE_speed * delta)
		if Input.is_action_pressed("ui_left") :
			rotate_y(ROTATE_speed * delta)

		move_and_slide()
