@tool
extends Path3D

@export var distance_between = 1.0
var is_diff = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_diff:
		#_update_multimesh()
		is_diff = false
	
func _update_multimesh():
	var path_length = curve.get_baked_length()
	print("Path Length", path_length)
	var count = floor(path_length / distance_between)
	
	var mm = $MultiMeshInstance3D.multimesh
	mm.instance_count = count 
	var offset = distance_between/2
	
	
	for i in range(0, count):
		var curve_distance = offset + distance_between * i
		var pos = curve.sample_baked(curve_distance, true)
		
		var basis = Basis()
		
		var up = curve.sample_baked_up_vector(curve_distance, true)
		var forward = position.direction_to(curve.sample_baked(curve_distance + 0.1, true))
		
		basis.y = up
		basis.x = forward.cross(up).normalized()
		basis.z = -forward
		
		var transform = Transform3D(basis, pos)
		mm.set_instance_transform(i, transform)


func _on_curve_changed():
	is_diff = true
