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

var cam_rotation = false

# Color Materials
var color_green = preload("res://material/green.tres")
var color_yellow = preload("res://material/yellow.tres")
var color_blue = preload("res://material/blue.tres")
var color_db = preload("res://material/dark_blue.tres")

var drag_point = null

# Called when the node enters the scene tree for the first time.
func _ready():
	select.position = Vector3(0, y_plane, 0)
	
func _input(event):
	#  Add Delete Last Point for Path_Creation
	
	if state == States.PATH_CREATION:
		if event.is_action_pressed("create_point"):
			var in_pos: Vector3 = Vector3(1, 0, 1)
			var out_pos: Vector3 = Vector3(-1, 0, -1)
			
			path.curve.add_point(select.position, in_pos, out_pos)
			
			
			var point = path_point.instantiate()
			points.append(point)
			
			point.position = select.position
			point.get_child(0).position = in_pos
			point.get_child(1).position = out_pos
			
			point.get_child(0).hide()
			point.get_child(1).hide()
			
			$Points.add_child(point)
	
	if state == States.PATH_SELECT:
		if event.is_action_pressed("ui_right"):
			points[point_index].set_surface_override_material(0, color_green)
			points[point_index].get_child(0).hide()
			points[point_index].get_child(1).hide()
			
			if point_index == path.curve.point_count - 1:
				point_index = 0
			else:
				point_index += 1
			
			points[point_index].set_surface_override_material(0, color_yellow)
			select.position = path.curve.get_point_position(point_index)
			points[point_index].get_child(0).show()
			points[point_index].get_child(1).show()
	
		if event.is_action_pressed("ui_left"):
			points[point_index].set_surface_override_material(0, color_green)
			points[point_index].get_child(0).hide()
			points[point_index].get_child(1).hide()
			
			if point_index == 0:
				point_index = path.curve.point_count - 1
			else:
				point_index -= 1
				
			points[point_index].set_surface_override_material(0, color_yellow)
			select.position = path.curve.get_point_position(point_index)
			points[point_index].get_child(0).show()
			points[point_index].get_child(1).show()
		
		if event.is_action_pressed("delete"):
			path.curve.remove_point(point_index)
			points[point_index].queue_free()
			points.remove_at(point_index)
			
			if point_index - 1 < 0:
				point_index = 0
			else:
				point_index = point_index - 1

		if event.is_action_pressed("mouse_click") and event.is_pressed():
			var get_point = get_mouse_intersect(event.position)
			if get_point != null:
					print("CLICK")
					drag_point = get_point
		elif event.is_action_released("mouse_click"):
			drag_point = null
		
		if event is InputEventMouseMotion and drag_point != null:
			var update_pos = Vector3(event.relative.x, 0, event.relative.y)
			print("updated pos", update_pos)
			
			drag_point.position += update_pos * .01
			print(drag_point.name)
			
			if drag_point.name == "InPoint":
				path.curve.set_point_in(point_index, drag_point.position)
			if drag_point.name == "OutPoint":
				path.curve.set_point_out(point_index, drag_point.position)
					
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
			
	if event is InputEventMouseMotion and cam_rotation == true:
		camera.rotate(Vector3.UP, -event.relative.x * 0.01)
		camera.rotate(Vector3.RIGHT, -event.relative.y * 0.01)

func _rotate_camera(mouse_pos):
	camera.rotate(Vector3.UP, mouse_pos.x * .001)
	camera.rotate(Vector3.RIGHT, mouse_pos.y * .001)

func get_mouse_intersect(mouse_pos):
	var params = PhysicsRayQueryParameters3D.new()
	params.from = camera.project_ray_origin(mouse_pos)
	params.to = camera.project_position(mouse_pos, 2000)
	
	var worldspace = get_world_3d().direct_space_state
	var result = worldspace.intersect_ray(params)
	
	if result:
		var check_res = result.collider.get_parent()
		if check_res.is_in_group("PathPoint"):
			#print(check_res.name, result)
			return check_res
	else:
		return null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
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
		pass
			
	if Input.is_action_pressed("mid_mouse"):
		#_rotate_camera(get_viewport().get_mouse_position())
		cam_rotation = true
	else:
		camera.look_at(select.position)
		cam_rotation = false
	
		
		#path.curve.add_point(path.curve.get_point_position(0))
		#var point = path_point.instantiate()
		
		#point.position = path.curve.get_point_position(0)
		#$Points.add_child(point)
		#
