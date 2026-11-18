extends SceneTree
const Sampler = preload("res://scripts/mountain_sampler.gd")
const MeshJob = preload("res://scripts/mountain_mesh_job.gd")
var failures := 0
var sim: Node3D
func _initialize() -> void: call_deferred("run")
func check(value: bool,label: String) -> void:
	print("PASS: " if value else "FAIL: ",label)
	if not value: failures+=1
func steps(count: int) -> void:
	for i in range(count): await physics_frame
func ray(a: Vector3,b: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(a,b)
	query.exclude = [sim.drone.get_rid()]
	return sim.get_world_3d().direct_space_state.intersect_ray(query)
func mesh_data(sampler: RefCounted,key: Vector2i,step: int) -> Array:
	var job := MeshJob.new()
	job.sampler = sampler
	return job.build(key,step).arrays
func edge(data: Array,axis: int,value: float) -> Dictionary:
	var result := {}
	var verts: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = data[Mesh.ARRAY_NORMAL]
	for i in range(verts.size()):
		if is_equal_approx(verts[i][axis],value):
			result[verts[i].z if axis==0 else verts[i].x] = Vector4(normals[i].x,normals[i].y,normals[i].z,verts[i].y)
	return result
func topology_valid(data: Array) -> bool:
	var edges := {}
	var verts: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = data[Mesh.ARRAY_INDEX]
	for i in range(0,indices.size(),3):
		var a := verts[indices[i]]
		var b := verts[indices[i+1]]
		var c := verts[indices[i+2]]
		if (c-a).cross(b-a).y<=0: return false
		for j in range(3):
			var u := indices[i+j]
			var v := indices[i+(j+1)%3]
			var key := Vector2i(mini(u,v),maxi(u,v))
			edges[key] = edges.get(key,0)+1
	for key in edges:
		if edges[key]==2: continue
		if edges[key]!=1: return false
		var a := verts[key.x]
		var b := verts[key.y]
		if not ((a.x==0 and b.x==0) or (a.x==200 and b.x==200) or (a.z==0 and b.z==0) or (a.z==200 and b.z==200)): return false
	return true
func run() -> void:
	var sampler := Sampler.new()
	for key in [Vector2i(-2,-10),Vector2i(-3,-13),Vector2i(5,-14),Vector2i(7,-8),Vector2i(6,0)]:
		for lod in [5,10,20]:
			var a := mesh_data(sampler,key,lod)
			var b := mesh_data(sampler,key+Vector2i.RIGHT,20)
			var c := mesh_data(sampler,key+Vector2i.DOWN,10)
			var right := edge(a,0,200)
			var left := edge(b,0,0)
			var bottom := edge(a,2,200)
			var top := edge(c,2,0)
			check(right.size()==41 and right==left and bottom.size()==41 and bottom==top,"All edge heights/normals join across LOD %d at %s" % [lod,key])
			check(topology_valid(a),"Terrain is manifold without holes, inverted faces or T-junctions at LOD %d" % lod)
	# Abrupt route endpoints previously cut vertical walls across the landscape.
	for p in [Vector2(100,-1400),Vector2(100,-3680),Vector2(850,-1450),Vector2(2400,-1300)]:
		check(absf(sampler.sample(p.x-0.01,p.y)-sampler.sample(p.x+0.01,p.y))<0.1 and absf(sampler.sample(p.x,p.y-0.01)-sampler.sample(p.x,p.y+0.01))<0.1,"Valley endpoint is continuous at "+str(p))
	sim = load("res://scenes/main.tscn").instantiate()
	sim.set_meta("controller_port",0)
	var save_path := "user://mountain-test-%d.cfg" % OS.get_process_id()
	sim.set_meta("progress_path",save_path)
	root.add_child(sim)
	current_scene = sim
	await steps(3)
	check(sim.field.FLIGHT_RADIUS==3800 and sim.field.mountains.chunks.size()==1456,"Eight-kilometre landscape surrounds the original districts")
	for i in range(9):
		check(sim.enter_free_roam(i),"Launch selection: "+sim.field.topography.launches[i].name)
		await steps(180)
		var p: Vector3 = sim.field.topography.launches[i].position
		check(not sim.drone.crashed and not sim.drone.armed and sim.drone.position.distance_to(p+Vector3.UP*(0.12+sim.drone.profile.body_height*0.5))<0.02 and sim.drone.linear_velocity.length()<0.1,"Launch pad supports a stable resting aircraft")
		check(sim.training.selected==-1 and sim.training.activity.kind=="free" and sim.field.gates.is_empty(),"Free roaming clears training gates and scores")
	sim.select_airframe(2)
	for index in [0,6,8]:
		sim.enter_free_roam(index)
		await steps(180)
		check(not sim.drone.crashed and sim.drone.linear_velocity.length()<0.1,"Two-inch airframe rests quietly at scenic launch "+str(index))
	# A pending physics reset must not immediately crash again at the old water position.
	sim.drone.global_position = Vector3(-250,69,-1600)
	sim.drone.crashed = true
	sim.reset_flight()
	await steps(10)
	check(not sim.drone.crashed and sim.drone.position.distance_to(sim.drone.spawn_transform.origin)<0.1,"Reset from water reaches the launch site without a second crash")
	for passage in sim.field.mountains.landmark_root.passages:
		var p: Vector3 = passage.centre
		sim.field.mountains.ensure_region(p)
		await steps(3)
		var length := 6.0 if passage.name=="Village house" else 41.0 if passage.name in ["Cave","Road tunnel"] else 12.0
		check(ray(p+Vector3.BACK*length,p+Vector3.FORWARD*length).is_empty(),passage.name+": centre passage stays physically open")
		check(not ray(p,p+Vector3.UP*70).is_empty(),passage.name+": overhead geometry has solid collision")
	var t: RefCounted = sim.field.topography
	for side in [-1,1]:
		check(absf(t.height(t.river_x(-2050)+side*65,-2050)-(t.river_y(-2050)+27.3))<0.1,"Stone bridge deck meets its approach terrain")
		check(absf(t.height(1500+side*125,t.branch_z(1500))-(t.viaduct_y()+0.35))<0.01,"Railway deck meets its approach terrain")
	check(sim.field.is_water(Vector3(-250,69.9,-1600)) and not sim.field.is_water(Vector3(-250,72,-1600)),"Lower lake contact matches its surface")
	check(sim.field.is_water(Vector3(t.river_x(-3350),t.river_y(-3350)-0.1,-3350)),"High lake uses its own water elevation")
	for i in range(3):
		sim.field.apply_atmosphere(i)
		check(sim.field.atmosphere==i,"Atmosphere preset "+str(i)+" applies")
	sim.toggle_explorer()
	check(paused and sim.show_explorer,"Explorer pauses flight")
	sim.toggle_explorer()
	check(not paused,"Closing explorer restores flight")
	sim.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	print("MOUNTAIN TESTS: ","ALL PASSED" if failures==0 else str(failures)+" FAILED")
	quit(0 if failures==0 else 1)
