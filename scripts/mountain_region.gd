extends Node3D
## Coarse distant landscape; detailed matching mesh/collision is streamed ahead.
const CHUNK := 200
const EXTENT := 4000
var field: Node3D
var topology: RefCounted
var terrain_material: ShaderMaterial
var chunks := {}
var queue: Array[Vector2i] = []
var last_position := Vector3.INF
var launch_index := 0
var frontier: Node3D
var landmark_root: Node3D
var overview: Texture2D
var worker: Thread
var worker_sampler: RefCounted
var main_sampler: RefCounted
var active_job: RefCounted

func build(world: Node3D) -> void:
	field = world
	topology = world.topography
	main_sampler = preload("res://scripts/mountain_sampler.gd").new(topology)
	worker_sampler = preload("res://scripts/mountain_sampler.gd").new()
	process_mode = Node.PROCESS_MODE_ALWAYS
	terrain_material = ShaderMaterial.new()
	terrain_material.shader = load("res://assets/shaders/alpine_terrain.gdshader" if RenderingServer.get_current_rendering_method()=="forward_plus" else "res://assets/shaders/alpine_terrain_compat.gdshader")
	for label in ["grass","cliff","scree","snow","forest"]:
		for channel in ["color","normal"]:
			terrain_material.set_shader_parameter(label+"_"+channel,load("res://assets/environment/%s_%s.jpg" % [label,channel]))
	for z in range(-20,20):
		for x in range(-20,20):
			var key := Vector2i(x,z)
			if is_original(key): continue
			var mesh := MeshInstance3D.new()
			mesh.mesh = make_mesh(key,20)
			mesh.material_override = terrain_material
			mesh.position = Vector3(x*CHUNK,0,z*CHUNK)
			mesh.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
			add_child(mesh)
			chunks[key] = {"mesh":mesh,"coarse":mesh.mesh,"body":null}
	landmark_root = Node3D.new()
	landmark_root.set_script(load("res://scripts/mountain_landmarks.gd"))
	add_child(landmark_root)
	landmark_root.build(field,self)
	frontier = Node3D.new()
	frontier.set_script(load("res://scripts/exploration_scenery.gd"))
	add_child(frontier)
	frontier.build(field,self)
	make_overview()
	# Coarse vertices are reusable; arbitrary sample caches must stay bounded.
	topology.cache.clear()

func make_overview() -> void:
	var image := Image.create(128,128,false,Image.FORMAT_RGB8)
	for z in range(128):
		for x in range(128):
			var px := -4000.0+x*8000.0/127
			var pz := -4000.0+z*8000.0/127
			var h: float = field._terrain_height(px,pz)
			var color := Color("37554b").lerp(Color("868674"),clampf(h/650,0,1))
			if h>600: color = color.lerp(Color("d7e3df"),clampf((h-600)/250,0,1))
			var slope: float = (field._terrain_height(px+15,pz)-h)/15
			color *= clampf(0.85-slope*0.15,0.45,1.25)
			if not is_nan(field.water_height_at(px,pz)): color = Color("4d909b")
			image.set_pixel(x,z,color)
	overview = ImageTexture.create_from_image(image)

func is_original(key: Vector2i) -> bool:
	return key.x>=-6 and key.x<6 and key.y>=-6 and key.y<6

func key_at(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x/CHUNK),floori(p.z/CHUNK))

func surface_height(x: float,z: float) -> float:
	var step := detail_step(key_at(Vector3(x,0,z)))
	var a := floorf(x/step)*step
	var b := floorf(z/step)*step
	var u := (x-a)/step
	var v := (z-b)/step
	var h00: float = main_sampler.sample(a,b)
	var h10: float = main_sampler.sample(a+step,b)
	var h01: float = main_sampler.sample(a,b+step)
	if u+v<=1:
		return h00+(h10-h00)*u+(h01-h00)*v
	var h11: float = main_sampler.sample(a+step,b+step)
	return h11+(h01-h11)*(1-u)+(h10-h11)*(1-v)

