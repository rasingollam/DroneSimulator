extends Node3D

var rotors: Array[Node3D] = []
var discs: Array[MeshInstance3D] = []
var profile: Dictionary
var prop_diameter := 0.127

func material(color: Color, metallic: float = 0.0, roughness: float = 0.55) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m

func box(size: Vector3, pos: Vector3, mat: Material, parent: Node3D = self) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.material_override = mat
	parent.add_child(part)
	part.position = pos
	return part

func cylinder(radius: float, height: float, pos: Vector3, mat: Material, parent: Node3D = self, top: float = -1) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius if top < 0 else top
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	part.mesh = mesh
	part.material_override = mat
	parent.add_child(part)
	part.position = pos
	return part

func build(inches: int, p: Dictionary) -> void:
	profile = p
	prop_diameter = inches * 0.0254
	var s: float = p.wheelbase / 0.245
	var arm: float = p.wheelbase / (2.0 * sqrt(2.0))
	var carbon := material(Color("202629"), 0.38, 0.62)
	var rubber := material(Color("121518"), 0, 0.95)
	var alloy := material(Color("69737b"), 0.82, 0.28)
	var accent := material(p.color, 0.30, 0.40)
	var battery := material(Color("292d30"), 0.12, 0.40)
	var lens := material(Color("132b3c"), 0.60, 0.08)
	# Thin carbon plates, replaceable arms and standoffs, all at physical scale.
	box(Vector3(0.042, 0.004, 0.115) * s, Vector3(0, -0.004, 0) * s, carbon)
	box(Vector3(0.035, 0.003, 0.086) * s, Vector3(0, 0.024, 0) * s, carbon)
	for angle in [-PI / 4.0, PI / 4.0]:
		var beam := box(Vector3(0.012, 0.005, p.wheelbase + 0.012 * s), Vector3.ZERO, carbon)
		beam.rotation.y = angle
	for x in [-0.014, 0.014]:
		for z in [-0.032, 0.032]:
			cylinder(0.0024 * s, 0.025 * s, Vector3(x, 0.01, z) * s, accent)
			cylinder(0.0027 * s, 0.002 * s, Vector3(x, 0.027, z) * s, alloy)
	var pack: Vector3 = p.battery_size
	var pack_y := 0.027 * s + pack.y * 0.5
	box(pack, Vector3(0, pack_y, 0.008 * s), battery)
	box(Vector3(pack.x * 0.92, 0.0007, pack.z * 0.70), Vector3(0, pack_y + pack.y * 0.5 + 0.0005, 0.008 * s), material(Color("c7c4b7")))
	for z in [-pack.z * 0.23, pack.z * 0.23]:
		box(Vector3(pack.x + 0.002, pack.y + 0.002, 0.005 * s), Vector3(0, pack_y, z + 0.008 * s), rubber)
		box(Vector3(0.008, 0.002, 0.006) * s, Vector3(pack.x * 0.32, pack_y + pack.y * 0.5 + 0.002, z + 0.008 * s), alloy)
	# Camera cage, visible lens, antenna and rear power lead.
	box(Vector3(0.025, 0.021, 0.020) * s, Vector3(0, 0.012, -0.049) * s, accent)
	var glass := cylinder(0.008 * s, 0.008 * s, Vector3(0, 0.013, -0.062) * s, lens)
	glass.rotation.x = PI / 2.0
	var antenna := cylinder(0.0013 * s, 0.07 * s, Vector3(0, 0.028, 0.067) * s, rubber)
	antenna.rotation.x = 0.40
	cylinder(0.006 * s, 0.007 * s, Vector3(0, 0.060, 0.081) * s, accent)
	box(Vector3(0.006, 0.006, 0.020) * s, Vector3(0.014, 0.029, 0.052) * s, material(Color("9f2924")))
	if inches == 4:
		box(Vector3(0.018, 0.009, 0.019) * s, Vector3(0, 0.04, 0.055) * s, material(Color("d7d4c6")))
	for i in range(4):
		var pos := Vector3(-arm if i % 2 == 0 else arm, 0, -arm if i < 2 else arm)
		cylinder(0.014 * s, 0.010 * s, pos + Vector3(0, 0.006 * s, 0), alloy)
		cylinder(0.013 * s, 0.010 * s, pos + Vector3(0, 0.014 * s, 0), accent if i < 2 else carbon)
		for vent in range(6):
			var theta := vent * TAU / 6
			box(Vector3(0.004, 0.007, 0.003) * s, pos + Vector3(cos(theta) * 0.010, 0.017, sin(theta) * 0.010) * s, rubber)
		var rotor := Node3D.new()
		add_child(rotor)
		rotor.position = pos + Vector3(0, 0.021 * s, 0)
		rotors.append(rotor)
		for blade in range(int(p.blades)):
			var leaf := MeshInstance3D.new()
			leaf.mesh = _blade(prop_diameter, s)
			leaf.material_override = accent if i < 2 else material(Color("535b61"), 0.1, 0.42)
			rotor.add_child(leaf)
			var theta := blade * TAU / int(p.blades)
			leaf.rotation.y = theta
		cylinder(0.0035 * s, 0.006 * s, Vector3(0, 0.002, 0) * s, alloy, rotor)
		var disc_mat := material(Color(p.color, 0.13), 0, 0.7)
		disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		disc_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var disc := cylinder(prop_diameter * 0.5, 0.0005, rotor.position, disc_mat)
		disc.visible = false
		disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		discs.append(disc)

func _blade(diameter: float, size: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for section in range(10):
		for side in [-1.0, 1.0]:
			var vertices := [Vector2(section, 0), Vector2(section, 1), Vector2(section + 1, 0), Vector2(section + 1, 0), Vector2(section, 1), Vector2(section + 1, 1)]
			if side < 0:
				vertices.reverse()
			for v in vertices:
				var t: float = v.x / 10.0
				var chord := diameter * (0.016 + 0.085 * pow(sin(t * PI), 0.6))
				var sweep := diameter * (0.06 * sin(t * PI) - 0.025 * t)
				var twist := lerpf(0.34, 0.08, t)
				var lateral: float = (v.y - 0.5) * chord
				surface.set_uv(Vector2(t, v.y))
				surface.add_vertex(Vector3(sweep + lateral, lateral * sin(twist) + side * 0.00035 * size, diameter * (0.04 + 0.46 * t)))
	surface.generate_normals()
	return surface.commit()

func animate(speeds: PackedFloat32Array, spins: Array, delta: float) -> void:
	for i in range(rotors.size()):
		rotors[i].rotate_y(speeds[i] * float(spins[i]) * 250 * delta)
		discs[i].visible = speeds[i] > 0.12
