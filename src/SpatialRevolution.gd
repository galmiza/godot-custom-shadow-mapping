extends Spatial

#
# Rotates around a target position
#

export var angle: float = 0.0
export var speed: float = 0.2
export var radius: float # computed in _ready
export var height: float # computed in _ready
export var target: Vector3 = Vector3.ZERO

func _ready() -> void:
	radius = get_transform().origin.length()
	height = get_transform().origin.y

func _process(delta) -> void:
	angle += speed*delta
	look_at_from_position(target+Vector3(radius*cos(angle),height,radius*sin(angle)),target,Vector3.UP)