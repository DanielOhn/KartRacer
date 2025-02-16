extends Control

const PACKET_READ_LIMIT: int = 32

var peer : MultiplayerPeer = null

var is_host: bool = false
var lobby_data
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 8
var lobby_vote_kick: bool = false
var steam_id: int = 0


var kart_lobby = load("res://scenes/Lobby/lobby.tscn").instantiate()
@onready var main_menu = $".."

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
			register_player.rpc_id(id, SteamGlobal.playerUsername)
	)
	


#region Lobby Created
func create_lobby() -> void:
	# Make sure a lobby is not already set
	if lobby_id == 0:
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, lobby_members_max)

func _on_lobby_created(connect: int, this_lobby_id: int) -> void:
	if connect == 1:
		# Set the lobby ID
		lobby_id = this_lobby_id
		print("Created a lobby: %s" % lobby_id)

		# Set this lobby as joinable, just in case, though this should be done by default
		# Set some lobby data
		Steam.setLobbyData(lobby_id, "name", "%s Lobby" % SteamGlobal.playerUsername)
		Steam.setLobbyData(lobby_id, "mode", "")
		Steam.setLobbyJoinable(lobby_id, true)
		
		# Allow P2P connections to fallback to being relayed through Steam if needed
		# var set_relay: bool = Steam.allowP2PPacketRelay(true)
		# print("Allowing Steam to be relay backup: %s" % set_relay)
		create_steam_socket()
		
		get_tree().root.add_child(kart_lobby)
		main_menu.hide()
		#assert(multiplayer.is_server())
		print("Is Server? ", multiplayer.is_server())
	else:
		print("ERROR ON LOBBY CREATION")
#endregion 

#region Lobby Match List
func _on_open_lobby_list_pressed() -> void:
	# Set distance to worldwide
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_DEFAULT)
	print("Requesting a lobby list")
	
	var lobbies = $LobbyUI/ScrollContainer/VBoxContainer.get_children()
	for lobby in lobbies:
		lobby.queue_free()
	
	Steam.requestLobbyList()

func _on_lobby_match_list(these_lobbies: Array) -> void:
	print("on_lobby_match_list: ", these_lobbies)
	for this_lobby in these_lobbies:
		# Pull lobby data from Steam, these are specific to our example
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
#endregion
#region Lobby Joined
func join_lobby(this_lobby_id: int) -> void:
	print("Attempting to join lobby %s" % lobby_id)

	# Clear any previous lobby members lists, if you were in a previous lobby
	lobby_members.clear()

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
			register_player.rpc(SteamGlobal.playerUsername)
			# Get the lobby members
			#lobby_members[multiplayer.get_unique_id()] = SteamGlobal.playerUsername
			get_lobby_members()
			#assert(multiplayer.is_server())

		# Make the initial handshake
		#make_p2p_handshake()

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
#region Lobby Members
func get_lobby_members() -> void:
	# Clear your previous lobby list
	lobby_members.clear()

	# Get the number of members from this lobby from Steam
	var num_of_members: int = Steam.getNumLobbyMembers(lobby_id)

	# Get the data of these players from Steam
	for this_member in range(0, num_of_members):
		# Get the member's Steam ID
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)

		# Get the member's Steam name
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)

		# Add them to the list
		lobby_members.append({"steam_id":member_steam_id, "steam_name":member_steam_name})
	
	print(lobby_members)
#endregion

func leave_lobby() -> void:
	# If in a lobby, leave it
	if lobby_id != 0:
		# Send leave request to Steam
		Steam.leaveLobby(lobby_id)

		# Wipe the Steam lobby ID then display the default lobby ID and player list title
		lobby_id = 0

		# Close session with all users
		for this_member in lobby_members:
			# Make sure this isn't your Steam ID
			if this_member['steam_id'] != steam_id:

				# Close the P2P session
				Steam.closeP2PSessionWithUser(this_member['steam_id'])

		# Clear the local lobby list
		lobby_members.clear()
		
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
	if lobby_members.has(trial):
		trial = query + ' ' + str(count)
		count += 1
	return trial

@rpc("call_local", "any_peer")
func get_player_name() -> String:
	return lobby_members[multiplayer.get_remote_sender_id()]
	
# Lobby management functions.
@rpc("call_local", "any_peer")
func register_player(new_player_name : String):
	var id = multiplayer.get_remote_sender_id()
	lobby_members[id] = _make_string_unique(new_player_name)
	
# A user's information has changed
func _on_persona_change(this_steam_id: int, _flag: int) -> void:
	# Make sure you're in a lobby and this user is valid or Steam might spam your console log
	if lobby_id == this_steam_id:
		print("A user (%s) had information change, update the lobby list" % this_steam_id)

		# Update the player list
		get_lobby_members()

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
