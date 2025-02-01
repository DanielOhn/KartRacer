extends Node

var playerSteamId
var playerUsername

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

	playerSteamId = Steam.getSteamID()
	playerUsername = Steam.getFriendPersonaName(playerSteamId)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass # Might have to call Steam.callbacks() here in the future
