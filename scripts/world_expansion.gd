extends Node3D
## Hand-built flying spaces. Shared materials and distance culling limit draw cost.
const Catalog = preload("res://scripts/training_catalog.gd")
var field: Node3D
var concrete: Material
var metal: Material
var wood: Material
var trim: Material
var amber: Material
var glass: Material
var landing_pads: Array[Vector3] = []
var art: Node3D

func build(world: Node3D) -> void:
	field = world
	art = Node3D.new()
	art.set_script(load("res://scripts/scenery_library.gd"))
	add_child(art)
	concrete = art.pbr("concrete",2)
	metal = art.pbr("corrugated",2,Color("b7c0c0"),0.55)
	wood = art.pbr("planks",2)
	trim = field.mat("303d41")
	amber = field.mat("d8a44c")
	glass = field.mat("314e5a", 0.2)
	_meadow()
	_industry()
	_quarry()
	_lake()
	art.finish_factory()
	for i in range(1, Catalog.ZONES.size()):
		var center: Vector3 = Catalog.ZONES[i]
		var names := ["", "MEADOW / FOUNDATIONS", "PINE WOOD / SLALOM", "FREIGHT YARD / TECHNICAL", "QUARRY / VERTICAL", "LAKESIDE / BRIDGE"]
		var spawn: Vector3 = [Vector3.ZERO, Vector3(-350,0,285), Vector3(-350,0,-280), Vector3(350,0,255), Vector3(350,0,-295), Vector3(-100,0,650)][i]
		pad(spawn, 3.0)
		part(Vector3(0.18,3,0.18), spawn + Vector3(-4,1.5,6), trim)
		part(Vector3(8,1.1,0.14), spawn + Vector3(0,3.2,6), trim)
		field.label_3d(names[i], spawn + Vector3(0,3.2,6.09), 34, Color("e7dfc8"), self)
		# A road and reflectors connect the original airfield to every district.
		var origin := Vector3(-90,0,0) if i < 3 else Vector3(90,0,0)
		var length := Vector2(center.x-origin.x,center.z-origin.z).length()
		var direction := (center-origin).normalized()
		_road(origin,center)
		for step_index in range(int(length / 20.0)):
			var p := origin + direction * (step_index * 20.0)
			p.y = field._terrain_height(p.x,p.z)
			var marker := part(Vector3(0.12,1,0.12),p+Vector3.UP*0.5,trim)
			marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			part(Vector3(0.2,0.15,0.2),p+Vector3.UP*0.94,amber,false)

func part(size: Vector3, position: Vector3, material: Material, collision: bool = true) -> MeshInstance3D:
	var mesh: MeshInstance3D = field.box(size, position, material, collision, self)
	mesh.visibility_range_end = 620
	mesh.visibility_range_end_margin = 35
	return mesh

func pad(position: Vector3, radius: float) -> void:
	var base := part(Vector3(radius*2,0.1,radius*2),position+Vector3.UP*0.05,concrete)
	base.name = "LandingPad"
	landing_pads.append(position + Vector3.UP * 0.10)
	for x in [-radius*0.45,radius*0.45]:
		part(Vector3(0.12,0.0006,radius),position+Vector3(x,0.1004,0),amber,false)
	part(Vector3(radius*0.9,0.0006,0.12),position+Vector3(0,0.1004,0),amber,false)

func _road(start: Vector3, end: Vector3) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var direction := (end-start).normalized()
	var right := Vector3(-direction.z,0,direction.x)*1.8
	var count := maxi(1,ceili(start.distance_to(end)/8.0))
	for i in range(count):
		var a := start.lerp(end,float(i)/count)
		var b := start.lerp(end,float(i+1)/count)
		for p in [a-right,a+right,b-right,a+right,b+right,b-right]:
			p.y = field._terrain_height(p.x,p.z)+0.015
			surface.set_normal(Vector3.UP)
			surface.set_uv(Vector2(p.x,p.z)*0.18)
			surface.add_vertex(p)
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = art.pbr("gravel",2)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)

func _meadow() -> void:
	var c := Vector3(-350,0,250)
	var red: Material = field.mat("8a4a3e")
	# Open barn, roof and beams are solid but the central passage remains flyable.
	for x in [-12,12]:
		part(Vector3(0.3,6,24),c+Vector3(x-40,3,0),red)
	for side in [-1,1]:
		var roof := part(Vector3(12.5,0.25,25),c+Vector3(-40+side*6,7.0,0),trim)
		roof.rotation.z = -side*0.22
	for z in [-11,0,11]:
		part(Vector3(24,0.3,0.3),c+Vector3(-40,5.3,z),wood)
	for z in range(-50,61,5):
		part(Vector3(0.14,1.5,0.14),c+Vector3(55,0.75,z),wood)
	for y in [0.5,1.1]:
		part(Vector3(0.10,0.12,110),c+Vector3(55,y,5),wood)
	var straw: Material = field.mat("b99b58")
	for i in range(14):
		part(Vector3(2,1.3,1.2),c+Vector3(-52+(i%4)*3,0.65,23+(i/4)*3),straw)
	for i in range(5):
		art.prop("wooden_crate_01",c+Vector3(-45+i*1.3,0,14),1.1,i*0.27)
	art.prop("barrel_03",c+Vector3(-52,0,12),0.65,0.3)
	pad(Vector3(-335,0,265),2.0)
	# Distinct crop strips, with no invisible decorative collision.
	var crop: Material = field.mat("797f43")
	for i in range(16):
		part(Vector3(0.5,0.45,32),c+Vector3(25+i*1.1,0.225,-22),crop,false)

