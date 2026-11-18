extends Node3D
## Optional exploration tools; no forces, scoring gates or aircraft assistance.
var sim: Node3D
var scenery: Node3D
var records := ConfigFile.new()
var state_path := ""
var route_path := ""
var discovered := {}
var landed := {}
var landing_holds := {}
var scan_clock := 0.0
var season := 0
var guides: Array[Dictionary] = []
var guide_index := -1
var guide_mesh: MeshInstance3D
var recording := false
var working: Array = []
var samples: Array = []
var record_time := 0.0
var sample_clock := 0.0
var recorded_inches := 5
var playing := false
var replay_clock := 0.0
var replay_cursor := 0
var ghost: Node3D
var hints := false
var hint_mesh: MeshInstance3D

func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 scenery=sim.field.mountains.frontier
 var isolated: bool=sim.get_meta("controller_port",42424)==0
 var custom: String=str(sim.get_meta("exploration_path",""))
 state_path=custom if not custom.is_empty() else "" if isolated else "user://exploration.cfg"
 route_path=state_path.get_basename()+"-flight.json" if not state_path.is_empty() else ""
 if not state_path.is_empty() and records.load(state_path)==OK:
  discovered=records.get_value("pilot","discoveries",{})
  landed=records.get_value("pilot","landings",{})
  season=int(records.get_value("world","season",0))%3
 load_flight()
 _guides()
 apply_season(season,false)

func save_progress() -> void:
 if state_path.is_empty(): return
 records.set_value("pilot","discoveries",discovered)
 records.set_value("pilot","landings",landed)
 records.set_value("world","season",season)
 records.save(state_path)
func apply_season(value: int,save: bool=true) -> void:
 season=posmod(value,3)
 sim.field.mountains.terrain_material.set_shader_parameter("season",float(season))
 sim.field.lowland_material.set_shader_parameter("season",float(season))
 sim.field.get_node("Vegetation").needle_material.set_shader_parameter("season",float(season))
 scenery.rice_material.set_shader_parameter("season",float(season))
 if save: save_progress()
func cycle_season() -> void:
 apply_season(season+1)
 sim.flash(["SUMMER VEGETATION","AUTUMN GRASSES","WINTER HIGHLANDS"][season])
func _guides() -> void:
 var topo: RefCounted=sim.field.topography
 var summit: Array[Vector2]=[Vector2(1100,-2700),Vector2(850,-2670),Vector2(550,-2630),Vector2(220,-2580),Vector2(topo.river_x(-2550),-2550)]
 for i in range(37):
  var z: float=-2550+i*25
  summit.append(Vector2(topo.river_x(z),z))
 summit.append(Vector2(-250,-1600))
 guides.append({"name":"SUMMIT TO LAKE","points":route_points(summit,28)})
 var forest: Array[Vector2]=[Vector2(-1400,-1800),Vector2(-1650,-1800),Vector2(-1900,-1600),Vector2(-2150,-1280)]
 for i in range(55):
  var z: float=-1100+i*20
  forest.append(Vector2(preload("res://scripts/exploration_geography.gd").slot_x(z),z))
 guides.append({"name":"FOREST AND SLOT CANYON","points":route_points(forest,9)})
 var braid: Array[Vector2]=[]
 for i in range(55):
  var z: float=1810+i*20
  braid.append(Vector2(preload("res://scripts/exploration_geography.gd").delta_x(z,1),z))
 guides.append({"name":"BRAIDED RIVER LINE","points":route_points(braid,10)})
 var coast: Array[Vector2]=[]
 for i in range(65):
  var z: float=760+i*22
  coast.append(Vector2(preload("res://scripts/exploration_geography.gd").shore_x(z)+65,z))
 guides.append({"name":"COASTAL CLIFF TRAVERSE","points":route_points(coast,22)})
 var industry: Array[Vector2]=[Vector2(2150,-1710),Vector2(1950,-1410),Vector2(2120,-1200),Vector2(1730,-940),Vector2(2060,-720),Vector2(2450,-300)]
 guides.append({"name":"DAM TO QUARRY","points":route_points(industry,30)})
 var bowl: Array[Vector2]=[Vector2(1100,-2700),Vector2(1600,-2500),Vector2(2100,-2450),Vector2(2100,-2200),Vector2(2100,-1850)]
 guides.append({"name":"ALPINE BOWL DIVE","points":route_points(bowl,25)})
