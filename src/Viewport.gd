extends Viewport

# Preload materials, useful nodes and classes
var mat1: ShaderMaterial = preload("res://shadermaterial_depthmap.tres") # depth map material
var mat2: ShaderMaterial = preload("res://shadermaterial_light1.tres") # shadow rendering material
onready var light: DirectionalLight = get_node("/root/Scene/DirectionalLight")
onready var renderables: DirectionalLight = get_node("/root/Scene/Renderables")
const ViewABB = preload("res://ViewABB.gd").ViewABB # load class ViewABB

# Duplicate all mesh for the shadow pass
func _ready() -> void:
	for node in  renderables.get_children():
		var copy: Node = node.duplicate()
		copy.set_surface_material(0,mat1) # one set of objects for the depth map
		node.set_surface_material(0,mat2) # one set of objects for the final pass
		add_child(copy)

# Update material of objects in the scene
func reload(type: int) -> void:
	for node in renderables.get_children():
		if type==1: node.set_surface_material(0,null) # if object has no material, the default pipeline is used
		if type==2: node.set_surface_material(0,mat2)

# Create light views and update shader parameters
export var bias: float = -0.005
var vabb: ViewABB = ViewABB.new()
func _process(delta) -> void:

	# Project AABB corners of all objects into our light view camera base to see how we should scale it (=which near,far,size?)
	var c: Camera = $CameraOrthogonalLightView
	c.set_transform(light.get_transform()) # move our camera at the light position
	vabb.reset() # reset our light view aligned bounding box
	vabb.set_transform(c.get_transform())
	for node in renderables.get_children():
		vabb.add_node(node)

	# Setup the light view camera
	var center: Vector3 = (vabb._max+vabb._min)/2
	c.translate(center) # move camera inside the AABB
	c.set_znear(center.z-vabb._max.z) # set near so that the nearest object is inside the camera frustum
	c.set_zfar(center.z-vabb._min.z) # set far so that the furthest object is inside the camera frustum
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