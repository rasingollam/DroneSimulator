extends Node3D
## Shared procedural branch meshes with CC0 photographed needle/bark atlases.
var rng := RandomNumberGenerator.new()

func build(field: Node3D) -> void:
	rng.seed = 87461
	var bark := StandardMaterial3D.new()
	bark.albedo_texture = load("res://assets/environment/bark_color.jpg")
	bark.uv1_scale = Vector3(1.5, 1.5, 1.5)
	bark.roughness = 0.98
	bark.cull_mode = BaseMaterial3D.CULL_DISABLED
	var needles := ShaderMaterial.new()
	needles.shader = load("res://assets/shaders/foliage.gdshader")
	needles.set_shader_parameter("leaf_color", load("res://assets/environment/pine_color.jpg"))
	needles.set_shader_parameter("leaf_alpha", load("res://assets/environment/pine_alpha.png"))
	for variant in range(3):
		var wood := SurfaceTool.new()
		var leaves := SurfaceTool.new()
		wood.begin(Mesh.PRIMITIVE_TRIANGLES)
		leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
		_segment(wood, Vector3.ZERO, Vector3(0.15, 11.0, 0.08), 0.20, 0.014)
		for level in range(13):
			var y := 2.1 + level * 0.61
			for branch in range(6):
				var angle := branch * TAU / 6.0 + level * 0.73 + rng.randf_range(-0.18, 0.18)
				var length := (1.0 - y / 12.0) * rng.randf_range(2.7, 3.8)
				var direction := Vector3(cos(angle), 0, sin(angle))
				var origin := Vector3(0.08, y, 0.02)
				var elbow := origin + direction * length * 0.55 + Vector3.DOWN * 0.15
				var tip := origin + direction * length + Vector3.UP * rng.randf_range(0.12, 0.55)
				_segment(wood, origin, elbow, 0.032 * (1.0 - y / 13), 0.015)
				_segment(wood, elbow, tip, 0.015, 0.002)
				for twig in range(9):
					var t := 0.25 + twig / 12.0
					var pos := origin.lerp(tip, t)
					pos += Vector3(-direction.z, 0, direction.x) * rng.randf_range(-0.35, 0.35)
					var tilt := rng.randf_range(-0.6, 0.6)
					var right := Vector3(cos(angle + tilt), 0, sin(angle + tilt))
					var up := (Vector3.UP + direction * rng.randf_range(0.2, 1.0)).normalized()
					var size := rng.randf_range(0.65, 1.15) * (1.05 - y / 25.0)
					_card(leaves, pos, right, up, size * 0.65, size * 1.1)
		wood.generate_tangents()
		var wood_mesh := wood.commit()
		var leaves_mesh := leaves.commit()
		var transforms: Array[Transform3D] = []
		for i in range(52):
			var angle := rng.randf_range(0, TAU)
			var radius := rng.randf_range(92, 190)
			var p := Vector3(cos(angle) * radius, 0, sin(angle) * radius - 15)
			p.y = field._terrain_height(p.x, p.z)
			var size := rng.randf_range(0.7, 1.5)
			var basis := Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3(size, size * rng.randf_range(0.85, 1.15), size))
			transforms.append(Transform3D(basis, p))
			var trunk := StaticBody3D.new()
			var collider := CollisionShape3D.new()
			var capsule := CylinderShape3D.new()
			capsule.radius = 0.20 * size
			capsule.height = 10.0 * size
			collider.shape = capsule
			trunk.add_child(collider)
			add_child(trunk)
			trunk.position = p + Vector3.UP * 5.0 * size
		_instances(wood_mesh, bark, transforms)
		_instances(leaves_mesh, needles, transforms)
	_grass(field)

func _instances(mesh: Mesh, material: Material, transforms: Array[Transform3D]) -> void:
	var instance := MultiMeshInstance3D.new()
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = transforms.size()
	for i in range(transforms.size()):
		batch.set_instance_transform(i, transforms[i])
	instance.multimesh = batch
	instance.material_override = material
	add_child(instance)

func _segment(surface: SurfaceTool, start: Vector3, end: Vector3, r1: float, r2: float) -> void:
	var direction := (end - start).normalized()
	var right := direction.cross(Vector3.FORWARD).normalized()
	if right.length_squared() < 0.5:
		right = Vector3.RIGHT
	var side := direction.cross(right).normalized()
	for i in range(7):
		for point in [Vector2(i, 0), Vector2(i + 1, 0), Vector2(i, 1), Vector2(i + 1, 0), Vector2(i + 1, 1), Vector2(i, 1)]:
			var theta: float = point.x * TAU / 7.0
			var normal := right * cos(theta) + side * sin(theta)
			surface.set_normal(normal)
			surface.set_uv(Vector2(point.x / 7.0, point.y * start.distance_to(end)))
			surface.add_vertex(start.lerp(end, point.y) + normal * lerpf(r1, r2, point.y))

func _card(surface: SurfaceTool, center: Vector3, right: Vector3, up: Vector3, width: float, height: float) -> void:
	for uv in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
		surface.set_normal(right.cross(up).normalized())
		# Only the atlas's photographed vertical needle twig, not its cones/branches.
		surface.set_uv(Vector2(0.008 + uv.x * 0.235, 0.025 + uv.y * 0.420))
		surface.add_vertex(center + right * (uv.x - 0.5) * width + up * (0.5 - uv.y) * height)

func _grass(field: Node3D) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for blade in range(3):
		var angle := blade * PI / 3
		var right := Vector3(cos(angle), 0, sin(angle)) * 0.025
		for uv in [Vector2(0, 0), Vector2(1, 0), Vector2(0.6, 1)]:
			surface.set_normal(Vector3.UP)
			surface.set_uv(uv)
			surface.add_vertex(right * (uv.x - 0.5) * 0.25 + Vector3(0.01 * uv.y, uv.y * 0.08, 0))
	var mesh := surface.commit()
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/shaders/grass.gdshader")
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_custom_data = true
	batch.mesh = mesh
	batch.instance_count = 26000
	var count := 0
	for i in range(32000):
		var p := Vector3(rng.randf_range(-90, 95), 0, rng.randf_range(-105, 75))
		if (p.x > -31 and p.x < -15 and p.z > -121 and p.z < 62) or p.distance_to(Vector3(0, 0, 9)) < 4.2:
			continue
		if (p.x < -36 and p.z > -53 and p.z < -20) or (p.x < -18 and p.z > 24 and p.z < 48):
			continue
		p.y = field._terrain_height(p.x, p.z) - 0.01
		var basis := Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3.ONE * rng.randf_range(0.65, 1.65))
		batch.set_instance_transform(count, Transform3D(basis, p))
		batch.set_instance_custom_data(count, Color(rng.randf(), 0, 0, 1))
		count += 1
		if count == batch.instance_count:
			break
	batch.visible_instance_count = count
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = batch
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
