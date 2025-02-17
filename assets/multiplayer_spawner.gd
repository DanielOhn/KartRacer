extends MultiplayerSpawner


@export var playerScene : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	spawn_function = spawnPlayer
	if not multiplayer.is_server():
		print("RETURNING")
		return
	
	print("Level Ready")

	if is_multiplayer_authority():
		spawn(1)
		multiplayer.peer_connected.connect(spawn)
		multiplayer.peer_disconnected.connect(removePlayer)


var players = {}

func spawnPlayer(data):
	var p = playerScene.instantiate()
	
	p.set_multiplayer_authority(data)
	players[data] = p
	print("SPAWNING PLAYER")
	return p
	
func removePlayer(data):
	players[data].queue_free()
	players.erase(data)

@rpc("any_peer", "call_local")
func teleport(new_position : Vector2) -> void:
	self.position = new_position
