extends SceneTree
## Regression: small airframes must rest quietly and still lift off normally.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ", label)
	if not value:
		failures += 1

func steps(count: int) -> void:
	for i in range(count):
		await physics_frame

func run() -> void:
	var sim = load("res://scenes/main.tscn").instantiate()
	sim.set_meta("controller_port", 0)
	root.add_child(sim)
	var craft = sim.drone
	craft.test_input = true
	for inches in [2, 3, 4, 5]:
		craft.set_armed(false)
		sim.select_airframe(inches)
		for surface in [Vector3(0, 0.18, 9), Vector3(20, 0.18, 10), Vector3(-23, 0.18, 51)]:
			craft.spawn_transform = Transform3D(Basis.IDENTITY, surface)
			for mode in ["disarmed", "zero throttle", "low throttle"]:
				craft.reset_drone()
				await steps(3)
				craft.set_armed(mode != "disarmed")
				craft.throttle = 0.15 if mode == "low throttle" else 0.0
				await steps(300)
				var start: Vector3 = craft.position
				var angular_peak := 0.0
				var drift_peak := 0.0
				var thrust_peak := 0.0
				for i in range(120):
					await physics_frame
					angular_peak = maxf(angular_peak, craft.angular_velocity.length())
					drift_peak = maxf(drift_peak, craft.position.distance_to(start))
					thrust_peak = maxf(thrust_peak, craft.total_thrust)
				var label := '%d-inch %s at %s: ' % [inches, mode, surface]
				check(angular_peak < 0.02 and drift_peak < 0.0005, label + "quiet ground contact")
				if mode != "low throttle":
					check(thrust_peak < 0.000001, label + "motors stay stopped")
			check(absf(craft.position.y - start_height(surface) - float(craft.profile.body_height) * 0.5) < 0.002, '%d-inch at %s: frame rests above visible surface' % [inches, surface])
			craft.throttle = craft.hover_throttle() * 1.3
			await steps(180)
			check(craft.position.y > start_height(surface) + 0.3 and craft.linear_velocity.y > 0.5, '%d-inch at %s: lifts off after resting' % [inches, surface])
		# Both ends of every visible arm must actually bridge the chassis and motor.
		for i in range(4):
			var beam: MeshInstance3D = craft.visual.get_node("FrameArm%d" % i)
			var half_length: float = beam.mesh.size.z * 0.5
			var tip: Vector3 = beam.position + beam.basis.z * half_length
			var inner: Vector3 = beam.position - beam.basis.z * half_length
			check(tip.distance_to(craft.MOTOR_POSITIONS[i]) < 0.01 and inner.length() < 0.01, '%d-inch arm %d: connects body to motor' % [inches, i])
	craft.set_armed(false)
	sim.select_airframe(5)
	sim.fpv = true
	sim.paused = true
	paused = true
	await process_frame
	await process_frame
	var expected: Transform3D = craft.global_transform * Transform3D(Basis(Vector3.RIGHT, deg_to_rad(sim.fpv_tilt)), Vector3(0, 0.018, -0.070))
	check(sim.camera.global_transform.is_equal_approx(expected) and is_equal_approx(sim.camera.fov, 105.0) and is_equal_approx(sim.camera.near, 0.035), "Original FPV camera mount and field of view preserved")
	sim.queue_free()
	await process_frame
	print("GROUND TESTS: ", "ALL PASSED" if failures == 0 else str(failures) + " FAILED")
	quit(0 if failures == 0 else 1)

func start_height(surface: Vector3) -> float:
	if surface.x == 20:
		return 0.0
	return 0.045 if surface.x == -23 else 0.0475
