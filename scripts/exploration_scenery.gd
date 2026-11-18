extends Node3D
const Geo = preload("res://scripts/exploration_geography.gd")
var field: Node3D
var region: Node3D
var art: Node3D
var stone: Material
var wood: Material
var steel: Material
var concrete: Material
var bark: Material
var water: Material
var discoveries: Array[Dictionary] = []
var landings: Array[Dictionary] = []
var passages: Array[Dictionary] = []
var gondolas: Array[Node3D] = []
var railway_points := PackedVector3Array()
var cable_points := PackedVector3Array()
var elapsed := 0.0
var rice_material: ShaderMaterial
var beacon: SpotLight3D
var ambience: Array[AudioStreamPlayer3D] = []

func build(world: Node3D,mountains: Node3D) -> void:
 process_mode=Node.PROCESS_MODE_PAUSABLE
 field=world
 region=mountains
 art=region.landmark_root.art
 stone=art.pbr("cliff",5,Color("b8beb9"))
 wood=art.pbr("planks",2)
 steel=art.pbr("corrugated",2,Color("8b9590"),0.6)
 concrete=art.pbr("concrete",4)
 water=region.landmark_root.water
 bark=field.mat("897b65")
 bark.albedo_texture=load("res://assets/environment/bark_color.jpg")
 _coast()
 _canyons()
 _delta()
 _farmland()
 _mine()
 _quarry()
 _dam()
 _ridges()
 _lakeshore()
 _debris()
 var forests: Array[Vector3] = []
 for p in [Vector3(-1800,0,-1600),Vector3(-1650,0,-1800),Vector3(-2200,0,-100),Vector3(-1950,0,-900),Vector3(-1750,0,400),Vector3(1700,0,-900),Vector3(1900,0,500),Vector3(-950,0,2100)]: forests.append(p)
 field.get_node("Vegetation").add_mountain_forest(field,forests)
 _sounds()
 _batch_static_visuals()

func ground(x: float,z: float) -> float: return region.surface_height(x,z)
func box(size: Vector3,p: Vector3,material: Material,solid: bool=true) -> MeshInstance3D:
 var mesh: MeshInstance3D=field.box(size,p,material,solid,self)
 mesh.visibility_range_end=1500
 mesh.visibility_range_end_margin=40
 return mesh
func beam(a: Vector3,b: Vector3,width: float,material: Material,solid: bool=true) -> MeshInstance3D:
 var mesh:=box(Vector3(width,width,a.distance_to(b)),(a+b)*0.5,material,solid)
 if a.distance_to(b)>0.001: mesh.look_at(b)
 return mesh
func support(p: Vector3,top: float,width: float=0.6) -> void:
 var bottom:=ground(p.x,p.z)-0.5
 box(Vector3(width,maxf(0.4,top-bottom),width),Vector3(p.x,(top+bottom)*0.5,p.z),stone)
func mark(id: String,label: String,p: Vector3,radius: float=60) -> void:
 discoveries.append({"id":id,"name":label,"position":p,"radius":radius})
func pad(id: String,label: String,p: Vector3,size: float=3) -> void:
 box(Vector3(size,0.12,size),p+Vector3.UP*0.06,wood)
 var paint: Material=field.mat("d5cfaa")
 box(Vector3(size*0.6,0.001,0.06),p+Vector3.UP*0.121,paint,false)
 for side in [-1,1]: box(Vector3(0.06,0.001,size*0.6),p+Vector3(side*size*0.3,0.121,0),paint,false)
 landings.append({"id":id,"name":label,"position":p+Vector3.UP*0.12,"half_size":size*0.5})
func rectangle(p: Vector3,size: Vector2,material: Material) -> MeshInstance3D:
 var mesh:=MeshInstance3D.new()
 var plane:=PlaneMesh.new()
 plane.size=size
 var arrays:=plane.surface_get_arrays(0)
 var colors:=PackedColorArray()
 colors.resize(arrays[Mesh.ARRAY_VERTEX].size())
 colors.fill(Color(0,0,0,1))
 arrays[Mesh.ARRAY_COLOR]=colors
 var geometry:=ArrayMesh.new()
 geometry.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 mesh.mesh=geometry
 mesh.material_override=material
 add_child(mesh)
 mesh.position=p
 mesh.set_meta("batch_plane",size)
 return mesh
