extends Button
@export var create_scene: PackedScene
var menu = null

# Called when the node enters the scene tree for the first time.
func _ready():
	menu =  get_tree().root.get_child(1)


func _on_pressed():
	var new_scene = create_scene.instantiate()
	menu.get_child(4).add_child(new_scene)
	
	
	
	hide_menu()
	
func hide_menu():
	
	print(menu.name)
	menu.get_child(0).hide()
	menu.get_child(1).hide()
	menu.get_child(2).hide()
