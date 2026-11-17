extends SceneTree

const Drone = preload("res://scripts/drone.gd")
var failures := 0
var craft: RigidBody3D
var wind_speeds := {}

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ", label)
	if not value:
		failures += 1

func steps(count: int) -> void:
	for i in range(count):
		await physics_frame

func fresh(inches: int) -> void:
	if is_instance_valid(craft):
		craft.queue_free()
		await process_frame
	craft = RigidBody3D.new()
	craft.set_script(Drone)
	craft.inches = inches
	craft.spawn_transform.origin = Vector3(0, 50, 0)
	root.add_child(craft)
	craft.test_input = true
	await steps(3)

func run() -> void:
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(300, 1, 300)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	floor_body.position.y = -0.5
	root.add_child(floor_body)
	for inches in [2, 3, 4, 5]:
		await fresh(inches)
		var label := '%d-inch: ' % inches
		check(is_equal_approx(craft.mass, float(craft.profile.mass)) and craft.inertia.is_equal_approx(craft.profile.inertia), label + "selected physical mass and inertia applied")
		check(craft.ARM * 2.0 > inches * 0.0254, label + "propeller discs have physical clearance")
		craft.set_armed(true)
		craft.throttle = craft.hover_throttle()
		await steps(400)
		check(absf(craft.total_thrust - craft.mass * 9.80665) < 0.02, label + "motor thrust balances weight at calculated hover")
		check(absf(craft.linear_velocity.y) < 0.85 and craft.angular_velocity.length() < 0.03, label + "stable level hover after spool-up")
		check(not craft.configure(2 if inches != 2 else 5), label + "armed airframe changes rejected")
		craft.test_stick = Vector3(-0.45, 0, 0)
		await steps(180)
		check(craft.rotation.x < -0.08 and craft.linear_velocity.z < -0.4, label + "motor torque produces forward pitch and acceleration")
		craft.test_stick = Vector3.ZERO
		await steps(400)
		check(absf(craft.rotation.x) < 0.03, label + "profile-tuned controller self-levels")
		craft.set_armed(false)
		check(craft.configure(inches), label + "disarmed selection succeeds")
		await steps(3)
		check(craft.linear_velocity.length() < 0.2 and craft.motor_speeds[0] == 0, label + "switch clears old momentum and motor state")
		craft.wind = Vector3(5, 0, 0)
		await steps(180)
		wind_speeds[inches] = craft.linear_velocity.x
		craft.wind = Vector3.ZERO
		craft.reset_drone()
		await steps(3)
		craft.set_armed(true)
		craft.acro = true
		craft.throttle = craft.hover_throttle()
		craft.test_stick = Vector3(0, -0.4, -0.4)
		await steps(60)
		check(craft.angular_velocity.y < -0.3 and craft.rotation.z < -0.05, label + "yaw and roll directions remain correct")
		craft.test_stick = Vector3.ZERO
		await steps(300)
		check(craft.angular_velocity.length() < 0.2 and absf(craft.rotation.z) > 0.05, label + "Acro retains tilt after rate settles")
		craft.spawn_transform.origin = Vector3(0, 3, 0)
		craft.reset_drone()
		await steps(300)
		check(craft.crashed and not craft.armed and craft.position.y > 0, label + "small-frame CCD impact is detected and ground remains solid")
	check(wind_speeds[2] > wind_speeds[5], "Micro has a larger wind response per mass than the 5-inch build")
	craft.queue_free()
	await process_frame
	print("PROFILE TESTS: ", "ALL PASSED" if failures == 0 else str(failures) + " FAILED")
	quit(0 if failures == 0 else 1)
