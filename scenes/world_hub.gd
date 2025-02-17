extends Node3D

func _ready():
	print("Map ready")
	
	if not multiplayer.is_server():
		print("Not A Server")
		var steamLobby = get_tree().get_current_scene().get_node("SteamLobby")
		steamLobby.player_loaded.rpc_id(1)
		return 
	
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)
	

func start_game():
	print("Multiplayer Peers: ", multiplayer.get_peers())
	
	for id in multiplayer.get_peers():
		
		add_player(id)

	if not OS.has_feature("dedicated_server"):
		add_player(1)

func add_player(id: int):
	print("Add player: " + str(id))
	var character = preload("res://assets/kart.tscn").instantiate()
	character.player = id

	var target = $PinkBox.position
	

	character.set_authority(id)
	#character.teleport.rpc_id(id, target)

	character.position = target
	character.name = str(id)
	$PlayerSpawner.add_child(character, true)
	
func del_player(id: int):
	if not $PlayerSpawner.has_node(str(id)):
		return
	$PlayerSpawner.get_node(str(id)).queue_free()
