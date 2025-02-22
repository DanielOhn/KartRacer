extends Node3D

func _ready():
	print("Map ready")
	
	if not multiplayer.is_server():
		print("Not A Server")
		var steamLobby = get_tree().get_current_scene().get_node("SteamLobby")
		steamLobby.player_loaded.rpc_id(1)
		return 
	
	#multiplayer.peer_connected.connect(add_player)
	#multiplayer.peer_disconnected.connect(del_player)
	

func start_game():
	print("Multiplayer Peers: ", multiplayer.get_peers())
	var count = 0
	for id in multiplayer.get_peers():
		
		add_player(id, count)
		count += 1
	
	if not OS.has_feature("dedicated_server"):
		add_player(1, count)
		count += 1

func add_player(id: int, count: int):
	print("Add player: " + str(id))
	var character = preload("res://assets/kart.tscn").instantiate()
	character.set_authority.rpc(id)
	#character.player = id

	var target = $PinkBox.position

	character.position = Vector3(target.x + count * 10, target.y + count * 10, target.z)
	character.name = str(id)
	$PlayerSpawner.add_child.call_deferred(character, true)
	
func del_player(id: int):
	if not $PlayerSpawner.has_node(str(id)):
		return
	$PlayerSpawner.get_node(str(id)).queue_free()