func route_points(plan: Array[Vector2],clearance: float) -> PackedVector3Array:
 var points:=PackedVector3Array()
 for i in range(plan.size()-1):
  var count:=maxi(1,ceili(plan[i].distance_to(plan[i+1])/12))
  for j in range(count):
   var p:=plan[i].lerp(plan[i+1],j/float(count))
   var altitude: float=sim.field._terrain_height(p.x,p.y)+clearance
   if absf(p.x+2445)<30 and absf(p.y-1500)<100: altitude=maxf(altitude,52)
   points.append(Vector3(p.x,altitude,p.y))
 var p: Vector2=plan[-1]
 points.append(Vector3(p.x,sim.field._terrain_height(p.x,p.y)+clearance,p.y))
 return points
func _glow(color: Color) -> StandardMaterial3D:
 var material:=StandardMaterial3D.new()
 material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 material.albedo_color=color
 material.emission_enabled=true
 material.emission=color
 material.emission_energy_multiplier=0.7
 return material
func toggle_guide() -> void:
 guide_index+=1
 if guide_index>=guides.size(): guide_index=-1
 if is_instance_valid(guide_mesh): guide_mesh.queue_free()
 if guide_index<0:
  sim.flash("SCENIC TRAILS OFF")
  return
 guide_mesh=_line(guides[guide_index].points,Color("69cdb7"))
 sim.flash(guides[guide_index].name+" / G NEXT TRAIL",5)
func _line(points: PackedVector3Array,color: Color) -> MeshInstance3D:
 var geometry:=ImmediateMesh.new()
 geometry.surface_begin(Mesh.PRIMITIVE_LINE_STRIP,_glow(color))
 for point in points: geometry.surface_add_vertex(point)
 geometry.surface_end()
 var node:=MeshInstance3D.new()
 node.mesh=geometry
 node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(node)
 return node
func toggle_hints() -> void:
 hints=not hints
 if is_instance_valid(hint_mesh): hint_mesh.queue_free()
 if hints:
  var geometry:=ImmediateMesh.new()
  geometry.surface_begin(Mesh.PRIMITIVE_LINES,_glow(Color("d9b96c")))
  for target in scenery.landings:
   var p: Vector3=target.position+Vector3.UP
   for i in range(4):
    var a:=i*PI/2
    var b: float=(i+1)*PI/2
    geometry.surface_add_vertex(p+Vector3(cos(a),0,sin(a))*2)
    geometry.surface_add_vertex(p+Vector3(cos(b),0,sin(b))*2)
  geometry.surface_end()
  hint_mesh=MeshInstance3D.new()
  hint_mesh.mesh=geometry
  add_child(hint_mesh)
 sim.flash("LANDING HINTS ON / O TO HIDE" if hints else "LANDING HINTS OFF")
func toggle_recording() -> void:
 if recording:
  finish_recording()
 else:
  recording=true
  record_time=0
  sample_clock=0
  working=[]
  recorded_inches=sim.drone.inches
  sim.flash("FLIGHT RECORDING / Y TO SAVE",4)
func finish_recording() -> void:
 recording=false
 if working.size()<2:
  sim.flash("RECORDING TOO SHORT / PREVIOUS FLIGHT KEPT")
  return
 playing=false
 if is_instance_valid(ghost): ghost.queue_free()
 ghost=null
 samples=working.duplicate(true)
 if not route_path.is_empty():
  var file:=FileAccess.open(route_path,FileAccess.WRITE)
  if file: file.store_string(JSON.stringify({"v":1,"airframe":recorded_inches,"samples":samples},"",true,true))
 sim.flash("FLIGHT SAVED / P REPLAYS THE GHOST",5)
func load_flight() -> void:
 if route_path.is_empty() or not FileAccess.file_exists(route_path): return
 var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(route_path))
 if not parsed is Dictionary or parsed.get("v")!=1 or not parsed.get("samples") is Array: return
 var frames: Array=parsed.samples
 if frames.size()<2 or frames.size()>18000: return
 var previous: float=-1
 for frame in frames:
  if not frame is Array or frame.size()!=8: return
  for value in frame:
   if not (value is float or value is int) or not is_finite(float(value)): return
  if frame[0]<=previous or absf(frame[1])>4100 or absf(frame[3])>4100 or frame[2]<-50 or frame[2]>2000: return
  var q:=Quaternion(frame[4],frame[5],frame[6],frame[7])
  if q.length_squared()<0.1 or q.length_squared()>2: return
  previous=frame[0]
 samples=frames
 recorded_inches=int(parsed.get("airframe",5))
 if recorded_inches not in [2,3,4,5]: recorded_inches=5