func strip(points: PackedVector3Array,width: float,material: Material,solid: bool=false) -> MeshInstance3D:
 var st:=SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(points.size()-1):
  var direction: Vector3=(points[i+1]-points[i]).normalized()
  var right:=Vector3(-direction.z,0,direction.x).normalized()*width*0.5
  for corner in [Vector2(-1,0),Vector2(-1,1),Vector2(1,0),Vector2(1,0),Vector2(-1,1),Vector2(1,1)]:
   var p: Vector3=points[i+int(corner.y)]+right*corner.x
   st.set_uv(Vector2(corner.x,float(i)+corner.y))
   st.set_color(Color(clampf(absf(direction.y)*0.8,0,1),0,0,1))
   st.add_vertex(p)
 st.generate_normals()
 st.generate_tangents()
 var mesh:=MeshInstance3D.new()
 mesh.mesh=st.commit()
 mesh.material_override=material
 add_child(mesh)
 if solid: mesh.create_trimesh_collision()
 return mesh
func rock(p: Vector3,width: float,index: int=0) -> void:
 var bottom:=ground(p.x,p.z)
 # Embed the bounding base below the lowest nearby triangle on sloping scree.
 for offset in [Vector2(width*0.3,0),Vector2(-width*0.3,0),Vector2(0,width*0.3),Vector2(0,-width*0.3)]: bottom=minf(bottom,ground(p.x+offset.x,p.z+offset.y))
 art.prop("rock_09" if index%2 else "namaqualand_boulder_02",Vector3(p.x,bottom-width*0.12,p.z),width,index*0.83)
func tunnel(a: Vector3,b: Vector3,label: String,width: float=12) -> void:
 var shell: MeshInstance3D=region.landmark_root._arch((a+b)*0.5,Vector2(width,width),Vector2(width+11,width+12),a.distance_to(b)+8,true)
 shell.rotation.y=atan2(b.x-a.x,b.z-a.z)
 passages.append({"name":label,"a":a+Vector3.UP*5,"b":b+Vector3.UP*5})
func house(p: Vector3,label: String,ruined: bool=false) -> void:
 var top:=ground(p.x,p.z)+0.4
 for x in [-5,5]:
  for z in [-4,4]: top=maxf(top,ground(p.x+x,p.z+z)+0.3)
 p.y=top
 for x in [-4.5,4.5]:
  for z in [-3.5,3.5]: support(p+Vector3(x,0,z),top)
 box(Vector3(10,0.25,8),p,concrete)
 for side in [-1,1]:
  box(Vector3(0.25,4,8),p+Vector3(side*5,2,0),stone)
  for x in [-3.4,3.4]: box(Vector3(3.2,4,0.25),p+Vector3(x,2,side*4),wood)
  box(Vector3(3.6,1,0.25),p+Vector3(0,3.5,side*4),wood)
  if not (ruined and side==1):
   var roof:=box(Vector3(5.8,0.2,9),p+Vector3(side*2.5,4.8,0),wood)
   roof.rotation.z=-side*0.32
 box(Vector3(0.8,2,0.8),p+Vector3(3.5,5,-2),stone)
 mark(label.to_snake_case(),label,p+Vector3.UP*2,45)
func tower(p: Vector3,label: String) -> void:
 p.y=ground(p.x,p.z)
 for x in [-2.5,2.5]:
  for z in [-2.5,2.5]:
   support(p+Vector3(x,0,z),p.y+12,0.5)
   beam(p+Vector3(x,1,z),p+Vector3(-x,10,z),0.18,wood)
 box(Vector3(6,0.3,6),p+Vector3.UP*12,wood)
 for side in [-1,1]:
  box(Vector3(6,0.12,0.12),p+Vector3(0,13,side*2.8),wood)
  box(Vector3(0.12,0.12,6),p+Vector3(side*2.8,13,0),wood)
 pad(label.to_snake_case(),label,p+Vector3.UP*12.15,2.2)
 mark(label.to_snake_case(),label,p+Vector3.UP*12,55)
func fallen_tree(a: Vector3,b: Vector3) -> void:
 a.y=ground(a.x,a.z)+0.32
 b.y=ground(b.x,b.z)+0.32
 beam(a,b,0.65,bark)
 for i in range(6):
  var p:=a.lerp(b,(i+1)/8.0)
  beam(p,p+Vector3(1.5 if i%2 else -1.5,0.6,0.4),0.12,wood)

