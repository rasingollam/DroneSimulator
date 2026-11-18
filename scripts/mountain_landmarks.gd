extends Node3D
## Exploration routes use real openings and collision, with no compulsory gates.
var field: Node3D
var region: Node3D
var topo: RefCounted
var art: Node3D
var stone: Material
var timber: Material
var water: ShaderMaterial
var forest_centres: Array[Vector3] = []
var passages: Array[Dictionary] = []

func build(world: Node3D,mountains: Node3D) -> void:
	field = world
	region = mountains
	topo = region.topology
	art = Node3D.new()
	art.set_script(load("res://scripts/scenery_library.gd"))
	add_child(art)
	stone = art.pbr("cliff",4.0)
	timber = art.pbr("planks",2.0)
	water = ShaderMaterial.new()
	water.shader = load("res://assets/shaders/alpine_water.gdshader" if RenderingServer.get_current_rendering_method()=="forward_plus" else "res://assets/shaders/alpine_water_compat.gdshader")
	_river()
	_lake(Vector3(-250,70,-1600),Vector2(280,360))
	_lake(Vector3(topo.river_x(-3350),topo.river_y(-3350),-3350),Vector2(218,214))
	var arch_z := -2180.0
	var natural := Vector3(topo.river_x(arch_z),topo.river_y(arch_z)+1,arch_z)
	_arch(natural,Vector2(23,25),Vector2(32,33),16,true)
	for side in [-1,1]:
		var foot := natural+Vector3(side*30,0,0)
		foot.y = region.surface_height(foot.x,foot.z)-1.5
		art.prop("namaqualand_boulder_02",foot,12,side*0.4)
	passages.append({"name":"Natural arch","centre":natural+Vector3.UP*9,"direction":Vector3.FORWARD,"width":26.0})
	var cave := Vector3(topo.cave_x(),topo.river_y(-2740)+18,-2740)
	_arch(cave,Vector2(11,12),Vector2(19,20),60,true)
	for end in [-1,1]:
		for side in [-1,1]:
			var edge := cave+Vector3(side*18,0,end*29)
			edge.y = region.surface_height(edge.x,edge.z)-2.5
			art.prop("namaqualand_boulder_02",edge,9,end*0.7+side)
	passages.append({"name":"Cave","centre":cave+Vector3.UP*5,"direction":Vector3.FORWARD,"width":12.0})
	var tunnel := Vector3(topo.road_x(-2890),topo.road_y(-2890),-2890)
	_arch(tunnel,Vector2(6,7),Vector2(13,15),72,true)
	passages.append({"name":"Road tunnel","centre":tunnel+Vector3.UP*3,"direction":Vector3.FORWARD,"width":7.0})
	_stone_bridge()
	_viaduct()
	_cliff_road()
	_village()
	_cabin()
	for i in range(36):
		var z := -1800.0-i*43
		if absf(z+2400)<50 or absf(z+3075)<50: continue
		var side := -1 if i%2==0 else 1
		var p := Vector3(topo.river_x(z)+side*(20+i%4*5),0,z)
		p.y = region.surface_height(p.x,p.z)-1.5
		art.prop("rock_09" if i%3 else "namaqualand_boulder_02",p,4+float(i%5),i*0.7)
	for i in range(topo.launches.size()):
		_launch_site(i)
	for z in [-1800.0,-2050.0,-2260.0,-2660.0,-2930.0,-3170.0]:
		for side in [-1,1]:
			forest_centres.append(Vector3(topo.river_x(z)+side*130,0,z))
	forest_centres.append(Vector3(-1380,0,-1760))
	forest_centres.append(Vector3(-1220,0,-1900))
	field.get_node("Vegetation").add_mountain_forest(field,forest_centres)

func box(size: Vector3,p: Vector3,material: Material,collision: bool=true) -> MeshInstance3D:
	var mesh: MeshInstance3D = field.box(size,p,material,collision,self)
	mesh.visibility_range_end = 1700
	mesh.visibility_range_end_margin = 50
	return mesh

func _triangle(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,hint: Vector3) -> void:
	var normal := (c-a).cross(b-a).normalized()
	var vertices: Array[Vector3] = [a,b,c]
	if normal.dot(hint)<0:
		vertices = [a,c,b]
		normal = -normal
	for p in vertices:
		st.set_normal(normal)
		st.set_uv(Vector2(p.x,p.y)*0.15)
		st.add_vertex(p)

func _quad(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3,hint: Vector3) -> void:
	_triangle(st,a,b,c,hint)
	_triangle(st,b,d,c,hint)

