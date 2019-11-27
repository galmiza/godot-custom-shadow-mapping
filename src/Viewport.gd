extends Viewport

# Preload materials
var mat1: ShaderMaterial = preload("res://shadermaterial_depthmap.tres") # depth map material
var mat2: ShaderMaterial = preload("res://shadermaterial_light1.tres") # shadow rendering material
const ViewABB = preload("res://ViewABB.gd").ViewABB # load class ViewABB

# Duplicate all mesh for the shadow pass
func _ready():
	for node in  get_parent().get_children():
		if node is MeshInstance:
			var copy: Node = node.duplicate()
			copy.set_surface_material(0,mat1) # one set of objects for the depth map
			node.set_surface_material(0,mat2) # one set of objects for the final pass
			add_child(copy)

# Update material of objects in the scene
func reload(type: int):
	for node in get_parent().get_children():
		if node is MeshInstance:
			if type==1: node.set_surface_material(0,null) # if object has no material, the default pipeline is used
			if type==2: node.set_surface_material(0,mat2)

# Create light views and update shader parameters
export var bias: float = -0.005
var vabb: ViewABB = ViewABB.new()
func _process(delta):

	# Project AABB corner of all objects into our light view camera base to see how we should scale it (=which near,far,size?)
	var c: Camera = $CameraOrthogonalLightView
	vabb.reset() # reset our light view aligned bounding box
	vabb.set_transform(c.get_transform())
	for node in get_parent().get_children():
		if node is MeshInstance:
			vabb.add_node(node)

	# Setup the light view camera
	c.set_znear(-vabb._max.z) # set near so that the nearest object is inside the camera frustum
	c.set_zfar(-vabb._min.z) # set far so that the furthest object is inside the camera frustum
	c.translate_object_local(Vector3(-(vabb._max.x+vabb._min.x)/2,-(vabb._max.y+vabb._min.y)/2,0)) # adjust position of the camera
	c.set_size(max(vabb._max.x-vabb._min.x,vabb._max.y-vabb._min.y)) # scale so that all objects are in the camera frustum

	# Compute orthogonal light view
	var t: Transform = c.get_transform()
	var light_lookat: Transform = Transform(Basis(),t.origin)
	light_lookat = light_lookat.looking_at(t.origin-t.basis.z,t.basis.y).affine_inverse()

	# Compensate the scale of the camera and produce a scale independent lookat matrix to be used in the lighting shader
	var size_inv: float = 1.0/c.get_size()
	var light_scaled_lookat: Transform = light_lookat
	light_scaled_lookat = light_scaled_lookat.scaled(Vector3(size_inv,size_inv,1))

	# Update shader parameters
	mat1.set_shader_param("uNear",c.get_znear())
	mat1.set_shader_param("uFar",c.get_zfar())
	mat1.set_shader_param("uLookAtView",light_lookat)
	mat2.set_shader_param("uBias",bias)
	mat2.set_shader_param("uLightDirection",-t.basis.z)
	mat2.set_shader_param("uNear",c.get_znear())
	mat2.set_shader_param("uFar",c.get_zfar())
	mat2.set_shader_param("uTextureDepth",get_texture())
	mat2.set_shader_param("uScaleLookAtView",light_scaled_lookat)

	# Choose between Godot shadow and custom shadow
	if Input.is_action_just_pressed("ui_up"): reload(1)
	if Input.is_action_just_pressed("ui_down"): reload(2)

	# Show FPS to track global performance
	print(Engine.get_frames_per_second())