func _coast() -> void:
 rectangle(Vector3(-3100,12,1400),Vector2(1800,2100),water)
 rectangle(Vector3(-20000,12,0),Vector2(32000,40000),water)
 tower(Vector3(-2350,0,1200),"Coastal lookout")
 var p:=Vector3(-2510,ground(-2510,1850),1850)
 var white: Material=field.mat("d5d2bf")
 for i in range(6):
  var drum: MeshInstance3D=field.cylinder(3.5-i*0.25,4,p+Vector3.UP*(2+i*4),white if i%2==0 else concrete,self,3.3-i*0.25)
  drum.create_convex_collision()
 box(Vector3(6,0.3,6),p+Vector3.UP*24.2,steel)
 for x in [-2,2]:
  for z in [-2,2]: box(Vector3(0.18,3,0.18),p+Vector3(x,25.5,z),steel)
 box(Vector3(5,0.25,5),p+Vector3.UP*27,steel)
 var lens: Material=field.mat("eed8a2",0.25)
 box(Vector3(1,1,1),p+Vector3.UP*25.5,lens,false)
 beacon=SpotLight3D.new()
 add_child(beacon)
 beacon.position=p+Vector3.UP*25.5
 beacon.spot_range=650
 beacon.spot_angle=18
 beacon.light_color=Color("ffe3ae")
 beacon.light_energy=4
 pad("lighthouse","Lighthouse roof",p+Vector3.UP*27.125,2)
 mark("lighthouse","Old coastal lighthouse",p+Vector3.UP*15,90)
 for i in range(26):
  var z:=750.0+i*55
  rock(Vector3(Geo.shore_x(z)+30+sin(i*2.3)*50,0,z),5+float(i%5)*2,i)
 tunnel(Vector3(-2445,14,1455),Vector3(-2445,14,1545),"Sea cave",12)
 mark("sea_cave","Tidal cave",Vector3(-2445,22,1500),50)
 house(Vector3(-2310,0,1550),"Cove boathouse")
 for island in [Vector2(-2850,1100),Vector2(-2950,1700),Vector2(-2750,2100)]:
  rock(Vector3(island.x,0,island.y),32,int(island.x))

func _canyons() -> void:
 var z: float=-650
 var x: float=Geo.slot_x(z)
 var y:=maxf(ground(x-55,z),ground(x+55,z))+1.5
 box(Vector3(116,0.35,5),Vector3(x,y,z),wood)
 for side in [-1,1]:
  for i in range(9):
   var p:=Vector3(x-56+i*14,y,z+side*2.3)
   box(Vector3(0.15,1.2,0.15),p+Vector3.UP*0.6,wood)
  beam(Vector3(x-57,y+1,z+side*2.3),Vector3(x+57,y+1,z+side*2.3),0.13,wood)
  support(Vector3(x+side*53,0,z),y,3)
 mark("timber_crossing","Old canyon timber bridge",Vector3(x,y,z),65)
 pad("canyon_bridge","Timber bridge landing",Vector3(x,y+0.175,z),2.5)
 for i in range(4):
  var pz: float=-1050+i*240
  var px: float=Geo.slot_x(pz)
  fallen_tree(Vector3(px-13,Geo.slot_y(pz)+7,pz),Vector3(px+13,Geo.slot_y(pz)+9,pz+5))
 for i in range(5):
  var pz: float=-1800-i*85
  var px: float=-1800+sin(i)*40
  var h:=ground(px,pz)
  fallen_tree(Vector3(px,h+2,pz),Vector3(px+24,h+5,pz+8))
 for i in range(3):
  var p:=Vector3(-1880+i*45,0,-1050-i*75)
  p.y=ground(p.x,p.z)-1
  var shell: MeshInstance3D=region.landmark_root._arch(p,Vector2(10+i*2,12+i),Vector2(17+i*2,20+i),13,true)
  shell.rotation.y=i*0.6
 mark("stone_garden","Hidden stone garden",Vector3(-1835,ground(-1835,-1125)+10,-1125),65)