func toggle_playback() -> void:
 if samples.size()<2:
  sim.flash("NO SAVED FLIGHT / Y STARTS RECORDING")
  return
 playing=not playing
 replay_clock=0
 replay_cursor=0
 if not is_instance_valid(ghost):
  ghost=Node3D.new()
  add_child(ghost)
  var visual:=Node3D.new()
  visual.set_script(load("res://scripts/drone_visual.gd"))
  ghost.add_child(visual)
  visual.build(recorded_inches,preload("res://scripts/drone_profiles.gd").get_profile(recorded_inches))
  var material:=_glow(Color(0.3,0.9,0.78,0.4))
  material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  for mesh in visual.find_children("*","MeshInstance3D",true,false): mesh.material_override=material
 ghost.visible=playing
 sim.flash("FLIGHT GHOST ON / ARMS START THE CLOCK" if playing else "FLIGHT GHOST OFF")
func replay_transform(time: float) -> Transform3D:
 if samples.size()<2: return Transform3D.IDENTITY
 var t:=clampf(time+float(samples[0][0]),samples[0][0],samples[-1][0])
 if replay_cursor>=samples.size()-1 or float(samples[replay_cursor][0])>t: replay_cursor=0
 while replay_cursor<samples.size()-2 and float(samples[replay_cursor+1][0])<t: replay_cursor+=1
 var a: Array=samples[replay_cursor]
 var b: Array=samples[replay_cursor+1]
 var blend:=clampf((t-float(a[0]))/(float(b[0])-float(a[0])),0,1)
 var p:=Vector3(a[1],a[2],a[3]).lerp(Vector3(b[1],b[2],b[3]),blend)
 var q:=Quaternion(a[4],a[5],a[6],a[7]).normalized().slerp(Quaternion(b[4],b[5],b[6],b[7]).normalized(),blend)
 return Transform3D(Basis(q),p)
func _physics_process(delta: float) -> void:
 if get_tree().paused or sim.drone.respawn_requested: return
 if recording:
  if sim.drone.armed and not sim.drone.crashed:
   record_time+=delta
   sample_clock+=delta
   if sample_clock>=0.05:
    sample_clock=0
    if working.is_empty(): recorded_inches=sim.drone.inches
    var p: Vector3=sim.drone.global_position
    var q: Quaternion=sim.drone.quaternion
    working.append([record_time,p.x,p.y,p.z,q.x,q.y,q.z,q.w])
    if working.size()>=18000: finish_recording()
  elif working.size()>1: finish_recording()
 if playing and is_instance_valid(ghost):
  if sim.drone.armed and not sim.drone.crashed: replay_clock+=delta
  var duration: float=float(samples[-1][0])-float(samples[0][0])
  if replay_clock>duration: replay_clock=fposmod(replay_clock,duration)
  ghost.global_transform=replay_transform(replay_clock)
 scan_clock+=delta
 if scan_clock>=0.2:
  scan_clock=0
  discover_nearby()
  check_landings(0.2)
func discover_nearby() -> void:
 for place in scenery.discoveries:
  if not discovered.has(place.id) and sim.drone.global_position.distance_to(place.position)<float(place.radius):
   discovered[place.id]=true
   save_progress()
   sim.flash("DISCOVERED / "+str(place.name).to_upper(),5)
func check_landings(delta: float) -> void:
 var p: Vector3=sim.drone.global_position
 for target in scenery.landings:
  if landed.has(target.id): continue
  var offset: Vector3=p-target.position
  var good: bool=not sim.drone.crashed and not sim.drone.armed and absf(offset.x)<float(target.half_size)-sim.drone.ARM and absf(offset.z)<float(target.half_size)-sim.drone.ARM and absf(offset.y-sim.drone.profile.body_height*0.5)<0.045 and sim.drone.linear_velocity.length()<0.15 and sim.drone.global_basis.y.dot(Vector3.UP)>0.98
  landing_holds[target.id]=float(landing_holds.get(target.id,0))+delta if good else 0.0
  if float(landing_holds[target.id])>=2:
   landed[target.id]=true
   save_progress()
   sim.flash("LANDING FOUND / "+str(target.name).to_upper(),5)
func _process(_delta: float) -> void:
 for source in scenery.ambience: source.stream_paused=sim.muted or get_tree().paused
func status() -> String:
 var text: String="%d / %d discoveries  ·  %d / %d landings" % [discovered.size(),scenery.discoveries.size(),landed.size(),scenery.landings.size()]
 if recording: text+="  ·  REC %.0f s" % record_time
 elif playing: text+="  ·  FLIGHT GHOST"
 return text
func _exit_tree() -> void:
 if recording and working.size()>1: finish_recording()
 save_progress()
