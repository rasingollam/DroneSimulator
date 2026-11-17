extends SceneTree
const Catalog = preload("res://scripts/training_catalog.gd")

func _initialize() -> void:
	call_deferred("capture")

func shot(path: String) -> void:
	for i in range(15):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func capture() -> void:
	var sim = load("res://scenes/main.tscn").instantiate()
	sim.set_meta("controller_port",0)
	root.add_child(sim)
	current_scene = sim
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1440,900))
	sim.toggle_training()
	sim.training_cursor = 8
	await shot("res://tests/training-menu.png")
	sim.set_process(false)
	sim.show_training = false
	sim.paused = false
	sim.hud_mode = 2
	for index in [3,4,5,6,7]:
		sim.training.select_activity(index)
		var center: Vector3 = Catalog.ZONES[Catalog.ACTIVITIES[index].zone]
		if index == 7:
			center = Vector3(20,0,600)
		sim.camera.fov = 70
		sim.camera.global_position = center+Vector3(65,50,90)
		sim.camera.look_at(center+Vector3(0,4,0))
		sim.hud.queue_redraw()
		await shot("res://tests/district-%s.png" % Catalog.ACTIVITIES[index].id)
	for detail in [
		["factory-detail",Vector3(409,5,182),Vector3(398,7,164)],
		["quarry-detail",Vector3(392,3,-330),Vector3(412,7,-346)],
		["freight-props",Vector3(313,1.8,207),Vector3(309,0.7,202)]
	]:
		sim.camera.fov = 70
		sim.camera.global_position = detail[1]
		sim.camera.look_at(detail[2])
		await shot("res://tests/%s.png" % detail[0])
	# Check the active lesson instrument HUD with its empty gate array.
	sim.training.select_activity(1)
	sim.drone.global_transform = sim.drone.spawn_transform
	sim.hud_mode = 1
	sim.camera.global_position = sim.drone.spawn_transform.origin+Vector3(0,2,4)
	sim.camera.look_at(Catalog.ACTIVITIES[1].target)
	sim.hud.queue_redraw()
	await shot("res://tests/hover-instruments.png")
	sim.queue_free()
	await process_frame
	quit()