func _delta() -> void:
 for channel in range(3):
  var points:=PackedVector3Array()
  for i in range(106):
   var z: float=1750+i*10
   points.append(Vector3(Geo.delta_x(z,channel),Geo.delta_y(z),z))
  strip(points,36,water)
 region.landmark_root._lake(Vector3(-500,35,2920),Vector2(340,245))
 for i in range(32):
  var z: float=1810+i*31
  var x: float=(Geo.delta_x(z,0)+Geo.delta_x(z,1))*0.5
  rock(Vector3(x,0,z),2+float(i%5),i)
 for i in range(4):
  var z: float=1940+i*180
  var x: float=Geo.delta_x(z,2)
  fallen_tree(Vector3(x-17,Geo.delta_y(z)+5,z),Vector3(x+15,Geo.delta_y(z)+6,z+4))
 house(Vector3(-100,0,2640),"Delta fishing hut")
 mark("delta_islands","Braided river islands",Vector3(Geo.delta_x(2350,1),Geo.delta_y(2350)+8,2350),100)

func _farmland() -> void:
 rice_material=ShaderMaterial.new()
 rice_material.shader=load("res://assets/shaders/rice.gdshader")
 var blade:=QuadMesh.new()
 blade.size=Vector2(0.9,0.95)
 var paddy_water: ShaderMaterial=water.duplicate()
 paddy_water.set_shader_parameter("deep_color",Vector3(0.035,0.065,0.025))
 var transforms: Array[Transform3D]=[]
 for column in range(9):
  var x: float=1900+column*44
  var h: float=145+column*3
  for row in range(12):
   var z: float=910+row*48
   rectangle(Vector3(x+17,h+0.1,z+23.5),Vector2(28,41),paddy_water)
   var compact: bool=RenderingServer.get_current_rendering_method()!="forward_plus"
   for ix in range(6 if compact else 18):
    for iz in range(9 if compact else 26):
     transforms.append(Transform3D(Basis(Vector3.UP,float(ix+iz)*1.7),Vector3(x+4+ix*(4.8 if compact else 1.5),h+0.55,z+4+iz*(4.8 if compact else 1.5))))
  box(Vector3(0.6,1.1,582),Vector3(x+33,h+0.55,1200),stone)
 var batch:=MultiMesh.new()
 batch.transform_format=MultiMesh.TRANSFORM_3D
 batch.mesh=blade
 batch.instance_count=transforms.size()
 for i in range(transforms.size()): batch.set_instance_transform(i,transforms[i])
 var crops:=MultiMeshInstance3D.new()
 crops.multimesh=batch
 crops.material_override=rice_material
 crops.visibility_range_end=600
 crops.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(crops)
 for i in range(4): house(Vector3(2350+(i%2)*28,0,1160+(i/2)*35),"Terrace hamlet "+str(i+1))
 var channel:=PackedVector3Array()
 for i in range(65):
  var x: float=1900+i*6
  channel.append(Vector3(x,145+floorf((x-1900)/44)*3+0.15,1500))
 strip(channel,3,paddy_water)
 mark("terraces","Rice terrace foothills",Vector3(2070,163,1200),110)
 for side in [-1,1]:
  for end in [-1,1]: support(Vector3(2390+side,0,1210+end),181.6,0.2)
 pad("farm_roof","Hamlet landing platform",Vector3(2390,181.6,1210),3)

func _mine() -> void:
 for i in range(Geo.MINE.size()-1):
  var a: Vector2=Geo.MINE[i]
  var b: Vector2=Geo.MINE[i+1]
  tunnel(Vector3(a.x,110,a.y),Vector3(b.x,110,b.y),"Mine gallery "+str(i+1))
  var direction: Vector2=(b-a).normalized()
  var right:=Vector2(-direction.y,direction.x)
  for t in [0.15,0.45,0.75]:
   var p:=a.lerp(b,t)
   for side in [-1,1]: box(Vector3(0.4,10,0.4),Vector3(p.x+right.x*side*9,115,p.y+right.y*side*9),wood)
   beam(Vector3(p.x-right.x*9,120,p.y-right.y*9),Vector3(p.x+right.x*9,120,p.y+right.y*9),0.5,wood)
  for side in [-1,1]: beam(Vector3(a.x+right.x*side,110.15,a.y+right.y*side),Vector3(b.x+right.x*side,110.15,b.y+right.y*side),0.12,steel)

 for p in [Vector3(-2075,0,495),Vector3(-1820,0,790)]: house(p,"Abandoned mine office "+str(p.x),true)
 for i in range(8): art.prop("wooden_crate_01",Vector3(-2078+i*3,110,525),1.3,i)
 mark("mine","Branching abandoned mine",Vector3(-2050,117,540),70)
 var wreck:=Vector3(-1800,ground(-1800,395)+1,395)
 var body:=box(Vector3(4,1.5,2),wreck,steel)
 body.rotation.z=0.3
 box(Vector3(2,0.9,1.8),wreck+Vector3(0.3,1,0),steel)
 mark("wreck","Forgotten expedition wreck",wreck,35)

