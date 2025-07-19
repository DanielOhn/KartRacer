extends Control

@export var steam_lobby: Control
@export var main_menu: Control

func _ready():
	hide()

func _on_exit_button_pressed():
	steam_lobby.leave_lobby()
	hide()
	steam_lobby.show()
	

func _on_start_game_pressed():
	steam_lobby.begin_game()
	main_menu.hide()

func show_user_lobby():
	show()
