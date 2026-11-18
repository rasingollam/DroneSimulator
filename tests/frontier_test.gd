extends SceneTree
var sim: Node3D
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(value: bool,label: String) -> void:
 print("PASS: " if value else "FAIL: ",label)
 if not value: failures+=1
func steps(count: int) -> void:
 for i in range(count): await physics_frame
func ray(a: Vector3,b: Vector3) -> Dictionary:
 var query:=PhysicsRayQueryParameters3D.create(a,b)
 query.exclude=[sim.drone.get_rid()]
 return sim.get_world_3d().direct_space_state.intersect_ray(query)
func run() -> void:
 var path: String="res://tools/frontier-test-%d.cfg" % OS.get_process_id()
 sim=load("res://scenes/main.tscn").instantiate()
 sim.set_meta("controller_port",0)
 sim.set_meta("exploration_path",path)
 root.add_child(sim)
 current_scene=sim
 await steps(3)
 var exploration: Node3D=sim.exploration
 var scenery: Node3D=sim.field.mountains.frontier
 check(sim.field.topography.launches.size()==18,"All eighteen scenic starts are available")
 check(scenery.discoveries.size()>=25 and scenery.landings.size()>=9,"World has varied discoverable landmarks and landing targets")
 for index in range(9,18):
  check(sim.enter_free_roam(index),"New region launch: "+sim.field.topography.launches[index].name)
  await steps(200)
  var expected: Vector3=sim.field.topography.launches[index].position+Vector3.UP*(0.12+sim.drone.profile.body_height*0.5)
  check(not sim.drone.crashed and not sim.drone.armed and sim.drone.position.distance_to(expected)<0.035 and sim.drone.linear_velocity.length()<0.1,"New launch pad supports stable flight preparation")
 for passage in scenery.passages:
  var centre: Vector3=(passage.a+passage.b)*0.5
  sim.field.mountains.ensure_region(centre)
  await steps(3)
  check(ray(passage.a,passage.b).is_empty(),passage.name+" has a physically open flight path")
  check(not ray(centre,centre+Vector3.UP*60).is_empty(),passage.name+" has a solid overhead surface")
 sim.drone.freeze=true
 sim.set_physics_process(false)
 for target in scenery.landings:
  sim.field.mountains.ensure_region(target.position)
  await steps(2)
  var hit:=ray(target.position+Vector3.UP*0.4,target.position-Vector3.UP*0.4)
  check(not hit.is_empty() and absf(hit.position.y-target.position.y)<0.02,"Landing surface matches its target: "+target.name)
 var track: PackedVector3Array=scenery.railway_points
 var track_index: int=track.size()/2
 var right: Vector3=(track[track_index+1]-track[track_index]).normalized().cross(Vector3.UP).normalized()
 var shoulder: Vector3=track[track_index]+right*1.8
 sim.field.mountains.ensure_region(shoulder)
 await steps(3)
 var bed:=ray(shoulder+Vector3.UP*0.2,shoulder-Vector3.UP*0.1)
 check(not bed.is_empty() and absf(bed.position.y-shoulder.y)<0.03,"Railway gravel bed has upward-facing physical collision")
 check(sim.field.is_water(Vector3(-3200,11.9,1500)),"Coastal water contact matches sea level")
 check(sim.field.is_water(Vector3(1910,145.05,920)),"Flooded rice fields have matching water contact")
 check(not sim.field.is_water(Vector3(2300,260,-1760)),"Water below the dam does not use the reservoir elevation")
 var geo=preload("res://scripts/exploration_geography.gd")
 check(absf(geo.delta_y(2800)-35)<0.001,"Braided channels meet the lake without a height step")
 for value in range(3):
  exploration.apply_season(value)
  check(sim.field.mountains.terrain_material.get_shader_parameter("season")==float(value) and scenery.rice_material.get_shader_parameter("season")==float(value),"Season controls terrain and crop materials")
 check(exploration.guides.size()==6,"Six optional scenic flight lines are available")
 for guide in exploration.guides:
  var clear:=true
  for point in guide.points:
   clear=clear and Vector2(point.x,point.z).length()<3800 and point.y>sim.field._terrain_height(point.x,point.z)+5
  check(clear,guide.name+" remains above ground and inside the flight boundary")
 for i in range(7): exploration.toggle_guide()
 check(exploration.guide_index==-1,"Guides cycle back to an unobstructed free-roaming view")
 exploration.toggle_hints()
 check(exploration.hints and is_instance_valid(exploration.hint_mesh),"Landing hints are optional")
 exploration.toggle_hints()
 var place: Dictionary=scenery.discoveries[0]
 exploration.discovered.clear()
 sim.drone.global_position=place.position
 exploration.discover_nearby()
 var total: int=exploration.discovered.size()
 exploration.discover_nearby()
 check(exploration.discovered.has(place.id) and exploration.discovered.size()==total,"Discoveries are awarded once")
 var target: Dictionary=scenery.landings[0]
 sim.drone.crashed=false
 sim.drone.set_armed(false)
 sim.drone.global_position=target.position+Vector3.UP*sim.drone.profile.body_height*0.5
 sim.drone.linear_velocity=Vector3.ZERO
 exploration.landed.clear()
 exploration.check_landings(1.0)
 check(not exploration.landed.has(target.id),"Landing discovery requires settling for two seconds")
 exploration.check_landings(1.1)
 check(exploration.landed.has(target.id),"A stable landing records the discovered spot")
 exploration.toggle_recording()
 sim.drone.set_armed(true)
 for i in range(12):
  sim.drone.global_position=Vector3(100+i,100,200)
  exploration._physics_process(0.05)
 exploration.finish_recording()
 check(exploration.samples.size()>=12 and FileAccess.file_exists(exploration.route_path),"Personal flight is sampled and saved")
 var before: Array=exploration.samples.duplicate(true)
 exploration.samples=[]
 exploration.load_flight()
 var same: bool=exploration.samples.size()==before.size()
 if same:
  for i in range(before.size()):
   for j in range(8): same=same and absf(float(exploration.samples[i][j])-float(before[i][j]))<0.000001
 check(same,"Saved flight reloads positions, rotation and timing within a micro-unit")
 var position: Vector3=exploration.replay_transform(0.025).origin
 check(absf(position.x-100.5)<0.001,"Replay interpolates between recorded samples")
 sim.drone.set_armed(false)
 sim.select_airframe(2)
 exploration.toggle_playback()
 check(exploration.playing and is_instance_valid(exploration.ghost),"A saved flight can be replayed while flying another airframe")
 var original: float=exploration.replay_clock
 sim.paused=true
 paused=true
 exploration._physics_process(1.0)
 check(exploration.replay_clock==original,"Replay respects simulation pause")
 check(not scenery.can_process(),"Moving scenery pauses with flight and controller signal holds")
 paused=false
 sim.paused=false
 exploration.toggle_playback()
 var car: Node3D=scenery.gondolas[0]
 var start: Vector3=car.position
 scenery._process(2.0)
 check(car.position.distance_to(start)>0.1,"Cable cars move along the cableway")
 var cable_clear:=true
 for i in range(scenery.cable_points.size()-1):
  for j in range(21):
   var p: Vector3=scenery._cable(i,j/20.0)
   cable_clear=cable_clear and p.y>sim.field._terrain_height(p.x,p.z)+6
 check(cable_clear,"Cable route and gondolas clear the mountain surface")
 check(scenery.ambience.size()>=7,"Spatial water and forest ambience sources exist")
 sim.muted=true
 exploration._process(0)
 var muted:=true
 for source in scenery.ambience: muted=muted and source.stream_paused
 check(muted,"Mute also silences environmental audio")
 exploration.save_progress()
 var saved:=ConfigFile.new()
 check(saved.load(path)==OK and saved.get_value("pilot","landings",{}).has(target.id),"Discoveries and landing records persist")
 var route_path: String=exploration.route_path
 sim.queue_free()
 await process_frame
 for name in [path,route_path]: DirAccess.remove_absolute(ProjectSettings.globalize_path(name))
 print("FRONTIER TESTS: ","ALL PASSED" if failures==0 else str(failures)+" FAILED")
 quit(0 if failures==0 else 1)
