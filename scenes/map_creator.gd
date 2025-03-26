extends Node3D

@export var select: MeshInstance3D
@export var path: Path3D
@export var camera: Camera3D
@export var state: States = States.PATH_CREATION
@export var map_name: TextEdit

@export var road_width: int

var path_point = preload("res://assets/road_point.tscn")
var y_plane: float = 0
var point_index: int = 0

var points: Array = []
enum States {PATH_CREATION, PATH_SELECT, PATH_GOALSET, PATH_FINISH}

var map_script = preload("res://scenes/world_hub.gd")

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
	$RoadPath/RoadMesh.set_polygon(PackedVector2Array([Vector2(0, 0), Vector2(0, .1), Vector2(road_width, .1), Vector2(road_width, 0)]))
		
func _input(event):
	#  Add Delete Last Point for Path_Creation
	#print("INDEX: ", point_index, " - ", path.curve.point_count)
	#print("POINT ARRAY: ", points)
	if state == States.PATH_CREATION:
		if event.is_action_pressed("create_point"):
			var in_pos: Vector3 = Vector3(.12, 0, .12)
			var out_pos: Vector3 = Vector3(-.12, 0, -.12)
			
			path.curve.add_point(select.position, in_pos, out_pos)
			
			var point = path_point.instantiate()
			point.position = select.position
			point.get_child(0).position = in_pos
			point.get_child(1).position = out_pos

			$Points.add_child(point)
			points.append(point)
	
	if state == States.PATH_SELECT:
		if event.is_action_pressed("ui_right"):
			points[point_index].set_surface_override_material(0, color_green)
			points[point_index].hide()
			
			if point_index == path.curve.point_count - 1:
				point_index = 0
			else:
				point_index += 1
			
			points[point_index].set_surface_override_material(0, color_yellow)
			select.position = path.curve.get_point_position(point_index)
			points[point_index].show()
	
		if event.is_action_pressed("ui_left"):
			points[point_index].set_surface_override_material(0, color_green)
			points[point_index].hide()
			
			if point_index == 0:
				point_index = path.curve.point_count - 1
			else:
				point_index -= 1
				
			points[point_index].set_surface_override_material(0, color_yellow)
			select.position = path.curve.get_point_position(point_index)
			points[point_index].show()
		
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
		
		if event.is_action_released("enter"):
			state = States.PATH_GOALSET
			print("State: ", state)
			$RoadPath/PathFollow3D/Goal.show()
			
		
		if event is InputEventMouseMotion and drag_point != null:
			var update_pos = Vector3(event.relative.x, 0, event.relative.y)
			print("updated pos", update_pos)
			
			drag_point.position += update_pos * .01
			print(drag_point.name)
			
			if drag_point.name == "InPoint":
				path.curve.set_point_in(point_index, drag_point.position)
			if drag_point.name == "OutPoint":
				path.curve.set_point_out(point_index, drag_point.position)
		
	if state == States.PATH_GOALSET:
		# Save the Level
		if event.is_action_pressed("enter"):
			print("MAP CREATED")
			
			
			var map_name_string = map_name.text
			
			state = States.PATH_FINISH
			$Selector.free()
			$MapName.free()
			$Points.free()
			name = map_name_string
			
			
			var save_scene = PackedScene.new()
			var save_self = self
			#save_self.set_script(null)
			save_self.set_script(map_script)
			save_scene.pack(save_self)
			var save_location = "res://custom_maps/" + map_name_string + ".tscn"
			ResourceSaver.save(save_scene, save_location)
			
			
			var menu = get_tree().root.get_child(1)
			
			for i in range(2):
				
				print(i)
				menu.get_child(i).show()
			
			self.queue_free()
			
			
		# Quit back to the the previous state
		if event.is_action_pressed("quit"):
			state = States.PATH_SELECT
			
	
	if event.is_action_pressed("finish_road"):
		$RoadPath/RoadMesh.path_joined = !$RoadPath/RoadMesh.path_joined

		if $RoadPath/RoadMesh.path_joined:
			var in_pos: Vector3 = Vector3(.12, 0, .12)
			var out_pos: Vector3 = Vector3(-.12, 0, -.12)
		
			path.curve.add_point(path.curve.get_point_position(0), in_pos, out_pos)
			var point = path_point.instantiate()
			
			points.append(point)
			point.position = path.curve.get_point_position(0)
			point.get_child(0).position = in_pos
			point.get_child(1).position = out_pos

			$Points.add_child(point)

			state = States.PATH_SELECT
			point_index = 0
			select.position = path.curve.get_point_position(point_index)
			points[point_index].set_surface_override_material(0, color_yellow)
			points[point_index].get_child(0).show()
			points[point_index].get_child(1).show()
			
			select.hide()
		else:
			
			var point = path.curve.get_point_position(len(points) - 1)
			path.curve.remove_point(len(points) - 1)

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
	if state == States.PATH_GOALSET:
		
		if Input.is_action_pressed("ui_left"):
			path.get_child(1).progress += 100 * delta
		if Input.is_action_pressed("ui_right"):
			path.get_child(1).progress -= 100 * delta
		
		if select != null:
			select.position = $RoadPath/PathFollow3D/Goal.global_position
		
			
	if Input.is_action_pressed("mid_mouse"):
		#_rotate_camera(get_viewport().get_mouse_position())
		cam_rotation = true
	else:
		if select != null:
			camera.look_at(select.position)
			cam_rotation = false
	
		
		#
		#var point = path_point.instantiate()
		
		#point.position = path.curve.get_point_position(0)
		#$Points.add_child(point)
		#
