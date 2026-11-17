extends RigidBody3D
## SI units. Independent motor forces; no scripted airborne translation/rotation.
signal hard_landing(speed: float)
const Profiles = preload("res://scripts/drone_profiles.gd")
const Visual = preload("res://scripts/drone_visual.gd")
const MOTOR_SPINS := [1.0, -1.0, -1.0, 1.0]

var inches := 5
var profile: Dictionary
var ARM := 0.0866
var MAX_THRUST := 12.5
var MOTOR_TIME_CONSTANT := 0.045
var YAW_COEFFICIENT := 0.014
var MOTOR_POSITIONS: Array[Vector3] = []
var armed := false
var acro := false
var throttle := 0.0
var stick := Vector3.ZERO
var motor_speeds := PackedFloat32Array([0, 0, 0, 0])
var motor_thrusts := PackedFloat32Array([0, 0, 0, 0])
var wind := Vector3.ZERO
var total_thrust := 0.0
var crashed := false
var respawn_requested := false
var spawn_transform := Transform3D(Basis.IDENTITY, Vector3(0, 0.18, 9))
var rate_integral := Vector3.ZERO
var previous_rate := Vector3.ZERO
var derivative_filtered := Vector3.ZERO
var last_velocity := Vector3.ZERO
var test_input := false
var test_stick := Vector3.ZERO
var remote_active := false
var remote_throttle := 0.0
var remote_stick := Vector3.ZERO
var visual: Node3D
var frame_collision: CollisionShape3D
var battery_collision: CollisionShape3D
var ground_effect := 1.0
var ground_reference := 0.0475
var contact_speed_history := PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0])
var contact_history_index := 0

func _ready() -> void:
	linear_damp = 0.0
	angular_damp = 0.0
	can_sleep = false
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 12
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = 0.65
	physics_material_override.bounce = 0.0
	frame_collision = CollisionShape3D.new()
	frame_collision.shape = BoxShape3D.new()
	frame_collision.shape.margin = 0.0005
	add_child(frame_collision)
	battery_collision = CollisionShape3D.new()
	battery_collision.shape = BoxShape3D.new()
	battery_collision.shape.margin = 0.0005
	add_child(battery_collision)
	configure(inches)
	global_transform = spawn_transform
	respawn_requested = false

func configure(size_inches: int) -> bool:
	if armed or size_inches not in Profiles.DATA:
		return false
	inches = size_inches
	profile = Profiles.get_profile(inches)
	mass = profile.mass
	inertia = profile.inertia
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, 0.017 * profile.wheelbase / 0.245, 0)
	ARM = profile.wheelbase / (2.0 * sqrt(2.0))
	MAX_THRUST = profile.thrust
	MOTOR_TIME_CONSTANT = profile.tau
	YAW_COEFFICIENT = profile.yaw_k
	MOTOR_POSITIONS = [Vector3(-ARM, 0, -ARM), Vector3(ARM, 0, -ARM), Vector3(-ARM, 0, ARM), Vector3(ARM, 0, ARM)]
	(frame_collision.shape as BoxShape3D).size = Vector3(2.0 * ARM + inches * 0.003, profile.body_height, 2.0 * ARM + inches * 0.003)
	(battery_collision.shape as BoxShape3D).size = profile.battery_size
	battery_collision.position = Vector3(0, 0.027 * profile.wheelbase / 0.245 + profile.battery_size.y * 0.5, 0.008 * profile.wheelbase / 0.245)
	if is_instance_valid(visual):
		remove_child(visual)
		visual.queue_free()
	visual = Node3D.new()
	visual.set_script(Visual)
	add_child(visual)
	visual.build(inches, profile)
	reset_drone()
	return true

func hover_throttle() -> float:
	return sqrt(mass * 9.80665 / (4.0 * MAX_THRUST))