func _arch(p: Vector3,inside: Vector2,outside: Vector2,length: float,natural: bool) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 36
	if natural:
		_natural_shell(st,inside,outside,length)
	for i in range(0 if natural else count):
		var a := i*PI/count
		var b := (i+1)*PI/count
		var ra := outside+(Vector2.ONE*(sin(a*7.0)*1.8+sin(a*13)*0.6) if natural else Vector2.ZERO)
		var rb := outside+(Vector2.ONE*(sin(b*7.0)*1.8+sin(b*13)*0.6) if natural else Vector2.ZERO)
		var ia := Vector3(cos(a)*inside.x,sin(a)*inside.y,0)
		var ib := Vector3(cos(b)*inside.x,sin(b)*inside.y,0)
		var oa := Vector3(cos(a)*ra.x,sin(a)*ra.y,0)
		var ob := Vector3(cos(b)*rb.x,sin(b)*rb.y,0)
		var front := Vector3(0,0,length*0.5)
		var back := -front
		var outward := Vector3(cos((a+b)/2),sin((a+b)/2),0)
		_quad(st,oa+front,ob+front,oa+back,ob+back,outward)
		_quad(st,ia+front,ib+front,ia+back,ib+back,-outward)
		_quad(st,ia+front,ib+front,oa+front,ob+front,Vector3.BACK)
		_quad(st,ia+back,ib+back,oa+back,ob+back,Vector3.FORWARD)
	if natural:
		st.index()
		st.generate_normals()
	st.generate_tangents()
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	mesh.material_override = stone
	add_child(mesh)
	mesh.position = p
	mesh.create_trimesh_collision() # A convex hull would incorrectly seal the opening.
	return mesh

func _river() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(765):
		# End at lake levels: overlapping coplanar water created flickering triangles.
		var za := -1750.0-index*2.0
		var zb := za-2.0
		for cross_index in range(8):
			for corner in [Vector2(0,0),Vector2(0,1),Vector2(1,0),Vector2(1,0),Vector2(0,1),Vector2(1,1)]:
				var z := lerpf(za,zb,corner.y)
				var fraction: float = (cross_index+corner.x)/8.0
				var width := 22.0+sin(z*0.021)*1.5+sin(z*0.053)*0.7
				var foam := clampf(absf(topo.river_y(z-1)-topo.river_y(z+1))/2.5,0,1)
				st.set_color(Color(foam,0,0,1))
				st.set_uv(Vector2(fraction,(-z-1500)/15))
				st.add_vertex(Vector3(topo.river_x(z)+(fraction*2-1)*width,topo.river_y(z),z))
	st.generate_normals()
	st.generate_tangents()
	var river := MeshInstance3D.new()
	river.mesh = st.commit()
	river.material_override = water
	add_child(river)
	if RenderingServer.get_current_rendering_method()!="forward_plus": return
	for z in [-2385.0,-3060.0]:
		var mist := FogVolume.new()
		mist.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
		mist.size = Vector3(48,25,45)
		var fog := FogMaterial.new()
		fog.density = 0.035
		fog.albedo = Color("c1d8d7")
		mist.material = fog
		add_child(mist)
		mist.position = Vector3(topo.river_x(z),topo.river_y(z)+9,z+8)

func _lake(p: Vector3,radius: Vector2) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(96):
		for j in [-1,i,i+1]:
			var angle: float = j*TAU/96
			var v := Vector3.ZERO if j==-1 else Vector3(cos(angle)*radius.x,0,sin(angle)*radius.y)
			st.set_normal(Vector3.UP)
			st.set_color(Color(0,0,0,1))
			st.set_uv(Vector2(v.x/radius.x,v.z/radius.y)*0.5+Vector2.ONE*0.5)
			st.add_vertex(v)
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	mesh.material_override = water
	add_child(mesh)
	mesh.position = p
	for i in range(18):
		var theta := i*TAU/18
		var rock := p+Vector3(cos(theta)*radius.x*0.55,0,sin(theta)*radius.y*0.55)
		rock.y = region.surface_height(rock.x,rock.z)-0.8
		art.prop("rock_09",rock,3+float(i%4),theta)

func _stone_bridge() -> void:
	var z := -2050.0
	var centre := Vector3(topo.river_x(z),topo.river_y(z)+3,z)
	for i in [-1,0,1]:
		_arch(centre+Vector3(i*40,0,0),Vector2(18,18),Vector2(22,23.5),9,false)
	box(Vector3(126,1,10),centre+Vector3.UP*23.8,art.pbr("concrete",3))
	for side in [-1,1]:
		box(Vector3(126,1,0.45),centre+Vector3(0,24.8,side*4.7),stone)
	for x in [-60,-20,20,60]:
		var ground: float = field._terrain_height(centre.x+x,z)-3
		var top := centre.y+24
		box(Vector3(4,maxf(1,top-ground),9),Vector3(centre.x+x,(top+ground)/2,z),stone)
	passages.append({"name":"Stone bridge","centre":centre+Vector3.UP*8,"direction":Vector3.FORWARD,"width":20.0})