func _quarry() -> void:
 for i in range(45):
  var theta: float=i*2.4
  var r: float=30+sqrt(float(i)/45)*220
  rock(Vector3(2450+cos(theta)*r,0,-300+sin(theta)*r),3+float(i%7),i)
 for i in range(3):
  var a:=Vector3(2340+i*80,0,-370+i*60)
  var b:=a+Vector3(100,0,55)
  a.y=ground(a.x,a.z)+12
  b.y=ground(b.x,b.z)+12
  var deck:=box(Vector3(3,0.4,a.distance_to(b)),(a+b)*0.5,steel)
  deck.look_at(b)
  for side in [-1,1]: beam(a+Vector3(side*1.5,1,0),b+Vector3(side*1.5,1,0),0.16,steel)
  for p in [a,b]:
   support(p+Vector3(-1,0,0),p.y,0.4)
   support(p+Vector3(1,0,0),p.y,0.4)
 house(Vector3(2470,0,-320),"Quarry crusher house",true)
 var p:=Vector3(2535,ground(2535,-230),-230)
 for side in [-1,1]: box(Vector3(0.35,20,0.35),p+Vector3(side*1.5,10,0),concrete)
 box(Vector3(3.5,1,3.5),p+Vector3.UP*20,concrete)
 pad("chimney","Crusher chimney landing",p+Vector3.UP*20.5,1.8)
 mark("quarry","Stepped quarry and conveyors",Vector3(2450,145,-300),110)
 # A ground-following switchback railway continues from the existing viaduct.
 var controls: Array[Vector2]=[Vector2(1950,-1411),Vector2(2120,-1200),Vector2(1730,-940),Vector2(2060,-720),Vector2(2400,-500)]
 var curve:=Curve2D.new()
 curve.bake_interval=8
 for i in range(controls.size()):
  var tangent: Vector2=(controls[mini(i+1,controls.size()-1)]-controls[maxi(i-1,0)])*0.17
  curve.add_point(controls[i],-tangent,tangent)
 var track:=PackedVector3Array()
 for p2 in curve.get_baked_points(): track.append(Vector3(p2.x,ground(p2.x,p2.y)+0.25,p2.y))
 railway_points=track
 strip(track,4,art.pbr("gravel",2),true)
 var ties: Array[Transform3D]=[]
 var rails: Array[Transform3D]=[]
 for i in range(track.size()-1):
  var p3: Vector3=track[i]
  var forward: Vector3=(track[i+1]-p3).normalized()
  var right:=forward.cross(Vector3.UP).normalized()
  for side in [-1,1]:
   rails.append(Transform3D(Basis.looking_at(forward).scaled(Vector3(0.1,0.1,track[i].distance_to(track[i+1]))),(track[i]+track[i+1])*0.5+right*side))
  ties.append(Transform3D(Basis.looking_at(forward),p3))
 _boxes(ties,Vector3(3,0.14,0.25),wood)
 _boxes(rails,Vector3.ONE,steel,true)

func _boxes(transforms: Array[Transform3D],size: Vector3,material: Material,solid: bool=false) -> void:
 var mesh:=BoxMesh.new()
 mesh.size=size
 var batch:=MultiMesh.new()
 batch.transform_format=MultiMesh.TRANSFORM_3D
 batch.mesh=mesh
 batch.instance_count=transforms.size()
 for i in range(transforms.size()): batch.set_instance_transform(i,transforms[i])
 var node:=MultiMeshInstance3D.new()
 node.multimesh=batch
 node.material_override=material
 node.visibility_range_end=1400
 add_child(node)
 if solid:
  var body:=StaticBody3D.new()
  add_child(body)
  for transform in transforms:
   var shape:=CollisionShape3D.new()
   var geometry:=BoxShape3D.new()
   geometry.size=size*transform.basis.get_scale().abs()
   shape.shape=geometry
   shape.transform=Transform3D(transform.basis.orthonormalized(),transform.origin)
   body.add_child(shape)

