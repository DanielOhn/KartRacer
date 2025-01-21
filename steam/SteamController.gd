extends Node

@export var FriendCard: PackedScene

var playerId

# Called when the node enters the scene tree for the first time.
func _ready():
	var init_response: Dictionary  = Steam.steamInitEx(true, 480)
	print("Did Steam initialize?: %s " % init_response)
	
	var steamRunning = Steam.isSteamRunning()
	
	if steamRunning:
		print("Steam is running")
	else:
		print("Steam is not running")
		return

	playerId = Steam.getSteamID()
	var name = Steam.getFriendPersonaName(playerId)
	
	$PlayerCard/HBoxContainer/Name.text = name 
	Steam.avatar_loaded.connect(AvatarLoaded)
	print("Your steam name is ", name)
	
	Steam.getPlayerAvatar()
	getFriends()
	
func getFriends():
	var onlineFriends: Array
	var ingameFriends: Array
	
	for i in range(0, Steam.getFriendCount()):
		var friendId = Steam.getFriendByIndex(i, Steam.FRIEND_FLAG_IMMEDIATE)
		
		if friendId:
			var online = Steam.getFriendPersonaState(friendId)
			
			var friend = {
				"id" : friendId,
				"online" : true if online == 1 else false,
				"game" : Steam.getFriendGamePlayed(friendId),
				"name" : Steam.getFriendPersonaName(friendId)
			}
			
			if friend.game != {}:
				ingameFriends.append(friend)
			elif friend.online:
				onlineFriends.append(friend)
		
	
	for f in ingameFriends:
		var currentCard: FriendCard = FriendCard.instantiate()
		currentCard.InitCard(f.name, f.id, f.game, f.online)
		$FriendPanel/ScrollContainer/VBoxContainer.add_child(currentCard)
		Steam.getPlayerAvatar(2, f.id)
		
	for f in onlineFriends:
		var currentCard: FriendCard = FriendCard.instantiate()
		currentCard.InitCard(f.name, f.id, f.game, f.online)
		$FriendPanel/ScrollContainer/VBoxContainer.add_child(currentCard)
		Steam.getPlayerAvatar(2, f.id)
		
	
func AvatarLoaded(id, size, buffer):
	var avatarImage = Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, buffer)
	var texture = ImageTexture.create_from_image(avatarImage)
	
	if id == playerId:
		$PlayerCard/HBoxContainer/ProfilePic.texture = texture
	else:
		for i in $FriendPanel/ScrollContainer/VBoxContainer.get_children():
			if i.Id == id:
				i.SetAvatar(texture)
