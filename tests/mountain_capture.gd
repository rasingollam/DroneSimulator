extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func shot(sim: Node3D,name: String,position: Vector3,target: Vector3,preset: int=0) -> void:
	position.y = maxf(position.y,sim.field._terrain_height(position.x,position.z)+6)
	sim.field.apply_atmosphere(preset)
	sim.drone.global_position = position
	sim.field.mountains.ensure_region(position)
	sim.camera.global_position = position
	sim.camera.look_at(target)
	sim.camera.fov = 75
	for i in range(120): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/mountain-%s.png" % name)
	print("MOUNTAIN RENDER ",name," FPS=",Engine.get_frames_per_second()," drawcalls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
func capture() -> void:
	var sim = load("res://scenes/main.tscn").instantiate()
	sim.set_meta("controller_port",0)
	root.add_child(sim)
	current_scene = sim
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1440,900))
	sim.toggle_explorer()
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/mountain-explorer.png")
	sim.show_explorer = false
	sim.paused = false
	sim.drone.visual.visible = false
	sim.set_process(false)
	sim.hud_mode = 2
	sim.hud.queue_redraw()
	var t: RefCounted = sim.field.topography
	await shot(sim,"river-valley",Vector3(t.river_x(-1900),t.river_y(-1900)+24,-1900),Vector3(t.river_x(-2250),t.river_y(-2250)+25,-2250))
	await shot(sim,"waterfall",Vector3(t.river_x(-2325),t.river_y(-2325)+22,-2325),Vector3(t.river_x(-2400),t.river_y(-2400)+12,-2400))
	await shot(sim,"arch",Vector3(t.river_x(-2120),t.river_y(-2120)+12,-2120),Vector3(t.river_x(-2180),t.river_y(-2180)+14,-2180))
	await shot(sim,"cave",Vector3(t.cave_x(),t.river_y(-2740)+23,-2690),Vector3(t.cave_x(),t.river_y(-2740)+24,-2775))
	await shot(sim,"village",Vector3(-1005,t.village_height+15,-2490),Vector3(-1055,t.village_height+4,-2550))
	var site: Vector3 = t.launches[6].position
	await shot(sim,"summit",site+Vector3(20,18,70),Vector3(-250,130,-1800))
	await shot(sim,"glacial-lake",t.launches[8].position+Vector3(20,30,90),Vector3(t.river_x(-3350),t.river_y(-3350),-3350))
	var viaduct: Vector3 = sim.field.mountains.landmark_root.passages[4].centre
	await shot(sim,"viaduct",viaduct+Vector3(-60,35,140),viaduct)
	await shot(sim,"road",Vector3(t.road_x(-2800)-35,t.road_y(-2800)+22,-2800),Vector3(t.road_x(-2890),t.road_y(-2890)+3,-2890))
	await shot(sim,"golden-hour",Vector3(t.river_x(-1900),t.river_y(-1900)+24,-1900),Vector3(t.river_x(-2250),t.river_y(-2250)+25,-2250),1)
	await shot(sim,"mist",Vector3(t.river_x(-1900),t.river_y(-1900)+24,-1900),Vector3(t.river_x(-2250),t.river_y(-2250)+25,-2250),2)
	sim.queue_free()
	await process_frame
	quit()
