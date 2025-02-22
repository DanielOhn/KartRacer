extends Control

const PACKET_READ_LIMIT: int = 32

@export var UserLobby: Control

var peer : MultiplayerPeer = null
var player_name
var players_loaded = 0

var is_host: bool = false
var lobby_data
var lobby_id: int = 0
var lobby_members_max: int = 8
var lobby_vote_kick: bool = false
var steam_id: int = 0

var players := {}

@export var player_list: ItemList

var kart_lobby = load("res://scenes/Lobby/lobby.tscn").instantiate()
@onready var SteamLobby = $"."

signal player_list_changed()

# Called when the node enters the scene tree for the first time.
func _ready():
	Steam.join_requested.connect(_on_lobby_join_requested)
	#Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_created.connect(_on_lobby_created.bind())
	#Steam.lobby_data_update.connect(_on_lobby_data_update)
	#Steam.lobby_invite.connect(_on_lobby_invite)
	Steam.lobby_joined.connect(_on_lobby_joined.bind())
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	#Steam.lobby_message.connect(_on_lobby_message)
	Steam.persona_state_change.connect(_on_persona_change)

	# Check for command line arguments
	check_command_line()
	
	multiplayer.peer_connected.connect(
		func(id : int):
			# Tell the connected peer that we have also joined
			register_player.rpc_id(id, player_name)
	)
	


#region Lobby Created
func create_lobby() -> void:
	player_name = SteamGlobal.playerUsername
	# Make sure a lobby is not already set
	if lobby_id == 0:
		Steam.createLobby(2, lobby_members_max)
		

func _on_lobby_created(connect: int, this_lobby_id: int) -> void:
	if connect == 1:
		# Set the lobby ID
		lobby_id = this_lobby_id
		print("Created a lobby: %s" % lobby_id)

		# Set this lobby as joinable, just in case, though this should be done by default
		# Set some lobby data
		Steam.setLobbyData(lobby_id, "name", "%s Lobby" % player_name)
		Steam.setLobbyData(lobby_id, "mode", "")
		Steam.setLobbyJoinable(lobby_id, true)
		
		# Allow P2P connections to fallback to being relayed through Steam if needed
		# var set_relay: bool = Steam.allowP2PPacketRelay(true)
		# print("Allowing Steam to be relay backup: %s" % set_relay)
		create_steam_socket()
		
		player_list.add_item(player_name)
		SteamLobby.hide()
		UserLobby.show()
		#assert(multiplayer.is_server())
		print("Is Server? ", multiplayer.is_server())
	else:
		print("ERROR ON LOBBY CREATION")
#endregion 

#region Lobby Match List
func _on_open_lobby_list_pressed() -> void:
	# Set distance to worldwide
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.addRequestLobbyListResultCountFilter(75)
	print("Requesting a lobby list")
	
	var lobbies = $LobbyUI/ScrollContainer/VBoxContainer.get_children()
	for lobby in lobbies:
		lobby.queue_free()
	
	Steam.requestLobbyList()

func _on_lobby_match_list(these_lobbies: Array) -> void:
	#print("on_lobby_match_list: ", these_lobbies)
	print("Lobby Num: ", len(these_lobbies))
	for this_lobby in these_lobbies:
		create_join_lobby_button(this_lobby)

func create_join_lobby_button(this_lobby):
	var lobby_name: String = Steam.getLobbyData(this_lobby, "name")
	var lobby_mode: String = Steam.getLobbyData(this_lobby, "mode")

	# Get the current number of members
	var lobby_num_members: int = Steam.getNumLobbyMembers(this_lobby)

	# Create a button for the lobby
	var lobby_button: Button = Button.new()
	lobby_button.set_text("Lobby %s: %s [%s] - %s Player(s)" % [this_lobby, lobby_name, lobby_mode, lobby_num_members])
	lobby_button.set_size(Vector2(800, 50))
	lobby_button.set_name("lobby_%s" % this_lobby)
	lobby_button.connect("pressed", Callable(self, "join_lobby").bind(this_lobby))

	# Add the new lobby to the list
	#$Lobbies/Scroll/List.add_child(lobby_button)
	$LobbyUI/ScrollContainer/VBoxContainer.add_child(lobby_button)

func get_lobbies_with_friends() -> Dictionary:
	var results: Dictionary = {}
	for i in range(0, Steam.getFriendCount()):
		var steam_id: int = Steam.getFriendByIndex(i, Steam.FRIEND_FLAG_IMMEDIATE)
		var game_info: Dictionary = Steam.getFriendGamePlayed(steam_id)

		if game_info.is_empty():
			# This friend is not playing a game
			continue
		else:
			# They are playing a game, check if it's the same game as ours
			var app_id: int = game_info['id']
			var lobby = game_info['lobby']
			if app_id != Steam.getAppID() or lobby is String:
				# Either not in this game, or not in a lobby
				continue
			if not results.has(lobby):
				results[lobby] = []
			results[lobby].append(steam_id)
	print("FRIEND LOBBIES: ", results)
	
	var lobbies = $LobbyUI/ScrollContainer/VBoxContainer.get_children()
	for lobby in lobbies:
		lobby.queue_free()
		
	for this_lobby in results:
		create_join_lobby_button(this_lobby)
	
	return results

