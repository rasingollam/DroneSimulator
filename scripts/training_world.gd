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
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("477d9b")
	sky_mat.sky_horizon_color = Color("c9d8d9")
	sky_mat.ground_bottom_color = Color("4e5a48")
	sky_mat.ground_horizon_color = Color("c5d3d1")
	sky_mat.sky_curve = 0.18
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color("c8dce6")
	env.ambient_light_energy = 0.38
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.fog_enabled = true
	env.fog_light_color = Color("b5cbce")
	env.fog_density = 0.0015
	env_node.environment = env
	add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-34, -32, 0)
	sun.light_color = Color("fff0d6")
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 180.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(sun)

func _terrain() -> void:
	var ground_shader := Shader.new()
	ground_shader.code = """shader_type spatial;
varying vec3 world;
void vertex(){ world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
float hash(vec2 p){ return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p){ vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f); return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y); }
void fragment(){ float n=noise(world.xz*0.09)*0.65+noise(world.xz*1.8)*0.2+noise(world.xz*15.0)*0.15; vec3 a=vec3(0.19,0.25,0.12); vec3 b=vec3(0.37,0.41,0.23); ALBEDO=mix(a,b,n); ROUGHNESS=1.0; }
"""
	var grass := ShaderMaterial.new()
	grass.shader = ground_shader
	box(Vector3(1000, 0.5, 1000), Vector3(0, -0.25, 0), grass, true)
	# Rolling perimeter terrain leaves the central training field flat.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 128
	var step := 8.0
	for z in range(count):
		for x in range(count):
			for offset in [Vector2(0, 0), Vector2(0, 1), Vector2(1, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
				var px: float = (x + offset.x - count / 2.0) * step
				var pz: float = (z + offset.y - count / 2.0) * step
				surface.add_vertex(Vector3(px, _terrain_height(px, pz), pz))
	surface.generate_normals()
	var terrain := MeshInstance3D.new()
	terrain.mesh = surface.commit()
	terrain.material_override = grass
	add_child(terrain)
	terrain.create_trimesh_collision()

func _terrain_height(x: float, z: float) -> float:
	var edge := smoothstep(100.0, 280.0, Vector2(x, z).length())
	return maxf(-0.03, (24.0 + terrain_noise.get_noise_2d(x, z) * 65.0) * edge - 0.03)

func _airfield() -> void:
	var asphalt := mat("393f40")
	var concrete := mat("92958a")
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
	cylinder(3.8, 0.045, pad_position + Vector3(0, 0.025, 0), asphalt)
	var ring := TorusMesh.new()
	ring.inner_radius = 3.2
	ring.outer_radius = 3.3
	var ring_mesh := MeshInstance3D.new()
	ring_mesh.mesh = ring
	ring_mesh.material_override = amber
	add_child(ring_mesh)
	ring_mesh.position = pad_position + Vector3(0, 0.055, 0)
	box(Vector3(0.16, 0.015, 2.4), Vector3(-0.7, 0.055, 9), paint)
	box(Vector3(0.16, 0.015, 2.4), Vector3(0.7, 0.055, 9), paint)
	box(Vector3(1.4, 0.015, 0.16), Vector3(0, 0.055, 9), paint)
	# Hangar, corrugated roof, control cabin and collision geometry.
	var steel := mat("65716c", 0.6)
	var dark := mat("252e31")
	box(Vector3(20, 9, 26), Vector3(-54, 4.5, -37), steel, true)
	box(Vector3(16, 7, 0.1), Vector3(-54, 3.5, -23.9), dark)
	for x in range(-64, -43, 2):
		box(Vector3(0.10, 9.2, 26.3), Vector3(x, 4.65, -37), mat("77817a"))
	box(Vector3(21, 0.3, 27), Vector3(-54, 9.2, -37), dark)
	label_3d("VECTOR  /  FIELD 01", Vector3(-54, 8.1, -23.7), 64, Color("e0e1d3"))
	box(Vector3(7, 4, 7), Vector3(-42, 2, 17), concrete, true)
	box(Vector3(7.2, 0.3, 7.2), Vector3(-42, 4.1, 17), dark)
	box(Vector3(5.8, 1.2, 0.04), Vector3(-42, 2.9, 20.53), mat("384f59", 0.25))
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
		light_mat.emission_energy_multiplier = 0.3
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
		var color := Color("66f0d0") if i == index else Color("d59c52")
		gate_materials[i].albedo_color = color
		gate_materials[i].emission = color

func _scenery() -> void:
	var trunk := mat("5b5141")
	var leaf_mats := [mat("3f5540"), mat("506144"), mat("63704c")]
	for i in range(185):
		var angle := rng.randf_range(0, TAU)
		var radius := rng.randf_range(98, 240)
		var p := Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		p.y = _terrain_height(p.x, p.z)
		var height := rng.randf_range(5, 12)
		cylinder(0.22, height * 0.6, p + Vector3.UP * height * 0.3, trunk).create_trimesh_collision()
		for layer in range(3):
			cylinder(height * (0.25 - layer * 0.05), height * 0.45, p + Vector3.UP * height * (0.48 + layer * 0.20), leaf_mats[i % 3], self, 0.0).create_trimesh_collision()
	var fence := mat("7c8175")
	for z in range(-110, 91, 5):
		box(Vector3(0.14, 1.4, 0.14), Vector3(-82, 0.7, z), fence, true)
	for y in [0.5, 1.1]:
		box(Vector3(0.09, 0.09, 200), Vector3(-82, y, -10), fence)
	var stone := mat("777a69")
	for i in range(26):
		var mesh := MeshInstance3D.new()
		var rock := SphereMesh.new()
		rock.radial_segments = 7
		rock.rings = 4
		mesh.mesh = rock
		mesh.material_override = stone
		add_child(mesh)
		mesh.position = Vector3(rng.randf_range(-95, 95), 0.5, rng.randf_range(65, 92))
		mesh.scale = Vector3(rng.randf_range(1, 3), rng.randf_range(1, 2), rng.randf_range(1, 3))
		mesh.create_trimesh_collision()