func _industry() -> void:
	var c := Vector3(350,0,200)
	part(Vector3(130,0.10,130),c+Vector3.UP*0.05,field.textured("asphalt",0.5))
	var colors := [art.pbr("corrugated",1.5,Color("91a995"),0.4),art.pbr("corrugated",1.5,Color("bd8c78"),0.4),art.pbr("corrugated",1.5,Color("d4c49a"),0.4)]
	for x in [-27,-13,13,27]:
		for z in [-22,20]:
			for level in range(2 if abs(x) == 27 else 1):
				var p := c+Vector3(x,1.4+level*2.8,z)
				part(Vector3(5,2.8,12),p,colors[(abs(x)+level)%3])
				for rib in range(6):
					part(Vector3(0.05,2.6,0.12),p+Vector3(2.52,0,-5+rib*2),trim,false)
	# A clear, roofed warehouse passage through the first two gates.
	for x in [-7,7]:
		part(Vector3(0.3,8,30),c+Vector3(x,4,24),concrete)
	part(Vector3(14.5,0.3,30),c+Vector3(0,8,24),metal)
	for x in [-12,12]:
		part(Vector3(0.4,13,0.4),c+Vector3(x,6.5,-25),amber)
	part(Vector3(25,0.6,0.6),c+Vector3(0,13,-25),amber)
	for x in [-48,48]:
		art.factory_block(c+Vector3(x,0.10,-40),4,6)
	for i in range(10):
		art.prop("wooden_crate_01",c+Vector3(-44+(i%5)*1.5,0.1,2+(i/5)*1.4),1.2,i*0.15)
	for i in range(6):
		art.prop("barrel_03",c+Vector3(43+(i%2)*1.0,0.1,6+(i/2)*1.0),0.7,i*0.8)
	for i in range(7):
		part(Vector3(0.2,0.001,6),c+Vector3(-53+i*4,0.101,48),amber,false)

func _quarry() -> void:
	var c := Vector3(350,0,-350)
	var stone: Material = art.pbr("gravel",2,Color("bfb3a1"))
	# Stepped rock walls create elevation references without closing the course.
	for side in [-1,1]:
		for tier in range(3):
			for i in range(8):
				var position := c+Vector3(side*(61+tier*8),tier*3.5,-49+i*14)
				art.prop("namaqualand_boulder_02" if i%2==0 else "rock_09",position,18+float(i%3)*2.0,sin(float(i*3+tier))*1.5)
	for x in [-12,12]:
		for z in [-12,12]:
			part(Vector3(0.6,30,0.6),c+Vector3(x,15,z),metal)
	for y in [10,20,30]:
		# A perimeter platform, with a large real opening down the centre.
		for x in [-12,12]:
			part(Vector3(2,0.4,26),c+Vector3(x,y,0),metal)
		for z in [-12,12]:
			part(Vector3(22,0.4,2),c+Vector3(0,y,z),metal)
	for i in range(9):
		part(Vector3(3,1.5,3),c+Vector3(35+(i%3)*5,0.75,-45+(i/3)*5),stone)

func _lake() -> void:
	var water := ShaderMaterial.new()
	water.shader = load("res://assets/shaders/water.gdshader")
	part(Vector3(140,0.05,180),Vector3(40,-1,600),water,false)
	for i in range(26):
		var theta := i*TAU/26
		var p := Vector3(40+cos(theta)*70,0,600+sin(theta)*90)
		# Leave the bridge approaches and the dock accessible.
		if absf(p.z-600)<12 or (p.x<0 and absf(p.z-635)<12):
			continue
		p.y = field._terrain_height(p.x,p.z)-0.3
		art.prop("rock_09",p,2.0+float(i%4),theta)
	# Raised crossing: clear water passage beneath a deck with physical piers.
	part(Vector3(180,0.45,9),Vector3(30,5,600),concrete)
	for x in [-50,-10,30,70,110]:
		for z in [596,604]:
			part(Vector3(1,10,1),Vector3(x,0,z),concrete)
	for z in [595.5,604.5]:
		part(Vector3(180,0.16,0.14),Vector3(30,6.2,z),trim)
		for x in range(-60,121,10):
			part(Vector3(0.1,1.1,0.1),Vector3(x,5.65,z),trim)
	# Lakeside dock and cabin frame the launch area.
	part(Vector3(30,0.2,5),Vector3(-23,0.8,635),wood)
	for x in [-35,-20,-10]:
		part(Vector3(0.3,5,0.3),Vector3(x,-1.5,635),wood)
	part(Vector3(12,4,10),Vector3(-135,2,625),wood)
	part(Vector3(13,0.25,11),Vector3(-135,4.2,625),trim)
	part(Vector3(5,1.5,0.08),Vector3(-135,2.5,630.05),glass,false)