#endregion
#region Lobby Joined
func join_lobby(this_lobby_id: int) -> void:
	print("Attempting to join lobby %s" % lobby_id)
	player_name = SteamGlobal.playerUsername
	# Clear any previous lobby members lists, if you were in a previous lobby
	players.clear()
	
	# Make the lobby join request to Steam
	Steam.joinLobby(int(this_lobby_id))
	
func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# If joining was successful
	if response == 1:
		# Set this lobby ID as your lobby ID
		lobby_id = this_lobby_id
		var id = Steam.getLobbyOwner(this_lobby_id)
		if id != Steam.getSteamID():
			connect_steam_socket(id)
			SteamLobby.hide()
			UserLobby.show()
			
			if peer:
				register_player(player_name)
				# Get the lobby members
				players[multiplayer.get_unique_id()] = player_name

	# Else it failed for some reason
	else:
		# Get the failure reason
		var fail_reason: String

		match response:
			Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: fail_reason = "This lobby no longer exists."
			Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: fail_reason = "You don't have permission to join this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: fail_reason = "The lobby is now full."
			Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: fail_reason = "Uh... something unexpected happened!"
			Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: fail_reason = "You are banned from this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: fail_reason = "You cannot join due to having a limited account."
			Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: fail_reason = "This lobby is locked or disabled."
			Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: fail_reason = "This lobby is community locked."
			Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: fail_reason = "A user in the lobby has blocked you from joining."
			Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: fail_reason = "A user you have blocked is in the lobby."

		print("Failed to join this chat room: %s" % fail_reason)

		#Reopen the lobby list
		_on_open_lobby_list_pressed()

func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
	# Get the lobby owner's name
	var owner_name: String = Steam.getFriendPersonaName(friend_id)

	print("Joining %s's lobby..." % owner_name)

	# Attempt to join the lobby
	join_lobby(this_lobby_id)
#endregion 

func leave_lobby() -> void:
	# If in a lobby, leave it
	if lobby_id != 0:
		# Send leave request to Steam
		Steam.leaveLobby(lobby_id)
		player_list.clear()

		# Wipe the Steam lobby ID then display the default lobby ID and player list title
		lobby_id = 0
		# Clear the local lobby list
		players.clear()
		
#region Steam Peer Management
func create_steam_socket():
	peer = SteamMultiplayerPeer.new()
	peer.create_host(0)
	multiplayer.multiplayer_peer = peer
	
	print("Steam Socket Created")
	print(multiplayer)
	print(multiplayer.multiplayer_peer)

func connect_steam_socket(steam_id : int):
	peer = SteamMultiplayerPeer.new()
	peer.create_client(steam_id, 0)
	multiplayer.multiplayer_peer = peer
	
	print("Steam Socket Connected")
	print(multiplayer)
	print(multiplayer.multiplayer_peer)
	
#endregion

#region Player Name Management
func _make_string_unique(query : String) -> String:
	var count := 2
	var trial := query
	if players.values().has(trial):
		trial = query + ' ' + str(count)
		count += 1
	return trial

@rpc("call_local", "any_peer")
func get_player_name() -> String:
	return players[multiplayer.get_remote_sender_id()]
	
# Lobby management functions.
@rpc("call_local", "any_peer")
func register_player(new_player_name : String):
	var id = multiplayer.get_remote_sender_id()
	players[id] = _make_string_unique(new_player_name)
	
	player_list.add_item(new_player_name)
	player_list_changed.emit()

func unregister_player(id):
	player_list.remove_item(players[id])
	players.erase(id)
	player_list_changed.emit()

# A user's information has changed
func _on_persona_change(this_steam_id: int, _flag: int) -> void:
	# Make sure you're in a lobby and this user is valid or Steam might spam your console log
	if lobby_id == this_steam_id:
		print("A user (%s) had information change, update the lobby list" % this_steam_id)

#endregion

func check_command_line() -> void:
	var these_arguments: Array = OS.get_cmdline_args()
	
	# There are arguments to process
	if these_arguments.size() > 0:
		
		# A Steam connection argument exists
		if these_arguments[0] == "+connect_lobby":
			
			# Lobby invite exists so try to connect to it
			if int(these_arguments[1]) > 0:
				
				# At this point, you'll probably want to change scenes
				# Something like a loading into lobby screen
				print("Command line lobby ID: %s" % these_arguments[1])
				join_lobby(int(these_arguments[1]))

@rpc("call_local")
func load_world():
	# Change scene.
	var world = preload("res://scenes/WorldHub.tscn").instantiate()
	$"../World".add_child(world)
	$"../SteamOverlay".hide()
	$".".hide()
	$"../UserLobby".hide()
	
	
	get_tree().set_pause(false) # Unpause and unleash the game!

# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		print("Players Loaded: ", players_loaded)
		if players_loaded == players.size():
			$"../World/WorldHub".start_game()


func begin_game():
	#Ensure that this is only running on the server; if it isn't, we need
	#to check our code.
	assert(multiplayer.is_server())
	
	#call load_world on all clients
	if multiplayer.is_server():
		load_world.rpc()
