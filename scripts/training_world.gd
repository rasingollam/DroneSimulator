extends Node3D

var gates: Array[Node3D] = []
var gate_materials: Array[StandardMaterial3D] = []
var pad_position := Vector3(0, 0.0, 9)
var rng := RandomNumberGenerator.new()
var terrain_noise := FastNoiseLite.new()

func _ready() -> void:
	rng.seed = 57291
	terrain_noise.seed = 132
	terrain_noise.frequency = 0.006
	terrain_noise.fractal_octaves = 3
	_environment()
	_terrain()
	_airfield()
	_course()
	_scenery()
	set_active_gate(0)

func mat(hex: String, roughness: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = roughness
	return m

func box(size: Vector3, pos: Vector3, material: Material, collision: bool = false, parent: Node3D = self) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var geometry := BoxMesh.new()
	geometry.size = size
	mesh.mesh = geometry
	mesh.material_override = material
	parent.add_child(mesh)
	mesh.position = pos
	if collision:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var collider := BoxShape3D.new()
		collider.size = size
		shape.shape = collider
		mesh.add_child(body)
		body.add_child(shape)
	return mesh

func cylinder(radius: float, height: float, pos: Vector3, material: Material, parent: Node3D = self, top_radius: float = -1.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius if top_radius < 0.0 else top_radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 16
	mesh.mesh = shape
	mesh.material_override = material
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

func label_3d(text: String, pos: Vector3, size: int = 64, color: Color = Color.WHITE, parent: Node3D = self) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.012
	label.modulate = color
	label.outline_size = 0
	parent.add_child(label)
	label.position = pos
	return label

func _environment() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var panorama := PanoramaSkyMaterial.new()
	panorama.panorama = load("res://assets/environment/daylight.hdr")
	sky.sky_material = panorama
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.background_energy_multiplier = 0.65
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("bacbd6")
	env.ambient_light_energy = 0.42
	env.ssao_enabled = true
	env.ssao_radius = 0.7
	env.ssao_intensity = 1.1
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.fog_enabled = true
	env.fog_light_color = Color("a7b5ba")
	env.fog_density = 0.00065
	env.fog_sky_affect = 0.05
	env_node.environment = env
	add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -36, 0)
	sun.light_color = Color("fff1d9")
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	sun.shadow_bias = 0.025
	sun.directional_shadow_max_distance = 200.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(sun)

func _terrain() -> void:
	var grass := ShaderMaterial.new()
	grass.shader = load("res://assets/shaders/terrain.gdshader")
	grass.set_shader_parameter("grass_color", load("res://assets/environment/grass_color.jpg"))
	grass.set_shader_parameter("grass_normal", load("res://assets/environment/grass_normal.jpg"))
	grass.set_shader_parameter("soil_color", load("res://assets/environment/soil_color.jpg"))
	grass.set_shader_parameter("rock_color", load("res://assets/environment/rock_color.jpg"))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 192
	var step := 5.0
	for z in range(count + 1):
		for x in range(count + 1):
			var px := (x - count / 2.0) * step
			var pz := (z - count / 2.0) * step
			var normal := Vector3(_terrain_height(px - 0.5, pz) - _terrain_height(px + 0.5, pz), 1.0, _terrain_height(px, pz - 0.5) - _terrain_height(px, pz + 0.5)).normalized()
			surface.set_normal(normal)
			surface.set_uv(Vector2(px, pz) * 0.1)
			surface.add_vertex(Vector3(px, _terrain_height(px, pz), pz))
	for z in range(count):
		for x in range(count):
			var a := z * (count + 1) + x
			for index in [a, a + 1, a + count + 1, a + 1, a + count + 2, a + count + 1]:
				surface.add_index(index)
	surface.generate_tangents()
	var terrain := MeshInstance3D.new()
	terrain.mesh = surface.commit()
	terrain.material_override = grass
	add_child(terrain)
	terrain.create_trimesh_collision()

func _terrain_height(x: float, z: float) -> float:
	var distance := Vector2(x, z).length()
	var edge := smoothstep(100.0, 290.0, distance)
	return maxf(0.0, (28.0 + terrain_noise.get_noise_2d(x, z) * 56.0) * edge)

func textured(name: String, scale_uv: float, color: Color = Color.WHITE) -> StandardMaterial3D:
	var material := mat("ffffff")
	material.albedo_texture = load("res://assets/environment/" + name + "_color.jpg")
	material.albedo_color = color
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * scale_uv
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.metallic_specular = 0.18
	if name == "asphalt":
		material.normal_enabled = true
		material.normal_texture = load("res://assets/environment/asphalt_normal.jpg")
		material.normal_scale = 0.45
	return material

func _airfield() -> void:
	var asphalt := textured("asphalt", 0.5, Color("b9bab8"))
	var concrete := textured("soil", 0.45, Color("bbbcb4"))
	var paint := mat("d8d8bf")
	var amber := mat("e1ac54")
	box(Vector3(13, 0.06, 180), Vector3(-23, 0.015, -30), asphalt)
	box(Vector3(31, 0.04, 22), Vector3(-35, 0.01, 36), concrete)
	for z in range(-110, 55, 12):
		box(Vector3(0.22, 0.015, 4.8), Vector3(-23, 0.055, z), paint)
	for x in [-29.0, -17.0]:
		box(Vector3(0.12, 0.01, 175), Vector3(x, 0.055, -30), paint)
	for x in range(5):
		box(Vector3(0.7, 0.02, 5), Vector3(-27 + x * 2, 0.055, 51), paint)
	var runway_number := label_3d("18", Vector3(-23, 0.075, 43), 220, Color("e3e1c9"))
	runway_number.rotation_degrees.x = -90
	cylinder(3.8, 0.045, pad_position + Vector3(0, 0.025, 0), asphalt).create_trimesh_collision()
	var ring := TorusMesh.new()
	ring.inner_radius = 3.2
	ring.outer_radius = 3.3
	var ring_mesh := MeshInstance3D.new()
	ring_mesh.mesh = ring
	ring_mesh.material_override = amber
	add_child(ring_mesh)
	ring_mesh.position = pad_position + Vector3(0, 0.049, 0)
	ring_mesh.scale.y = 0.03
	box(Vector3(0.16, 0.015, 2.4), Vector3(-0.7, 0.055, 9), paint)
	box(Vector3(0.16, 0.015, 2.4), Vector3(0.7, 0.055, 9), paint)
	box(Vector3(1.4, 0.015, 0.16), Vector3(0, 0.055, 9), paint)
	_hangar()
	_clubhouse()
	var steel := mat("68716e", 0.6)

	# Training blocks and slalom poles, all solid.
	for i in range(5):
		var p := Vector3(72, 1.0 + i * 0.35, -12 - i * 11)
		box(Vector3(3, p.y * 2, 3), p, concrete, true)
		box(Vector3(3.05, 0.18, 3.05), p + Vector3(0, p.y - 0.4, 0), amber)
	for i in range(6):
		box(Vector3(0.25, 6, 0.25), Vector3(21 + (i % 2) * 8, 3, -24 - i * 8), amber, true)
	# Windsock is animated in main.gd to agree with the selected wind.
	box(Vector3(0.12, 8, 0.12), Vector3(-10, 4, 23), steel, true)
	var sock := Node3D.new()
	sock.name = "Windsock"
	add_child(sock)
	sock.position = Vector3(-10, 8, 23)
	for i in range(5):
		var band := cylinder(0.38 - i * 0.045, 0.45, Vector3(0, -0.06 * i, i * 0.43), amber if i % 2 == 0 else paint, sock, 0.34 - i * 0.045)
		band.rotation.x = PI / 2.0

func _course() -> void:
	var positions := [Vector3(0, 3, -18), Vector3(0, 4, -48), Vector3(22, 5, -74), Vector3(48, 4, -60), Vector3(54, 3, -26), Vector3(34, 3, 0), Vector3(10, 2.8, 12)]
	var base := mat("273637")
	for i in range(positions.size()):
		var gate := Node3D.new()
		add_child(gate)
		gate.position = positions[i]
		var previous: Vector3 = positions[i - 1] if i > 0 else pad_position
		var incoming: Vector3 = positions[i] - previous
		incoming.y = 0.0
		gate.look_at(gate.position + incoming)
		var light_mat := mat("e9a34c")
		light_mat.emission_enabled = true
		light_mat.emission = Color("e9a34c")
		light_mat.emission_energy_multiplier = 0.025
		gate_materials.append(light_mat)
		for x in [-3.2, 3.2]:
			box(Vector3(0.22, 4.4, 0.28), Vector3(x, 0, 0), base, true, gate)
			box(Vector3(0.24, 4.2, 0.12), Vector3(x, 0, 0.17), light_mat, false, gate)
			box(Vector3(1.0, 0.18, 1.3), Vector3(x, -gate.position.y + 0.09, 0), base, true, gate)
		for y in [-2.2, 2.2]:
			box(Vector3(6.6, 0.22, 0.28), Vector3(0, y, 0), base, true, gate)
			box(Vector3(6.4, 0.24, 0.12), Vector3(0, y, 0.17), light_mat, false, gate)
		label_3d("%02d" % (i + 1), Vector3(0, 2.85, 0), 84, Color("f1e8cf"), gate)
		gates.append(gate)

func set_active_gate(index: int) -> void:
	for i in range(gate_materials.size()):
		var color := Color("58bcad") if i == index else Color("bf8a44")
		gate_materials[i].albedo_color = color
		gate_materials[i].emission = color

func _hangar() -> void:
	var structure := Node3D.new()
	add_child(structure)
	structure.position = Vector3(-54, 0, -37)
	var steel := ShaderMaterial.new()
	steel.shader = load("res://assets/shaders/metal.gdshader")
	steel.set_shader_parameter("base_color", Color("8a9593"))
	var edge := mat("4b5555", 0.58)
	var floor_mat := textured("asphalt", 0.5, Color("c7c7b9"))
	box(Vector3(20, 0.15, 26), Vector3(0, 0.075, 0), floor_mat, true, structure)
	for x in [-10.0, 10.0]:
		box(Vector3(0.20, 6, 26), Vector3(x, 3, 0), steel, true, structure)
	box(Vector3(20, 6, 0.2), Vector3(0, 3, -13), steel, true, structure)
	for x in [-8.0, 8.0]:
		box(Vector3(4, 6, 0.20), Vector3(x, 3, 13), steel, true, structure)
	box(Vector3(12, 1.5, 0.20), Vector3(0, 5.25, 13), steel, true, structure)
	# Curved roof assembled from ribbed solid panels: the interior is flyable.
	for segment in range(20):
		var a := segment * PI / 20
		var b := (segment + 1) * PI / 20
		var p1 := Vector3(cos(a) * 10, 6 + sin(a) * 3.2, 0)
		var p2 := Vector3(cos(b) * 10, 6 + sin(b) * 3.2, 0)
		var roof := box(Vector3(p1.distance_to(p2) + 0.03, 0.14, 26.4), (p1 + p2) * 0.5, steel, true, structure)
		roof.rotation.z = atan2(p2.y - p1.y, p2.x - p1.x)
	for z in range(-12, 14, 4):
		for x in [-9.7, 9.7]:
			box(Vector3(0.16, 6.5, 0.18), Vector3(x, 3.25, z), edge, true, structure)
	label_3d("VECTOR  /  FLIGHT FIELD", Vector3(0, 5.55, 13.16), 50, Color("e3e4dc"), structure)
	# Interior service benches and storage crates, not a solid building block.
	for z in [-8, -2, 4]:
		box(Vector3(2.5, 0.12, 1), Vector3(-7.8, 1, z), edge, true, structure)
		for x in [-8.8, -6.8]:
			box(Vector3(0.08, 1, 0.08), Vector3(x, 0.5, z), edge, true, structure)
		box(Vector3(1.1, 0.7, 0.9), Vector3(7.5, 0.5, z), textured("bark", 0.9), true, structure)
	for i in range(5):
		_cone(Vector3(-63 + i * 4.3, 0, -19))

func _clubhouse() -> void:
	var plaster := textured("soil", 0.65, Color("d7d4bf"))
	var trim := mat("475451")
	box(Vector3(7, 3.3, 7), Vector3(-42, 1.65, 17), plaster, true)
	box(Vector3(7.8, 0.22, 7.8), Vector3(-42, 3.4, 17), trim)
	for x in [-44.0, -40.5]:
		box(Vector3(2.3, 1.35, 0.14), Vector3(x, 2.0, 20.55), trim)
		box(Vector3(2.12, 1.19, 0.02), Vector3(x, 2.0, 20.64), mat("263f4b", 0.15))
		box(Vector3(0.04, 1.2, 0.04), Vector3(x, 2.0, 20.67), mat("a1a89d"))
	box(Vector3(1.1, 2.3, 0.10), Vector3(-38.44, 1.15, 17), trim)
	for position in [Vector3(-44, 1.3, -65), Vector3(-57, 1.3, 4)]:
		var steel := ShaderMaterial.new()
		steel.shader = load("res://assets/shaders/metal.gdshader")
		steel.set_shader_parameter("base_color", Color("5c756e"))
		box(Vector3(2.45, 2.6, 6.1), position, steel, true)
		for x in [-0.55, 0.55]:
			box(Vector3(1.05, 2.35, 0.06), position + Vector3(x, 0, 3.08), mat("526a62"))
			box(Vector3(0.04, 2.2, 0.08), position + Vector3(x, 0, 3.15), mat("a6aaa1"))
	# Low service fence and a weathered picnic table near the control cabin.
	var wood := textured("bark", 0.7)
	box(Vector3(3, 0.10, 0.85), Vector3(-36, 0.85, 25), wood, true)
	for x in [-37.1, -34.9]:
		box(Vector3(0.12, 0.8, 0.8), Vector3(x, 0.4, 25), mat("404846"), true)
	for z in [24.1, 25.9]:
		box(Vector3(3, 0.10, 0.3), Vector3(-36, 0.5, z), wood, true)

func _cone(pos: Vector3) -> void:
	box(Vector3(0.42, 0.055, 0.42), pos + Vector3.UP * 0.028, mat("282a27"), true)
	cylinder(0.16, 0.6, pos + Vector3.UP * 0.35, mat("cf652e"), self, 0.045)
	cylinder(0.105, 0.10, pos + Vector3.UP * 0.43, mat("deddd0"), self, 0.083)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder_shape := CylinderShape3D.new()
	cylinder_shape.radius = 0.13
	cylinder_shape.height = 0.6
	shape.shape = cylinder_shape
	body.add_child(shape)
	add_child(body)
	body.position = pos + Vector3.UP * 0.35

func _scenery() -> void:
	var plants := Node3D.new()
	plants.set_script(load("res://scripts/vegetation.gd"))
	add_child(plants)
	plants.build(self)
	var fence := textured("bark", 0.6, Color("b9b4a2"))
	for z in range(-110, 91, 5):
		box(Vector3(0.14, 1.4, 0.14), Vector3(-82, _terrain_height(-82, z) + 0.7, z), fence, true)
	for y in [0.5, 1.1]:
		box(Vector3(0.09, 0.09, 190), Vector3(-82, y, -10), fence)
	var stone := textured("soil", 0.7, Color("91958f"))
	for i in range(34):
		var rock := SphereMesh.new()
		rock.radial_segments = 16
		rock.rings = 10
		var mesh := MeshInstance3D.new()
		mesh.mesh = rock
		mesh.material_override = stone
		add_child(mesh)
		var p := Vector3(rng.randf_range(-95, 95), 0, rng.randf_range(67, 92))
		p.y = _terrain_height(p.x, p.z) + 0.25
		mesh.position = p
		mesh.rotation = Vector3(rng.randf(), rng.randf() * TAU, rng.randf())
		mesh.scale = Vector3(rng.randf_range(0.7, 2.4), rng.randf_range(0.65, 1.5), rng.randf_range(0.7, 2.4))
		mesh.create_trimesh_collision()
