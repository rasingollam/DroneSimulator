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
	sim.explorer_cursor=10
	sim.show_explorer=true
	sim.hud.queue_redraw()
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/frontier-menu.png")
	sim.show_explorer=false
	sim.hud.queue_redraw()
	await shot(sim,"frontier-coast",Vector3(-2750,160,1450),Vector3(-2940,65,1750))
	await shot(sim,"frontier-terraces",Vector3(2060,245,1570),Vector3(2100,153,1180))
	await shot(sim,"frontier-delta",Vector3(-680,130,2050),Vector3(-520,47,2600))
	var geo=preload("res://scripts/exploration_geography.gd")
	await shot(sim,"frontier-slot",Vector3(geo.slot_x(-950),geo.slot_y(-950)+15,-950),Vector3(geo.slot_x(-750),geo.slot_y(-750)+12,-750))
	await shot(sim,"frontier-mine",Vector3(-2050,118,485),Vector3(-2050,117,620))
	await shot(sim,"frontier-dam",Vector3(2270,330,-1560),Vector3(2300,270,-1860))
	await shot(sim,"frontier-quarry",Vector3(2300,250,-80),Vector3(2450,130,-320))
	await shot(sim,"frontier-bowl",Vector3(2250,850,-2300),Vector3(2100,630,-2650))
	sim.exploration.apply_season(2,false)
	await shot(sim,"frontier-winter",Vector3(2250,850,-2300),Vector3(2100,630,-2650))
	sim.exploration.apply_season(0,false)
	sim.field.mountains.frontier._process(0)
	var cable: Vector3=sim.field.mountains.frontier._cable(2,0.66)
	await shot(sim,"frontier-cableway",cable+Vector3(12,6,16),cable+Vector3.DOWN*3)
	await shot(sim,"frontier-alcove",Vector3(t.river_x(-2400)+50,t.river_y(-2385)+20,-2355),Vector3(t.river_x(-2400)+50,t.river_y(-2385)+20,-2410))
	await shot(sim,"frontier-islands",Vector3(-400,125,-1460),Vector3(-250,70,-1600))
	sim.exploration.guide_index=1
	sim.exploration.toggle_guide()
	await shot(sim,"frontier-trail",Vector3(geo.delta_x(2250,1),geo.delta_y(2250)+20,2250),Vector3(geo.delta_x(2380,1),geo.delta_y(2380)+10,2380))
	await shot(sim,"frontier-landslide",Vector3(-1950,420,-1900),Vector3(-2150,270,-2250))
	sim.queue_free()
	await process_frame
	quit()