func _viaduct() -> void:
	var x := 1500.0
	var z: float = topo.branch_z(x)
	var y: float = topo.viaduct_y()
	for i in range(-5,6):
		var centre := Vector3(x+i*22,y-30,z)
		_arch(centre,Vector2(9,24),Vector2(12,30),8,false)
		var ground: float = field._terrain_height(centre.x+11,z)-1
		box(Vector3(3,y-ground,8),Vector3(centre.x+11,(y+ground)/2,z),stone)
	box(Vector3(250,0.7,10),Vector3(x,y,z),art.pbr("gravel",2))
	var iron: Material = field.mat("484e4d",0.55)
	for offset in [-1.0,1.0]:
		box(Vector3(250,0.15,0.15),Vector3(x,y+0.55,z+offset),iron)
	for i in range(125):
		box(Vector3(0.2,0.18,3),Vector3(x-124+i*2,y+0.25,z),timber,false)
	for side in [-1,1]:
		for i in range(65):
			var a := Vector3(x+side*(125+i*5),0,z)
			var b := Vector3(x+side*(130+i*5),0,z)
			a.y = topo.height(a.x,a.z)+0.2
			b.y = topo.height(b.x,b.z)+0.2
			for offset in [-1.0,1.0]:
				var rail := box(Vector3(a.distance_to(b),0.15,0.15),(a+b)*0.5+Vector3(0,0,offset),iron)
				rail.rotation.z = atan2(b.y-a.y,b.x-a.x)
	passages.append({"name":"Rail viaduct","centre":Vector3(x,y-19,z),"direction":Vector3.FORWARD,"width":12.0})

func _cliff_road() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(280):
		var z := -1800.0-i*5
		for offset in [Vector2(-3,0),Vector2(3,0),Vector2(-3,-5),Vector2(3,0),Vector2(3,-5),Vector2(-3,-5)]:
			var pz: float = z+offset.y
			var px: float = topo.road_x(pz)+offset.x
			var y: float = topo.height(topo.road_x(pz),pz)+0.3
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(px,pz)*0.25)
			st.add_vertex(Vector3(px,y,pz))
		if i%7==0:
			var p := Vector3(topo.road_x(z)-4,topo.height(topo.road_x(z),z),z)
			box(Vector3(0.18,1.2,0.18),p+Vector3.UP*0.6,timber)
			if i<273:
				var next_z := z-35
				var next := Vector3(topo.road_x(next_z)-4,topo.height(topo.road_x(next_z),next_z),next_z)
				var rail := box(Vector3(0.12,0.14,p.distance_to(next)),(p+next)*0.5+Vector3.UP*0.9,timber)
				rail.look_at(next+Vector3.UP*0.9)
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	mesh.material_override = art.pbr("gravel",2,Color("b6b1a4"))
	add_child(mesh)
	mesh.create_trimesh_collision()

func _village() -> void:
	for i in range(7):
		var p := Vector3(-1085+(i%3)*30,0,-2575+(i/3)*27)
		p.y = field._terrain_height(p.x,p.z)
		var wall: Material = art.pbr("cliff",2.5,Color("b8b7ac"))
		box(Vector3(10,0.2,8),p+Vector3.UP*0.1,stone)
		for side in [-1,1]:
			box(Vector3(0.3,5,8),p+Vector3(side*5,2.5,0),wall)
			for x in [-3.2,3.2]:
				box(Vector3(3.6,5,0.3),p+Vector3(x,2.5,side*4),wall)
			box(Vector3(2.8,1.5,0.3),p+Vector3(0,4.25,side*4),wall)
			if not (i==2 and side==1):
				var roof := box(Vector3(5.6,0.18,9),p+Vector3(side*2.5,5.7,0),timber)
				roof.rotation.z = -side*0.28
		for beam in [-2.0,2.0]:
			box(Vector3(9.8,0.15,0.15),p+Vector3(0,4.6,beam),timber)
		if i%2==0:
			art.prop("wooden_crate_01",p+Vector3(-3,0.2,1),1.2,i)
	passages.append({"name":"Village house","centre":Vector3(-1085,field._terrain_height(-1085,-2575)+1.5,-2575),"direction":Vector3.FORWARD,"width":2.0})