func _dam() -> void:
 var st:=SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(128):
  for j in [-1,i,i+1]:
   var angle: float=j*TAU/128
   var p:=Vector3(2300,270,-1950) if j==-1 else Vector3(2300+cos(angle)*270,270,minf(-1795,-1950+sin(angle)*270))
   st.set_color(Color(0,0,0,1))
   st.set_normal(Vector3.UP)
   st.set_uv(Vector2(p.x,p.z)*0.02)
   st.add_vertex(p)
 var reservoir:=MeshInstance3D.new()
 reservoir.mesh=st.commit()
 reservoir.material_override=water
 add_child(reservoir)
 for i in range(26):
  var x: float=2050+i*20
  var floor_height:=minf(ground(x,-1795),235)
  box(Vector3(20,284-floor_height,9),Vector3(x,(284+floor_height)*0.5,-1795),concrete)
  box(Vector3(0.4,14,24),Vector3(x-9,263,-1784),concrete)
 box(Vector3(520,1,13),Vector3(2300,284.5,-1795),art.pbr("gravel",2))
 for side in [-1,1]: box(Vector3(520,1,0.35),Vector3(2300,286,-1795+side*6),steel)
 rectangle(Vector3(2300,240,-1630),Vector2(50,300),water)
 var flow:=PackedVector3Array([Vector3(2300,270,-1799),Vector3(2300,269,-1789),Vector3(2300,242,-1765),Vector3(2300,240,-1735)])
 strip(flow,18,water)
 house(Vector3(2430,0,-1690),"Hydroelectric station")
 for i in range(3):
  var a:=Vector3(2360+i*12,263,-1800)
  var b:=Vector3(2415+i*6,254,-1700)
  beam(a,b,1.4,steel)
 pad("dam","Dam crest landing",Vector3(2240,285,-1795),3)
 mark("dam","Mountain dam and hydro station",Vector3(2300,287,-1795),120)

func _ridges() -> void:
 for p in [Vector3(1050,0,-2650),Vector3(600,0,-2540),Vector3(-1600,0,-2010)]: tower(p,"Ridge lookout "+str(p.x))
 var a:=Vector3(1050,ground(1050,-2760)+16,-2760)
 var b:=Vector3(300,ground(300,-2500)+16,-2500)
 for j in range(9):
  var p:=a.lerp(b,j/8.0)
  p.y=maxf(p.y,ground(p.x,p.z)+18)
  cable_points.append(p)
 # Lift adjacent supports together wherever a ridge would intersect the sag.
 for i in range(cable_points.size()-1):
  var lift:=0.0
  for j in range(25):
   var p:=_cable(i,j/24.0)
   lift=maxf(lift,field._terrain_height(p.x,p.z)+12-p.y)
  cable_points[i]+=Vector3.UP*lift
  cable_points[i+1]+=Vector3.UP*lift
 for j in range(cable_points.size()):
  var p: Vector3=cable_points[j]
  var floor_height:=ground(p.x,p.z)
  for side in [-1,1]: box(Vector3(0.7,p.y-floor_height,0.7),Vector3(p.x+side*3,(p.y+floor_height)*0.5,p.z),steel)
  box(Vector3(8,0.5,0.5),p,steel)
  if j in [0,8]: house(Vector3(p.x+14,0,p.z),"Cable car station "+str(j))
 for i in range(cable_points.size()-1):
  for j in range(10):
   var p:=_cable(i,j/10.0)
   var q:=_cable(i,(j+1)/10.0)
   beam(p,q,0.065,steel,false)
 for i in range(3):
  var car:=Node3D.new()
  add_child(car)
  var cabin:=box(Vector3(3.2,0.9,2.5),Vector3.ZERO,steel)
  cabin.reparent(car,false)
  cabin.position=Vector3(0,-4,0)
  var glass: Material=field.mat("94b9bc",0.15)
  glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  glass.albedo_color.a=0.4
  for side in [-1,1]:
   var window:=box(Vector3(0.05,1.5,2.5),Vector3.ZERO,glass)
   window.reparent(car,false)
   window.position=Vector3(side*1.6,-2.8,0)
   var front:=box(Vector3(3.2,1.5,0.05),Vector3.ZERO,glass)
   front.reparent(car,false)
   front.position=Vector3(0,-2.8,side*1.25)
  var roof:=box(Vector3(3.3,0.18,2.6),Vector3.ZERO,steel)
  roof.reparent(car,false)
  roof.position=Vector3(0,-2,0)
  var hanger:=box(Vector3(0.1,2,0.1),Vector3.ZERO,steel)
  hanger.reparent(car,false)
  hanger.position=Vector3(0,-1,0)
  car.set_meta("phase",float(i)/3)
  gondolas.append(car)
 mark("cableway","Summit cableway",a,90)
 # Short avalanche gallery with open valley-side bays.
 var p:=Vector3(1750,ground(1750,-2200)+1,-2200)
 for i in range(8):
  for side in [-1,1]: support(p+Vector3(side*5,0,i*8),p.y+7,0.6)
 box(Vector3(12,0.6,65),p+Vector3(0,7.3,28),concrete)
 box(Vector3(11,0.2,65),p+Vector3(0,0.1,28),concrete)
 mark("gallery","Alpine avalanche gallery",p+Vector3.UP*4,70)
 for peak in [Vector2(2400,-2700),Vector2(2150,-3100),Vector2(1800,-2900)]: rock(Vector3(peak.x,0,peak.y),9,int(peak.x))
 mark("bowl","Snow bowl descent",Vector3(2100,650,-2650),130)
