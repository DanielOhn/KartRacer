extends Node3D

@export var select: MeshInstance3D
@export var path: Path3D
@export var camera: Camera3D
@export var state: States = States.PATH_CREATION

var path_point = preload("res://assets/road_point.tscn")
var y_plane: float = 0
var point_index: int = 0

var points: Array = []
enum States {PATH_CREATION, PATH_SELECT, EDIT_POINT}

# Color Materials
var color_green = preload("res://material/green.tres")
var color_yellow = preload("res://material/yellow.tres")

# Called when the node enters the scene tree for the first time.
func _ready():
	select.position = Vector3(0, y_plane, 0)
	
func _input(event):
	#  Add Delete Last Point for Path_Creation
	
	if state == States.PATH_CREATION:
		if event.is_action_pressed("create_point"):
			path.curve.add_point(select.position,Vector3(0, 0, 0), Vector3(0, 0, 0))
			print(path.curve.point_count)
			print(path.curve.sample(0, 1))
			print("Curve Created @ ", select.position)
			
			var point = path_point.instantiate()
			points.append(point)
			point.position = select.position
			$Points.add_child(point)
	
	if state == States.PATH_SELECT:
		if event.is_action_pressed("ui_right"):
			points[point_index].set_surface_override_material(0, color_green)
			if point_index == path.curve.point_count - 1:
				point_index = 0
			else:
				point_index += 1
			
			points[point_index].set_surface_override_material(0, color_yellow)
			select.position = path.curve.get_point_position(point_index)
	
		if event.is_action_pressed("ui_left"):
			points[point_index].set_surface_override_material(0, color_green)
			if point_index == 0:
				point_index = path.curve.point_count - 1
			else:
				point_index -= 1
				
			points[point_index].set_surface_override_material(0, color_yellow)
			select.position = path.curve.get_point_position(point_index)
		# Iterate between road points
	
	if event.is_action_pressed("finish_road"):
		$RoadPath/CSGPolygon3D.path_joined = !$RoadPath/CSGPolygon3D.path_joined
		
		if $RoadPath/CSGPolygon3D.path_joined:
			state = States.PATH_SELECT
			point_index = 0
			select.position = path.curve.get_point_position(point_index)
			points[point_index].set_surface_override_material(0, color_yellow)
			
			select.hide()
		else:
			state = States.PATH_CREATION
			select.show()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			camera.transform.origin = camera.transform.origin - Vector3(0, 2, 0)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			camera.transform.origin = camera.transform.origin + Vector3(0, 2, 0)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	camera.look_at(select.position)
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir  := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		
	if state == States.PATH_CREATION:
		if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down"):
			select.position.x += input_dir.x
			select.position.z += input_dir.y
			
		if Input.is_action_pressed("shift_down"):
			select.position.y -= 1
		elif Input.is_action_pressed("shift_up"):
			select.position.y += 1
			
	if state == States.PATH_SELECT:
		#select.hide()
		pass
		
		#path.curve.add_point(path.curve.get_point_position(0))
		#var point = path_point.instantiate()
		
		#point.position = path.curve.get_point_position(0)
		#$Points.add_child(point)
		#
