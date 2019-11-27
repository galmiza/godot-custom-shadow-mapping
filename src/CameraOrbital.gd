extends Spatial

#
# Orbital camera
# Follows the parent node but keeps a constant global view axis
# Mouse a finger to rotate around the parent node
#

# Constants and parameters
const UP: Vector3 = Vector3(0,1,0)
export var radius: float = 10
export var sensitivity: Vector2 = Vector2(0.01,0.01)
export var enabled: bool = true

# Operational variables
var axis: Vector3
var last_position: Vector2

func _ready() -> void:
	radius = get_transform().origin.length()
	axis = get_transform().origin.normalized()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		last_position = event.position
	if event is InputEventScreenDrag and enabled:
		var delta: Vector2 = last_position - event.position
		last_position = event.position
		axis = axis.rotated(get_global_transform().basis.y,delta.x*sensitivity.x)
		axis = axis.rotated(get_global_transform().basis.x,delta.y*sensitivity.y)

func _process(delta: float) -> void:
	var global_position = get_parent().get_global_transform().origin
	look_at_from_position(global_position+radius*axis,global_position,UP)