func make_mesh(key: Vector2i,step: int) -> ArrayMesh:
	var job := preload("res://scripts/mountain_mesh_job.gd").new()
	job.sampler = main_sampler
	var result: Dictionary = job.build(key,step)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,result.arrays)
	return mesh

func refine(key: Vector2i) -> void:
	if not chunks.has(key) or chunks[key].body != null: return
	var job := preload("res://scripts/mountain_mesh_job.gd").new()
	job.sampler = main_sampler
	var result: Dictionary = job.build(key,detail_step(key))
	apply_refinement(key,result.arrays)

func detail_step(key: Vector2i) -> int:
	var centre := Vector3((key.x+0.5)*CHUNK,0,(key.y+0.5)*CHUNK)
	if centre.x < -2150 and centre.z > 650 and centre.z < 2400: return 5
	if (centre.x < -1700 and centre.z > -1300 and centre.z < 900) or (centre.x>1750 and centre.z>650 and centre.z<1750) or (centre.x>2000 and absf(centre.z)<850): return 5
	return 5 if centre.z < -1400 and centre.z > -3600 and absf(centre.x-topology.river_x(centre.z)) < 450 else 10

func apply_refinement(key: Vector2i,arrays: Array) -> void:
	if not chunks.has(key) or chunks[key].body!=null: return
	var data: Dictionary = chunks[key]
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	data.mesh.mesh = mesh
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_trimesh_shape()
	body.add_child(collision)
	data.mesh.add_child(body)
	data.body = body

func ensure_region(p: Vector3) -> void:
	var centre := key_at(p)
	for z in range(-1,2):
		for x in range(-1,2):
			refine(centre+Vector2i(x,z))
	update_queue(p)

func update_queue(p: Vector3) -> void:
	last_position = p
	queue.clear()
	var centre := key_at(p)
	for z in range(-3,4):
		for x in range(-3,4):
			var key := centre+Vector2i(x,z)
			if chunks.has(key) and chunks[key].body==null:
				queue.append(key)
	queue.sort_custom(func(a: Vector2i,b: Vector2i) -> bool: return (Vector2(a)-Vector2(centre)).length_squared()<(Vector2(b)-Vector2(centre)).length_squared())
	for key in chunks:
		var data: Dictionary = chunks[key]
		if data.body!=null and (Vector2(key)-Vector2(centre)).length()>6:
			data.mesh.mesh = data.coarse
			data.body.queue_free()
			data.body = null
	if topology.cache.size()>180000:
		topology.cache.clear()

func _process(_delta: float) -> void:
	if not is_instance_valid(field) or not is_instance_valid(field.get_parent().get("drone")): return
	if worker!=null and not worker.is_alive():
		var result: Dictionary = worker.wait_to_finish()
		worker = null
		active_job = null
		apply_refinement(result.key,result.arrays)
		if worker_sampler.topology.cache.size()>180000:
			worker_sampler.topology.cache.clear()
	var p: Vector3 = field.get_parent().drone.global_position
	if last_position==Vector3.INF or p.distance_to(last_position)>80:
		update_queue(p)
	if worker==null and not queue.is_empty():
		var key: Vector2i = queue.pop_front()
		if chunks[key].body!=null: return
		active_job = preload("res://scripts/mountain_mesh_job.gd").new()
		active_job.sampler = worker_sampler
		worker = Thread.new()
		var error := worker.start(active_job.build.bind(key,detail_step(key)))
		if error!=OK:
			worker = null
			refine(key)

func _exit_tree() -> void:
	if worker!=null:
		worker.wait_to_finish()
		worker = null

func launch_position(index: int) -> Vector3:
	launch_index = clampi(index,0,topology.launches.size()-1)
	var p: Vector3 = topology.launches[launch_index].position
	ensure_region(p)
	return p+Vector3.UP*0.28
