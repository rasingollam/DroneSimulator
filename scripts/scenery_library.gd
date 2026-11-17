extends Node3D
## Shared glTF geometry, baked photo textures and cached collision hulls.
const SOURCES := {"rock_09":"2k", "namaqualand_boulder_02":"2k", "wooden_crate_01":"1k", "barrel_03":"2k"}
var scenes := {}
var hulls := {}
var materials := {}
var factory_meshes := {}
var factory_transforms := {}

func pbr(label: String, metres_per_repeat: float = 2.0, tint: Color = Color.WHITE, metallic: float = 0.0) -> StandardMaterial3D:
	var key := '%s_%s_%s_%s' % [label,metres_per_repeat,tint,metallic]
	if materials.has(key):
		return materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://assets/environment/%s_color.jpg" % label)
	material.albedo_color = tint
	material.normal_enabled = true
	material.normal_texture = load("res://assets/environment/%s_normal.jpg" % label)
	material.normal_scale = 0.8
	material.roughness_texture = load("res://assets/environment/%s_roughness.jpg" % label)
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.roughness = 1.0
	material.metallic = metallic
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE/metres_per_repeat
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	materials[key] = material
	return material

func prop(asset: String, position: Vector3, width: float, yaw: float = 0.0, collision: bool = true) -> Node3D:
	if not scenes.has(asset):
		scenes[asset] = load("res://assets/models/%s/%s_%s.gltf" % [asset,asset,SOURCES[asset]])
	var instance: Node3D = scenes[asset].instantiate()
	add_child(instance)
	var meshes := instance.find_children("*","MeshInstance3D",true,false)
	var bounds := AABB()
	var first := true
	for child in meshes:
		var mesh: MeshInstance3D = child
		var transform: Transform3D = instance.global_transform.affine_inverse()*mesh.global_transform
		var box: AABB = transform*mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
		mesh.visibility_range_end = 430.0 if width < 3 else 800.0
		mesh.visibility_range_end_margin = 25.0
		for surface in range(mesh.mesh.get_surface_count()):
			var material := mesh.get_active_material(surface) as StandardMaterial3D
			if material:
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		if collision:
			var key: int = mesh.mesh.get_instance_id()
			if not hulls.has(key):
				hulls[key] = mesh.mesh.create_convex_shape(true,true)
			var body := StaticBody3D.new()
			var shape := CollisionShape3D.new()
			shape.shape = hulls[key]
			mesh.add_child(body)
			body.add_child(shape)
	var scale_factor := width/maxf(bounds.size.x,bounds.size.z)
	var centre := Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
	instance.scale = Vector3.ONE*scale_factor
	instance.rotation.y = yaw
	instance.position = position-instance.basis*centre
	return instance

func factory_block(position: Vector3, columns: int = 4, floors: int = 5) -> void:
	if factory_meshes.is_empty():
		var kit: Node3D = load("res://assets/models/modular_factory_facade/modular_factory_facade_1k.gltf").instantiate()
		for child in kit.find_children("*","MeshInstance3D",true,false):
			factory_meshes[str(child.name)] = child.mesh
			for surface in range(child.mesh.get_surface_count()):
				var material := child.mesh.surface_get_material(surface) as BaseMaterial3D
				if material:
					material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		kit.free()
	var width := columns*3.0
	for side in range(4):
		var yaw := side*PI/2
		var basis := Basis(Vector3.UP,yaw)
		for column in range(columns):
			var anchor := Vector3(-width/2+(column+1)*3,0,width/2)
			_module("base_standard_standard_01",Transform3D(basis,position+basis*anchor))
			for floor_index in range(floors):
				anchor.y = floor_index*3.0
				_module("wall_window_tall_large_01",Transform3D(basis,position+basis*anchor))
				_module("window_tall_large_01",Transform3D(basis,position+basis*anchor))
				anchor.y += 3.0
				_module("cornice01_standard_standard_01",Transform3D(basis,position+basis*anchor))
			anchor.y = floors*3.0
			_module("crown_standard_standard_01",Transform3D(basis,position+basis*anchor))
	# Closed buildings have solid shells; the separate warehouse is fly-through.
	var body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width,floors*3.0,width)
	collider.shape = box
	body.add_child(collider)
	add_child(body)
	body.position = position+Vector3.UP*floors*1.5
	var roof := MeshInstance3D.new()
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(width,0.2,width)
	roof.mesh = roof_mesh
	roof.material_override = pbr("concrete",2)
	add_child(roof)
	roof.position = position+Vector3.UP*floors*3.0

func _module(part: String, transform: Transform3D) -> void:
	if not factory_transforms.has(part):
		factory_transforms[part] = []
	factory_transforms[part].append(transform)

func finish_factory() -> void:
	for part in factory_transforms:
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = factory_meshes[part]
		batch.instance_count = factory_transforms[part].size()
		for i in range(batch.instance_count):
			batch.set_instance_transform(i,factory_transforms[part][i])
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = batch
		instance.visibility_range_end = 650
		instance.visibility_range_end_margin = 40
		add_child(instance)
