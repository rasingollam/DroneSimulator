extends SceneTree
## Run with Godot --headless --path . --script tests/physics_test.gd

const DroneScript = preload("res://scripts/drone.gd")
var drone: RigidBody3D
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1

func steps(count: int) -> void:
	for i in range(count):
		await physics_frame

func fresh(altitude: float = 50.0) -> void:
	if is_instance_valid(drone):
		drone.queue_free()
		await process_frame
	drone = RigidBody3D.new()
	drone.set_script(DroneScript)
	drone.spawn_transform.origin = Vector3(0, altitude, 0)
	root.add_child(drone)
	drone.test_input = true
	await steps(2)

func run() -> void:
	await fresh()
	var start := drone.position.y
	await steps(120)
	check(drone.linear_velocity.y < -4.5 and drone.position.y < start - 1.0, "Disarmed drone falls under gravity")
	check(is_zero_approx(drone.total_thrust), "Disarmed motors produce zero thrust")

	await fresh()
	drone.set_armed(true)
	drone.throttle = sqrt(drone.mass * 9.80665 / (4.0 * drone.MAX_THRUST))
	await steps(480)
	check(absf(drone.linear_velocity.y) < 0.85, "Analytical hover power balances weight after motor spool-up")
	check(absf(drone.total_thrust - drone.mass * 9.80665) < 0.08, "Four motor forces sum to weight at level hover")
	check(drone.angular_velocity.length() < 0.02, "Symmetric motor thrust creates no spurious rotation")

	await fresh()
	drone.set_armed(true)
	drone.throttle = 0.72
	await steps(180)
	check(drone.linear_velocity.y > 3.0, "Above-hover thrust climbs")
	check(drone.motor_speeds[0] <= 0.721, "Motor spool remains bounded")
	drone.set_armed(false)
	await steps(120)
	check(drone.total_thrust < 0.01 and drone.throttle == 0, "Disarm cuts power and clears throttle")

	await fresh()
	drone.set_armed(true)
	drone.throttle = 0.58
	drone.test_stick = Vector3(-0.5, 0, 0)
	await steps(300)
	check(drone.rotation.x < -0.10 and drone.linear_velocity.z < -0.8, "Forward pitch tilts nose down and accelerates forward")
	drone.test_stick = Vector3.ZERO
	await steps(480)
	check(absf(drone.rotation.x) < 0.025, "Angle mode returns to level when pitch is released")
	check(absf(drone.linear_velocity.z) > 0.1, "Leveling does not unrealistically stop horizontal momentum")

	await fresh()
	drone.set_armed(true)
	drone.throttle = 0.58
	drone.test_stick = Vector3(0, -0.5, 0)
	await steps(240)
	check(drone.angular_velocity.y < -0.8, "Right yaw is produced by differential motor reaction torque")

	await fresh()
	drone.set_armed(true)
	drone.throttle = 0.58
	drone.test_stick = Vector3(0, 0, -0.5)
	await steps(240)
	check(drone.rotation.z < -0.10 and drone.linear_velocity.x > 0.5, "Right roll banks right and accelerates right")

	await fresh()
	drone.set_armed(true)
	drone.acro = true
	drone.throttle = 0.58
	drone.test_stick = Vector3(-0.4, 0, 0)
	await steps(60)
	drone.test_stick = Vector3.ZERO
	await steps(300)
	check(absf(drone.rotation.x) > 0.15 and drone.angular_velocity.length() < 0.15, "Acro release stops rotation while preserving tilt")

	await fresh()
	drone.wind = Vector3(5, 0, 0)
	await steps(240)
	check(drone.linear_velocity.x > 0.1, "Wind acts through relative-air drag")
	drone.reset_drone()
	await steps(3)
	check(not drone.armed and drone.throttle == 0 and not drone.crashed, "Reset restores safe disarmed state")
	check(drone.position.distance_to(drone.spawn_transform.origin) < 0.01, "Reset restores spawn through physics state")

	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position.y = -0.5
	root.add_child(floor_body)
	await fresh(3.0)
	await steps(300)
	check(drone.crashed and not drone.armed, "Hard contact detects crash and disarms")
	check(drone.position.y > 0.0, "Solid ground prevents falling through the field")
	print("PHYSICS TESTS: ", "ALL PASSED" if failures == 0 else str(failures) + " FAILED")
	quit(0 if failures == 0 else 1)
