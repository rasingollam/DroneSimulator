extends RigidBody3D
## SI units: metres, kilograms, seconds, newtons and radians.

signal hard_landing(speed: float)

const ARM := 0.165
const MAX_THRUST := 6.5 # N per motor at nominal voltage
const YAW_COEFFICIENT := 0.018 # reaction torque / thrust, m
const MOTOR_TIME_CONSTANT := 0.045
const MOTOR_POSITIONS := [Vector3(-ARM, 0, -ARM), Vector3(ARM, 0, -ARM), Vector3(-ARM, 0, ARM), Vector3(ARM, 0, ARM)]
const MOTOR_SPINS := [1.0, -1.0, -1.0, 1.0]

var armed := false
var acro := false
var throttle := 0.0
var stick := Vector3.ZERO # pitch, yaw, roll; body axes
var motor_speeds := PackedFloat32Array([0, 0, 0, 0])
var motor_thrusts := PackedFloat32Array([0, 0, 0, 0])
var wind := Vector3.ZERO
var total_thrust := 0.0
var crashed := false
var respawn_requested := false
var spawn_transform := Transform3D(Basis.IDENTITY, Vector3(0, 0.22, 9))
var rate_integral := Vector3.ZERO
var previous_rate := Vector3.ZERO
var derivative_filtered := Vector3.ZERO
var last_velocity := Vector3.ZERO
var rotors: Array[Node3D] = []
var test_input := false
var test_stick := Vector3.ZERO
var remote_active := false
var remote_throttle := 0.0
var remote_stick := Vector3.ZERO

func _ready() -> void:
	mass = 0.8
	inertia = Vector3(0.005, 0.009, 0.005)
	linear_damp = 0.0
	angular_damp = 0.0
	can_sleep = false
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 12
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = 0.65
	physics_material_override.bounce = 0.08
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.42, 0.13, 0.42)
	shape.shape = box
	add_child(shape)
	_build_model()
	global_transform = spawn_transform

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var dt := state.step
	if respawn_requested:
		state.transform = spawn_transform
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		last_velocity = Vector3.ZERO
		previous_rate = Vector3.ZERO
		derivative_filtered = Vector3.ZERO
		respawn_requested = false
		return
	var body_basis := state.transform.basis
	var rate := body_basis.transposed() * state.angular_velocity
	if state.get_contact_count() > 0 and last_velocity.length() > 3.8 and not crashed:
		crashed = true
		set_armed(false)
		hard_landing.emit(last_velocity.length())
	last_velocity = state.linear_velocity
	if remote_active:
		throttle = remote_throttle if armed else 0.0
		stick = stick.lerp(remote_stick, 1.0 - exp(-dt / 0.025))
	elif not test_input:
		if armed:
			throttle = clampf(throttle + (float(Input.is_physical_key_pressed(KEY_W)) - float(Input.is_physical_key_pressed(KEY_S))) * 0.30 * dt, 0.0, 1.0)
		var raw := Vector3(float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP)), float(Input.is_physical_key_pressed(KEY_A)) - float(Input.is_physical_key_pressed(KEY_D)), float(Input.is_physical_key_pressed(KEY_LEFT)) - float(Input.is_physical_key_pressed(KEY_RIGHT)))
		stick = stick.lerp(raw, 1.0 - exp(-dt / 0.12))
	else:
		stick = test_stick
	var desired_rate := stick * Vector3(4.2, 2.8, 4.2)
	if not acro:
		# Desired up vector expressed in body coordinates: no altitude/position hold.
		var level_up := body_basis.transposed() * Vector3.UP
		desired_rate.x = clampf((level_up.z + stick.x * sin(deg_to_rad(30.0))) * 6.0, -4.2, 4.2)
		desired_rate.z = clampf((-level_up.x + stick.z * sin(deg_to_rad(30.0))) * 6.0, -4.2, 4.2)
	var error := desired_rate - rate
	if armed and throttle > 0.08 and state.get_contact_count() == 0:
		rate_integral += error * dt
		rate_integral = rate_integral.clamp(Vector3.ONE * -0.8, Vector3.ONE * 0.8)
	else:
		rate_integral = Vector3.ZERO
	var derivative := (rate - previous_rate) / dt
	previous_rate = rate
	derivative_filtered = derivative_filtered.lerp(derivative, 1.0 - exp(-dt * 35.0))
	var torque := error * Vector3(0.075, 0.10, 0.075) + rate_integral * Vector3(0.035, 0.045, 0.035) - derivative_filtered * Vector3(0.0018, 0.001, 0.0018)
	var collective := 4.0 * MAX_THRUST * throttle * throttle
	total_thrust = 0.0
	for i in range(4):
		var p: Vector3 = MOTOR_POSITIONS[i]
		var target_thrust: float = collective / 4.0 - p.z * torque.x / (4.0 * ARM * ARM) + p.x * torque.z / (4.0 * ARM * ARM) + MOTOR_SPINS[i] * torque.y / (4.0 * YAW_COEFFICIENT)
		var target_speed := sqrt(clampf(target_thrust / MAX_THRUST, 0.0, 1.0)) if armed else 0.0
		motor_speeds[i] = lerpf(motor_speeds[i], target_speed, 1.0 - exp(-dt / MOTOR_TIME_CONSTANT))
		motor_thrusts[i] = MAX_THRUST * motor_speeds[i] * motor_speeds[i]
		total_thrust += motor_thrusts[i]
		state.apply_force(body_basis.y * motor_thrusts[i], body_basis * p)
		state.apply_torque(body_basis.y * MOTOR_SPINS[i] * motor_thrusts[i] * YAW_COEFFICIENT)
	# Quadratic body drag relative to the air. Gravity and contacts stay engine-driven.
	var relative_air := body_basis.transposed() * (state.linear_velocity - wind)
	var drag := -0.5 * 1.225 * Vector3(0.035, 0.075, 0.035) * relative_air * relative_air.abs()
	state.apply_central_force(body_basis * drag)
	state.apply_torque(body_basis * (-rate * rate.abs() * Vector3(0.0006, 0.001, 0.0006)))