func _cable(index: int,t: float) -> Vector3:
 var p:=cable_points[index].lerp(cable_points[index+1],t)
 p.y-=sin(t*PI)*5
 return p
func _process(delta: float) -> void:
 elapsed+=delta
 if is_instance_valid(beacon): beacon.rotation=Vector3(-0.1,elapsed*0.3,0)
 for car in gondolas:
  var t: float=fposmod(elapsed*0.014+float(car.get_meta("phase")),2)
  if t>1: t=2-t
  var segment:=minf(t*(cable_points.size()-1),cable_points.size()-1.001)
  car.position=_cable(int(segment),fposmod(segment,1))

func _lakeshore() -> void:
 var p:=Vector3(-250,70,-1445)
 box(Vector3(5,0.25,22),p+Vector3(0,1,0),wood)
 for x in [-2,2]:
  for z in [-9,9]: support(p+Vector3(x,0,z),71,0.3)
 pad("dock","Lakeside dock",p+Vector3.UP*1.125,2.5)
 house(Vector3(-280,0,-1350),"Lake boathouse")
 var island:=Vector3(-205,70,-1600)
 # Timber platform on lake piers is a small landing destination.
 for side in [-1,1]: support(island+Vector3(side*2,0,0),71,0.3)
 pad("lake_platform","Lake research platform",island+Vector3.UP,3)
 for i in range(7):
  var x: float=-200+i*5
  box(Vector3(2,4,1),Vector3(x,69,-1690+sin(i)*5),stone)
 mark("drowned_ruin","Drowned lakeside ruins",Vector3(-190,73,-1690),45)
 var islet:=Vector3(-300,ground(-300,-1640),-1640)
 pad("lake_islet","Lake islet landing",islet,2.5)
 rock(islet+Vector3(9,0,4),4,3)
 # A dry side entrance reaches an alcove behind the waterfall; crossing the
 # actual water curtain still triggers the normal water-contact failure.
 var c:=Vector3(region.topology.river_x(-2400)+50,region.topology.river_y(-2385)+15,-2410)
 region.landmark_root._arch(c,Vector2(10,12),Vector2(24,60),72,true)
 passages.append({"name":"Waterfall alcove","a":c+Vector3(0,5,33),"b":c+Vector3(0,5,-33)})
 box(Vector3(3,0.2,3),c+Vector3.UP*0.1,wood)
 art.prop("wooden_crate_01",c+Vector3(4,0,0),1.1,0.3)
 for side in [-1,1]:
  var tent:=box(Vector3(1.8,0.04,3),c+Vector3(5+side*0.65,0.8,-6),field.mat("8a7250"),false)
  tent.rotation.z=-side*0.8
 mark("waterfall_camp","Camp behind the waterfall",c+Vector3.UP*3,25)
 pad("secret_camp","Waterfall alcove landing",c+Vector3.UP*0.2,2.8)

func _debris() -> void:
 for i in range(72):
  var theta: float=i*2.399
  var radius:=sqrt(float(i)/72)*310
  rock(Vector3(-2150+cos(theta)*radius,0,-2200+sin(theta)*radius),2+float(i%8)*1.5,i)
 for i in range(8):
  var a:=Vector3(-2290+i*38,0,-2320+sin(i)*55)
  a.y=ground(a.x,a.z)+0.5
  fallen_tree(a,a+Vector3(18,5,12))
 house(Vector3(-2450,0,-1950),"Hidden forest cabin")
 mark("landslide","Landslide scar and scree fan",Vector3(-2150,ground(-2150,-2250)+15,-2250),100)