func height_above_pad() -> float:
	return maxf(0.0, global_position.y - (ground_reference + float(profile.body_height) * 0.5))

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var dt := state.step
	if respawn_requested:
		state.transform = spawn_transform
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		last_velocity = Vector3.ZERO
		previous_rate = Vector3.ZERO
		derivative_filtered = Vector3.ZERO
		contact_speed_history.fill(0.0)
		respawn_requested = false
		return
	var body_basis := state.transform.basis
	var rate := body_basis.transposed() * state.angular_velocity
	# CCD may remove speed a frame before contact reporting. Keep 33 ms of history.
	var impact_speed := maxf(state.linear_velocity.length(), contact_speed_history[0])
	for speed in contact_speed_history:
		impact_speed = maxf(impact_speed, speed)
	if state.get_contact_count() > 0 and impact_speed > 3.8 and not crashed:
		crashed = true
		set_armed(false)
		hard_landing.emit(impact_speed)
	last_velocity = state.linear_velocity
	contact_speed_history[contact_history_index] = last_velocity.length()
	contact_history_index = (contact_history_index + 1) % contact_speed_history.size()
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
	# Common rates make size comparisons fair; inertia, authority and spool differ.
	var desired_rate := stick * Vector3(4.2, 2.8, 4.2)
	if not acro:
		var level_up := body_basis.transposed() * Vector3.UP
		desired_rate.x = clampf((level_up.z + stick.x * 0.5) * 6.0, -4.2, 4.2)
		desired_rate.z = clampf((-level_up.x + stick.z * 0.5) * 6.0, -4.2, 4.2)
	var error := desired_rate - rate
	if armed and throttle > 0.08 and state.get_contact_count() == 0:
		rate_integral = (rate_integral + error * dt).clamp(-Vector3.ONE * 0.8, Vector3.ONE * 0.8)
	else:
		rate_integral = Vector3.ZERO
	var derivative := (rate - previous_rate) / dt
	previous_rate = rate
	derivative_filtered = derivative_filtered.lerp(derivative, 1.0 - exp(-dt * 45.0))
	# Torque gains scale with the actual inertia tensor (Nm per control error).
	var torque := inertia * (error * 18.0 + rate_integral * 6.0 - derivative_filtered * 0.18)
	var collective := 4.0 * MAX_THRUST * throttle * throttle
	# Bounded rotor/ground interaction approximation, measured by a world ray.
	ground_effect = 1.0
	if body_basis.y.dot(Vector3.UP) > 0.8:
		var radius := inches * 0.0254 * 0.5
		var origin: Vector3 = state.transform.origin + body_basis.y * (0.021 * profile.wheelbase / 0.245)
		var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * radius * 4.0)
		query.exclude = [get_rid()]
		var hit := state.get_space_state().intersect_ray(query)
		if not hit.is_empty():
			var clearance := maxf(radius * 0.55, origin.distance_to(hit.position))
			ground_effect = clampf(1.0 / (1.0 - pow(radius / (4.0 * clearance), 2.0)), 1.0, 1.15)
	total_thrust = 0.0
	for i in range(4):
		var p := MOTOR_POSITIONS[i]
		var target: float = collective / 4.0 - p.z * torque.x / (4.0 * ARM * ARM) + p.x * torque.z / (4.0 * ARM * ARM) + MOTOR_SPINS[i] * torque.y / (4.0 * YAW_COEFFICIENT)
		# Motor-stop at zero throttle prevents the rate controller fighting the floor.
		var target_speed := sqrt(clampf(target / MAX_THRUST, 0.0, 1.0)) if armed and throttle > 0.001 else 0.0
		motor_speeds[i] = lerpf(motor_speeds[i], target_speed, 1.0 - exp(-dt / MOTOR_TIME_CONSTANT))
		var aerodynamic_thrust := MAX_THRUST * motor_speeds[i] * motor_speeds[i]
		motor_thrusts[i] = aerodynamic_thrust * ground_effect
		total_thrust += motor_thrusts[i]
		state.apply_force(body_basis.y * motor_thrusts[i], body_basis * p)
		state.apply_torque(body_basis.y * MOTOR_SPINS[i] * aerodynamic_thrust * YAW_COEFFICIENT)
	var air := body_basis.transposed() * (state.linear_velocity - wind)
	var drag: Vector3 = -0.5 * 1.225 * profile.drag * air * air.abs()
	# Effective rotor-plane drag: a bounded low-speed blade-flapping approximation.
	drag -= Vector3(air.x, 0, air.z) * total_thrust * 0.015
	state.apply_central_force(body_basis * drag)
	state.apply_torque(body_basis * (-rate * rate.abs() * inertia * 0.12))

func _process(delta: float) -> void:
	visual.animate(motor_speeds, MOTOR_SPINS, delta)

func set_armed(value: bool) -> void:
	armed = value and not crashed
	throttle = 0.0
	rate_integral = Vector3.ZERO

func reset_drone() -> void:
	set_armed(false)
	crashed = false
	stick = Vector3.ZERO
	remote_throttle = 0.0
	remote_stick = Vector3.ZERO
	motor_speeds.fill(0.0)
	motor_thrusts.fill(0.0)
	total_thrust = 0.0
	respawn_requested = true
