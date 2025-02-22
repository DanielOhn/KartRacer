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
			start_game()
	#multiplayer.peer_connected.connect(add_player)
	#multiplayer.peer_disconnected.connect(del_player)
	

func start_game():
	print("Multiplayer Peers: ", multiplayer.get_peers())
	var count = 0
	
	for id in multiplayer.get_peers():
		add_player(id, count)
		count += 1
	
	if not OS.has_feature("dedicated_server"):
		print("Host should hit this.")
		add_player(1, count)
		count += 1

func add_player(id: int, count):
	print("ADD PEER: " + str(id))
	var character = load("res://assets/kart.tscn").instantiate()
	
	var target = $PinkBox.position
	character.position = Vector3(target.x + count * 5, target.y + 2, target.z)
	character.name = str(id)
	$PlayerSpawner.add_child(character, true)
	
	character.set_authority.rpc(id)
	
func del_player(id: int):
	if not $PlayerSpawner.has_node(str(id)):
		return
	$PlayerSpawner.get_node(str(id)).queue_free()