func _sounds() -> void:
 var rush:=_sound(false)
 var birds:=_sound(true)
 for p in [Vector3(region.topology.river_x(-2400),region.topology.river_y(-2400),-2400),Vector3(region.topology.river_x(-3070),region.topology.river_y(-3070),-3070),Vector3(2300,250,-1770),Vector3(-2800,15,1500)]: _source(rush,p,450,-19)
 for p in [Vector3(-1800,ground(-1800,-1800)+8,-1800),Vector3(2100,155,1200),Vector3(-400,45,2400)]: _source(birds,p,220,-23)
func _source(stream: AudioStreamWAV,p: Vector3,distance_limit: float,volume: float) -> void:
 var node:=AudioStreamPlayer3D.new()
 node.stream=stream
 node.position=p
 node.max_distance=distance_limit
 node.unit_size=30
 node.volume_db=volume
 add_child(node)
 node.play()
 ambience.append(node)
func _sound(birds: bool) -> AudioStreamWAV:
 var random:=RandomNumberGenerator.new()
 random.seed=718 if birds else 224
 var data:=PackedByteArray()
 var count:=22050*6
 data.resize(count*2)
 var low:=0.0
 for i in range(count):
  var t:=float(i)/22050
  low=lerpf(low,random.randf_range(-1,1),0.12)
  var sample:=low*0.8+random.randf_range(-0.05,0.05)
  if birds:
   var phase:=fposmod(t,1.5)
   sample=sin(TAU*(1700*t+150*sin(t*19)))*exp(-phase*14)*0.3
  sample*=minf(1,minf(float(i)/500,float(count-i)/500))
  data.encode_s16(i*2,int(clampf(sample,-1,1)*30000))
 var stream:=AudioStreamWAV.new()
 stream.format=AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate=22050
 stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
 stream.loop_end=count
 stream.data=data
 return stream

func _batch_static_visuals() -> void:
 # Keep the original collision nodes; batch only stationary visual geometry.
 var groups: Dictionary={}
 for child in get_children():
  if not child is MeshInstance3D: continue
  var node:=child as MeshInstance3D
  var primitive: String=""
  var scale: Vector3=Vector3.ONE
  if node.mesh is BoxMesh:
   primitive="box"
   scale=node.mesh.size
  elif node.has_meta("batch_plane"):
   primitive="plane"
   var size: Vector2=node.get_meta("batch_plane")
   scale=Vector3(size.x,1,size.y)
  else: continue
  var cell:=Vector2i(floori(node.position.x/400),floori(node.position.z/400))
  var key: String=primitive+str(node.material_override.get_instance_id())+str(cell)
  if not groups.has(key): groups[key]={"material":node.material_override,"primitive":primitive,"origin":Vector3(cell.x*400+200,0,cell.y*400+200),"transforms":[]}
  var transform: Transform3D=node.transform
  transform.basis=transform.basis*Basis.from_scale(scale)
  transform.origin-=groups[key].origin
  groups[key].transforms.append(transform)
  node.mesh=null
 var cube:=BoxMesh.new()
 cube.size=Vector3.ONE
 var plane:=PlaneMesh.new()
 plane.size=Vector2.ONE
 var arrays:=plane.surface_get_arrays(0)
 var colors:=PackedColorArray()
 colors.resize(arrays[Mesh.ARRAY_VERTEX].size())
 colors.fill(Color(0,0,0,1))
 arrays[Mesh.ARRAY_COLOR]=colors
 var unit_plane:=ArrayMesh.new()
 unit_plane.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 for group in groups.values():
  var batch:=MultiMesh.new()
  batch.transform_format=MultiMesh.TRANSFORM_3D
  batch.mesh=cube if group.primitive=="box" else unit_plane
  batch.instance_count=group.transforms.size()
  for i in range(batch.instance_count): batch.set_instance_transform(i,group.transforms[i])
  var node:=MultiMeshInstance3D.new()
  node.multimesh=batch
  node.material_override=group.material
  add_child(node)
  node.position=group.origin
  node.visibility_range_end=0 if group.primitive=="plane" else 1500
  if group.primitive=="plane": node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  node.visibility_range_end_margin=40
