extends Node3D

func _ready():
	print("Map ready")
	var steamLobby = get_tree().get_current_scene().get_node("SteamLobby")
	
	if not multiplayer.is_server():
		print("Not A Server")
		steamLobby.player_loaded.rpc_id(1)
		return 
	else:
		if steamLobby.players.size() == 0:
			print("Server and no players :(")
	#multiplayer.peer_connected.connect(add_player)
	#multiplayer.peer_disconnected.connect(del_player)
	

func start_game():
	print("Multiplayer Peers: ", multiplayer.get_peers())
	for id in multiplayer.get_peers():
		add_player(id)
	
	if not OS.has_feature("dedicated_server"):
		add_player(1)

func add_player(id: int):
	assert(multiplayer.is_server())
	print("PEER ID: " + str(id))
	var character = load("res://assets/kart.tscn").instantiate()
	character.set_authority.rpc(id)

	var target = $PinkBox.position
	character.position = Vector3(target.x, target.y + 10, target.z)
	character.name = str(id)
	$PlayerSpawner.add_child(character, true)
	
func del_player(id: int):
	if not $PlayerSpawner.has_node(str(id)):
		return
	$PlayerSpawner.get_node(str(id)).queue_free()