func _launch_site(index: int) -> void:
	var site: Dictionary = topo.launches[index]
	var p: Vector3 = site.position
	box(Vector3(5,0.12,5),p+Vector3.UP*0.06,timber)
	var paint: Material = field.mat("e1d6b7")
	for x in [-0.8,0.8]:
		box(Vector3(0.12,0.001,2),p+Vector3(x,0.121,0),paint,false)
	box(Vector3(1.6,0.001,0.12),p+Vector3(0,0.121,0),paint,false)
	box(Vector3(0.14,2,0.14),p+Vector3(-4,1,4),timber)
	box(Vector3(4,0.65,0.10),p+Vector3(-2,1.8,4),timber)
	field.label_3d(site.name.to_upper(),p+Vector3(-2,1.8,4.07),22,Color("e6dac1"),self)
	if index in [0,2,4]:
		for tent in range(2):
			var centre := p+Vector3(9+tent*5,0,5)
			centre.y = field._terrain_height(centre.x,centre.z)
			var cloth: Material = field.mat("627968" if tent==0 else "9b6b43")
			for side in [-1,1]:
				var roof := box(Vector3(1.8,0.035,3.5),centre+Vector3(side*0.65,0.75,0),cloth,false)
				roof.rotation.z = -side*0.85
			box(Vector3(0.06,1.5,0.06),centre+Vector3(0,0.75,-1.6),timber)
		art.prop("wooden_crate_01",p+Vector3(5,0,5),1.0,0.3)
		for i in range(8):
			var theta := i*TAU/8
			var rock := p+Vector3(6+cos(theta),0,-5+sin(theta))
			rock.y = field._terrain_height(rock.x,rock.z)-0.15
			art.prop("rock_09",rock,0.65,theta,false)


func _cabin() -> void:
	var p := Vector3(-470,0,-1650)
	for x in [-5,5]:
		for z in [-4,4]: p.y = maxf(p.y,region.surface_height(p.x+x,p.z+z)+0.3)
	# Piers reach the ground even on the sloping lakeshore.
	for x in [-5,5]:
		for z in [-4,4]:
			var bottom: float = region.surface_height(p.x+x,p.z+z)-0.5
			box(Vector3(0.5,p.y-bottom,0.5),Vector3(p.x+x,(p.y+bottom)/2,p.z+z),stone)
	box(Vector3(11,0.25,10),p,timber)
	for side in [-1,1]:
		box(Vector3(0.2,4,8),p+Vector3(side*5,2,-0.5),timber)
		box(Vector3(3.6,4,0.2),p+Vector3(side*3.2,2,3.5),timber)
		box(Vector3(0.18,3.5,0.18),p+Vector3(side*5,1.75,4.5),timber)
		var roof := box(Vector3(5.8,0.18,10),p+Vector3(side*2.5,4.9,0),timber)
		roof.rotation.z = -side*0.35
	box(Vector3(10,4,0.2),p+Vector3(0,2,-4.5),timber)
	box(Vector3(2.8,1.2,0.2),p+Vector3(0,3.4,3.5),timber)
	box(Vector3(0.8,3,0.8),p+Vector3(3,5,-2),stone)
	art.prop("wooden_crate_01",p+Vector3(-3,0.15,4),0.9,0.2)

func _shell_point(theta: float,t: float,radius: Vector2,length: float,inner: bool) -> Vector3:
	var z := (t-0.5)*length
	var strength := 0.035 if inner else 0.13
	var ripple := 1.0+strength*(sin(theta*5+z*0.17)+0.4*sin(theta*11-z*0.11))
	var edge := sin(theta*3+0.3)*1.8+sin(theta*7)*0.6
	return Vector3(cos(theta)*radius.x*ripple,sin(theta)*radius.y*ripple,z+edge)

func _natural_shell(st: SurfaceTool,inside: Vector2,outside: Vector2,length: float) -> void:
	st.set_smooth_group(0)
	for i in range(48):
		var a := i*PI/48
		var b := (i+1)*PI/48
		var hint := Vector3(cos((a+b)*0.5),sin((a+b)*0.5),0)
		for j in range(12):
			var t := j/12.0
			var u := (j+1)/12.0
			_quad(st,_shell_point(a,t,outside,length,false),_shell_point(b,t,outside,length,false),_shell_point(a,u,outside,length,false),_shell_point(b,u,outside,length,false),hint)
			_quad(st,_shell_point(a,t,inside,length,true),_shell_point(b,t,inside,length,true),_shell_point(a,u,inside,length,true),_shell_point(b,u,inside,length,true),-hint)
		for end in [0.0,1.0]:
			_quad(st,_shell_point(a,end,inside,length,true),_shell_point(b,end,inside,length,true),_shell_point(a,end,outside,length,false),_shell_point(b,end,outside,length,false),Vector3.BACK if end==1 else Vector3.FORWARD)

