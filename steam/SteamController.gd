extends Node


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

	var userId = Steam.getSteamID()
	var name = Steam.getFriendPersonaName(userId)
	
	print("Your steam name is ", name)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
