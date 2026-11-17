extends SceneTree
const Catalog = preload("res://scripts/training_catalog.gd")
var failures := 0
var sim: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ",label)
	if not value:
		failures += 1

func steps(count: int) -> void:
	for i in range(count):
		await physics_frame

func ray(start: Vector3, end: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(start,end)
	query.exclude = [sim.drone.get_rid()]
	return sim.get_world_3d().direct_space_state.intersect_ray(query)

func run() -> void:
	var save_path := "user://expansion-test-%d.cfg" % OS.get_process_id()
	sim = load("res://scenes/main.tscn").instantiate()
	sim.set_meta("controller_port",0)
	sim.set_meta("progress_path",save_path)
	root.add_child(sim)
	current_scene = sim
	await steps(3)
	check(sim.field.FLIGHT_RADIUS > 1000 and not ray(Vector3(900,120,0),Vector3(900,-10,0)).is_empty(),"Expanded terrain remains solid beyond the old boundary")
	for center in Catalog.ZONES:
		var ground := ray(center+Vector3(5,30,5),center+Vector3(5,-3,5))
		check(not ground.is_empty(),"District ground collision exists at "+str(center))
	for index in range(Catalog.ACTIVITIES.size()):
		sim.drone.set_armed(false)
		check(sim.training.select_activity(index),Catalog.ACTIVITIES[index].name+": selection succeeds")
		await steps(3)
		check(not sim.drone.armed and sim.drone.position.distance_to(Catalog.ACTIVITIES[index].spawn)<0.01,"Activity starts disarmed at its own launch point")
		if sim.training.activity.kind == "race":
			var clear := true
			for gate in sim.field.gates:
				clear = clear and ray(gate.to_global(Vector3(0,0,0.3)),gate.to_global(Vector3(0,0,-0.3))).is_empty()
			check(clear,sim.training.activity.name+": every gate centre is physically flyable")
		else:
			check(sim.field.gates.is_empty(),"Lessons clear the previous circuit")
		# Exercise every instrument HUD branch, including lessons with no gates.
		sim.hud_mode = 1
		await process_frame
		sim.drone.set_armed(true)
		check(not sim.training.select_activity(0),"Armed activity changes are rejected")
		sim.drone.set_armed(false)
	# Menu gating and closing preserve the previous pause state.
	sim.toggle_training()
	check(paused and sim.show_training,"Training menu pauses flight")
	sim.training_cursor = 1
	sim.start_training()
	check(not paused and not sim.show_training and sim.training.selected == 1,"Launch exits menu into the selected lesson")
	sim.drone.freeze = true
	sim.drone.global_position = Catalog.ACTIVITIES[1].target
	sim.drone.set_armed(true)
	sim.drone.linear_velocity = Vector3.ZERO
	for i in range(50):
		sim.training.update(0.1)
	check(not sim.training.complete and sim.training.hold>4.9,"Hover lesson requires the full steady hold")
	sim.drone.global_position += Vector3.UP
	sim.training.update(0.1)
	check(sim.training.hold == 0,"Leaving hover tolerance resets consecutive hold")
	sim.drone.global_position = Catalog.ACTIVITIES[1].target
	for i in range(101):
		sim.training.update(0.1)
	check(sim.training.complete and sim.training.completions(1)==1,"Steady hover completes and records the lesson once")
	sim.training.update(1.0)
	check(sim.training.completions(1)==1,"Completed lesson does not repeatedly award progress")
	sim.drone.set_armed(false)
	sim.training.select_activity(2)
	sim.training.update(1.1)
	check(not sim.training.complete,"Landing lesson cannot complete without takeoff")
	sim.drone.global_position = Catalog.ACTIVITIES[2].target+Vector3.UP*2
	sim.drone.set_armed(true)
	sim.training.update(0.1)
	check(sim.training.took_off,"Landing lesson recognizes a real takeoff height")
	sim.drone.freeze = false
	sim.drone.spawn_transform.origin = Catalog.ACTIVITIES[2].target+Vector3.UP*0.15
	sim.drone.reset_drone()
	sim.training.elapsed = 2
	await steps(480)
	check(sim.training.complete and not sim.drone.crashed,"Gentle settled contact on the target completes landing")
	sim.drone.set_armed(false)
	sim.training.select_activity(4)
	sim.training.record_result(40)
	sim.training.record_result(50)
	check(is_equal_approx(sim.best_lap,40) and sim.training.completions(4)==2,"Slower repeats preserve the best time")
	sim.toggle_mode()
	check(sim.best_lap==0,"Acro records are separate from Angle records")
	sim.toggle_mode()
	sim.wind_level = 1
	sim.training.refresh_best()
	check(sim.best_lap==0,"Wind conditions have separate records")
	sim.wind_level = 0
	sim.training.refresh_best()
	check(sim.best_lap==40,"Original setup retrieves its record")
	var saved := ConfigFile.new()
	check(saved.load(save_path)==OK and float(saved.get_value("forest_5_angle_w0","best",0))==40,"Progress survives reloading from disk")
	check(Catalog.medal(Catalog.ACTIVITIES[4],20)=="GOLD" and Catalog.medal(Catalog.ACTIVITIES[4],40)=="SILVER" and Catalog.medal(Catalog.ACTIVITIES[4],60)=="BRONZE","Medals use the documented activity targets")
	check(ray(Vector3(-20,2,600),Vector3(90,2,600)).is_empty(),"Bridge has an open longitudinal flight passage")
	check(not ray(Vector3(0,2,600),Vector3(0,8,600)).is_empty(),"Bridge deck is solid")
	check(sim.field.is_water(Vector3(40,-1.1,600)) and not sim.field.is_water(Vector3(40,2,600)),"Water contact only triggers at the lake surface")
	# Detailed scenery must not reintroduce resting jitter on the new launch pads.
	for inches in [2,5]:
		for index in [0,3,4,5,6,7]:
			sim.drone.set_armed(false)
			sim.select_airframe(inches)
			sim.training.select_activity(index)
			await steps(300)
			var peak := 0.0
			for i in range(60):
				await physics_frame
				peak = maxf(peak,sim.drone.angular_velocity.length())
			check(peak<0.03,'%d-inch launch pad is stable in %s' % [inches,sim.training.activity.name])
	sim.training.records_path = ""
	sim.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	print("EXPANSION TESTS: ","ALL PASSED" if failures==0 else str(failures)+" FAILED")
	quit(0 if failures==0 else 1)
