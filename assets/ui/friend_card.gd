extends Control
class_name FriendCard

var Avatar
var Id
var Name
var Game

func InitCard(name, id, game, online):
	Name = name
	Id = id
	Game = game

	if online:
		$HBoxContainer/Name.add_theme_color_override("default_color", Color.WHITE)
	else:
		$HBoxContainer/Name.add_theme_color_override("default_color", Color.WEB_GRAY)
		
		
	if game != {}:
		$HBoxContainer/Name.add_theme_color_override("default_color", Color.WEB_GREEN)

	$HBoxContainer/Name.text = Name

func SetAvatar(image):
	$HBoxContainer/ProfilePic.texture = image
	
