extends Viewport

# Preallocate memory for matrices
var mat1: ShaderMaterial = preload("res://shadermaterial_depthmap.tres") # depth map material
var mat2: ShaderMaterial = preload("res://shadermaterial_light1.tres") # shadow rendering material

# Duplicate all mesh for the shadow pass
func _ready():
	var root: Node = get_parent()
	for node in root.get_children():
		if node is MeshInstance:
			var copy: Node = node.duplicate()
			copy.set_surface_material(0,mat1) # one set of objects for the depth map
			node.set_surface_material(0,mat2) # one set of objects for the final pass
			add_child(copy)

# Update material of objects in the scene
func reload(type: int):
	var root: Node = get_parent()
	for node in root.get_children():
		if node is MeshInstance:
			if type==1: node.set_surface_material(0,null) # if object has no material, the default pipeline is used
			if type==2: node.set_surface_material(0,mat2)

# Create light views and update shader parameters
export var bias: float = -0.005
func _process(delta):
	
	# Compute orthogonal light view
	var c: Camera = $CameraOrthogonalLightView
	var light_lookat: Transform = Transform(Basis(),c.get_transform().origin)
	light_lookat = light_lookat.looking_at(c.get_transform().origin-c.get_transform().basis.z,c.get_transform().basis.y).affine_inverse()
	
	# Compensate the attribute 'size' of the camera which scales the lookat (but need to be scale not to discard objects not visible by the camera)
	var size_inv: float = 1.0/c.get_size()
	var light_scaled_lookat: Transform = light_lookat
	light_scaled_lookat = light_scaled_lookat.scaled(Vector3(size_inv,size_inv,1))
	
	# Update shader parameters
	mat1.set_shader_param("uNear",c.get_znear())
	mat1.set_shader_param("uFar",c.get_zfar())
	mat1.set_shader_param("uLookAtView",light_lookat)
	mat2.set_shader_param("uBias",bias)
	mat2.set_shader_param("uLightDirection",-c.get_transform().basis.z)
	mat2.set_shader_param("uNear",c.get_znear())
	mat2.set_shader_param("uFar",c.get_zfar())
	mat2.set_shader_param("uTextureDepth",get_texture())
	mat2.set_shader_param("uScaleLookAtView",light_scaled_lookat)
	
	# Choose between Godot shadow and custom shadow
	if Input.is_action_just_pressed("ui_up"): reload(1)
	if Input.is_action_just_pressed("ui_down"): reload(2)
	
	# Show FPS to track global performance
	print(Engine.get_frames_per_second())