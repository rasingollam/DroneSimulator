extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	scene.set_meta("controller_port", 0)
	root.add_child(scene)
	current_scene = scene
	print("DISPLAY MODE: ", DisplayServer.window_get_mode(), " / WINDOW: ", DisplayServer.window_get_size())
	scene.show_help = true
	paused = true
	for i in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/guide.png")
	scene.show_phone = true
	for i in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/pairing.png")
	scene.show_phone = false
	scene.show_help = false
	paused = false
	for i in range(90):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/field.png")
	scene.fpv = true
	scene.camera.fov = 105.0
	for i in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/fpv.png")
	scene.fpv = false
	scene.camera.fov = 85.0
	scene.drone.test_input = true
	scene.drone.spawn_transform.origin = Vector3(0, 3.5, 5)
	scene.drone.reset_drone()
	for i in range(3):
		await physics_frame
	scene.drone.set_armed(true)
	scene.drone.throttle = scene.drone.hover_throttle()
	for i in range(120):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/flight.png")
	print("STEADY FLIGHT FPS: ", Engine.get_frames_per_second())
	scene.drone.set_armed(false)
	scene.toggle_fleet()
	for inches in [2, 3, 4, 5]:
		scene.select_airframe(inches)
		for i in range(20):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/airframe_%d.png" % inches)
	quit()
