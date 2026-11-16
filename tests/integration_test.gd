extends SceneTree

var sim: Node3D
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, description: String) -> void:
	if value:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1

func steps(count: int) -> void:
	for i in range(count):
		await physics_frame

func key(code: Key, down: bool = true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame

func tap(code: Key) -> void:
	await key(code)
	await key(code, false)

func run() -> void:
	sim = load("res://scenes/main.tscn").instantiate()
	root.add_child(sim)
	current_scene = sim
	await process_frame
	check(not paused and not sim.show_help and sim.hud_mode == 0, "Launch opens an unobstructed minimal flight view")
	await tap(KEY_F1)
	check(paused and sim.show_help, "F1 opens the guide and pauses the world")
	await tap(KEY_ENTER)
	check(not paused and not sim.show_help, "Enter dismisses guide and begins simulation")
	await tap(KEY_SPACE)
	check(sim.drone.armed and sim.drone.throttle == 0.0, "Space arms at zero throttle")
	await key(KEY_W)
	await steps(480)
	await key(KEY_W, false)
	var released_throttle: float = sim.drone.throttle
	await steps(120)
	check(released_throttle > 0.55 and released_throttle < 0.68, "Physical W input increases throttle at the configured rate")
	check(is_equal_approx(sim.drone.throttle, released_throttle), "Releasing W retains throttle")
	check(sim.drone.position.y > 0.3, "Keyboard takeoff lifts the drone from the actual landing pad")
	await key(KEY_S)
	await steps(60)
	await key(KEY_S, false)
	check(sim.drone.throttle < released_throttle - 0.05, "Physical S input decreases throttle")
	await tap(KEY_H)
	check(absf(sim.drone.throttle - 0.54932) < 0.001, "H applies analytical hover power")
	await key(KEY_D)
	await steps(120)
	await key(KEY_D, false)
	check(sim.drone.angular_velocity.y < -0.5, "Physical D input yaws right")
	await tap(KEY_C)
	check(sim.fpv and sim.camera.fov == 105.0, "C selects FPV camera")
	await tap(KEY_TAB)
	check(sim.drone.acro, "Tab selects Acro mode")
	await tap(KEY_B)
	await steps(2)
	check(sim.wind_level == 1 and sim.drone.wind.length() > 1.0, "B enables actual wind forces")
	await tap(KEY_ESCAPE)
	var stopped_position: Vector3 = sim.drone.position
	await steps(60)
	check(paused and sim.drone.position.distance_to(stopped_position) < 0.001, "Pause freezes aircraft physics")
	await tap(KEY_SPACE)
	check(sim.drone.armed, "Pause ignores arming controls")
	await tap(KEY_ESCAPE)
	await tap(KEY_R)
	await steps(3)
	check(not sim.drone.armed and sim.drone.throttle == 0.0 and sim.next_gate == 0, "R resets flight and circuit safely")

	# Check gate scoring with controlled positions, independently of piloting.
	sim.drone.freeze = true
	var gate: Node3D = sim.field.gates[0]
	sim.previous_position = gate.to_global(Vector3(0, 0, -1))
	sim.drone.global_position = gate.to_global(Vector3(0, 0, 1))
	sim._check_gate()
	check(sim.next_gate == 0, "Reverse gate crossings do not score")
	sim.previous_position = gate.to_global(Vector3(4, 0, 1))
	sim.drone.global_position = gate.to_global(Vector3(4, 0, -1))
	sim._check_gate()
	check(sim.next_gate == 0, "Crossing outside the gate aperture does not score")
	for i in range(8):
		gate = sim.field.gates[sim.next_gate]
		sim.previous_position = gate.to_global(Vector3(0, 0, 1))
		sim.drone.global_position = gate.to_global(Vector3(0, 0, -1))
		sim._check_gate()
	check(sim.completed_laps == 1 and sim.next_gate == 1, "All seven gates followed by gate 1 complete a timed lap")
	print("INTEGRATION TESTS: ", "ALL PASSED" if failures == 0 else str(failures) + " FAILED")
	quit(0 if failures == 0 else 1)