func _process(delta: float) -> void:
	for i in range(rotors.size()):
		rotors[i].rotate_y(motor_speeds[i] * MOTOR_SPINS[i] * 260.0 * delta)

func set_armed(value: bool) -> void:
	armed = value and not crashed
	throttle = 0.0
	rate_integral = Vector3.ZERO

func reset_drone() -> void:
	set_armed(false)
	crashed = false
	stick = Vector3.ZERO
	motor_speeds.fill(0.0)
	motor_thrusts.fill(0.0)
	total_thrust = 0.0
	respawn_requested = true

func _material(color: Color, metal: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metal
	mat.roughness = 0.55
	return mat

func _part(size: Vector3, pos: Vector3, mat: Material, parent: Node3D = self) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = mat
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

func _build_model() -> void:
	var carbon := _material(Color("171d22"), 0.55)
	var accent := _material(Color("51e1c3"), 0.25)
	var dark := _material(Color("080c10"))
	_part(Vector3(0.12, 0.065, 0.24), Vector3.ZERO, carbon)
	_part(Vector3(0.075, 0.055, 0.13), Vector3(0, 0.055, 0.025), dark)
	for angle in [-PI / 4.0, PI / 4.0]:
		var arm := _part(Vector3(0.035, 0.025, 0.48), Vector3.ZERO, carbon)
		arm.rotation.y = angle
	for i in range(4):
		var p: Vector3 = MOTOR_POSITIONS[i]
		var motor := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.016
		cylinder.bottom_radius = 0.019
		cylinder.height = 0.032
		motor.mesh = cylinder
		motor.material_override = accent if p.z < 0.0 else carbon
		add_child(motor)
		motor.position = p + Vector3(0, 0.02, 0)
		var rotor := Node3D.new()
		add_child(rotor)
		rotor.position = p + Vector3(0, 0.04, 0)
		_part(Vector3(0.229, 0.003, 0.018), Vector3.ZERO, accent if p.z < 0.0 else dark, rotor)
		rotors.append(rotor)
	_part(Vector3(0.065, 0.035, 0.028), Vector3(0, 0.005, -0.135), dark)
	for x in [-0.07, 0.07]:
		_part(Vector3(0.016, 0.07, 0.12), Vector3(x, -0.055, 0), carbon)
