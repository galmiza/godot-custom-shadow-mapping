#
# View Aligned Bounding Box
# Computes a bounding box in a specific base
#
class ViewABB:
	var transform: Transform
	var _max: Vector3
	var _min: Vector3

	func set_transform(t: Transform) -> void:
		transform = t
	func reset() -> void:
		_max = Vector3(-1e20,-1e20,-1e20)
		_min = Vector3( 1e20, 1e20, 1e20)

	func add_point(node: Node, point: Vector3) -> void:
		var a: Vector3 = node.get_transform().xform(point) # point in global space
		var b: Vector3 = transform.xform_inv(a) # get point in the ViewABB space
		_max.x = max(_max.x,b.x)
		_max.y = max(_max.y,b.y)
		_max.z = max(_max.z,b.z)
		_min.x = min(_min.x,b.x)
		_min.y = min(_min.y,b.y)
		_min.z = min(_min.z,b.z)
	
	func add_node(node: Node) -> void:
		var aabb: AABB = node.get_aabb()
		for i in 8:
			add_point(node,aabb.get_endpoint(i))