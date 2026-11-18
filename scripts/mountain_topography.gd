extends RefCounted
## Deterministic metre-scale geography shared by scenery, water and collision.
const Geography = preload("res://scripts/exploration_geography.gd")
var ridge := FastNoiseLite.new()
var detail := FastNoiseLite.new()
var launches: Array[Dictionary] = []
var cache := {}
var village_height := 0.0

func _init() -> void:
	ridge.seed = 91283
	ridge.frequency = 0.0012
	ridge.fractal_octaves = 3
	ridge.domain_warp_enabled = true
	ridge.domain_warp_amplitude = 110.0
	ridge.domain_warp_frequency = 0.001
	ridge.domain_warp_fractal_octaves = 3
	ridge.domain_warp_fractal_lacunarity = 2.0
	ridge.fractal_gain = 0.4
	detail.seed = 5724
	detail.frequency = 0.008
	detail.fractal_octaves = 3
	village_height = _raw_height(-1050,-2550)
	var locations := [
		["Lake overlook",Vector2(river_x(-1600)-220,-1580),"Lake, riverside forest and the lower valley"],
		["Gorge trailhead",Vector2(river_x(-2050)+95,-2035),"Stone bridge, narrow gorge and the natural rock arch"],
		["Waterfall camp",Vector2(river_x(-2390)+52,-2360),"A sixty-five metre cascade and its misty plunge pool"],
		["Pine saddle",Vector2(-1400,-1800),"Forest canopy, cliff roads and western ridgelines"],
		["Cave camp",Vector2(cave_x()+35,-2720),"An open-ended rock cavern above the river"],
		["Forgotten village",Vector2(-1050,-2505),"Abandoned houses, roof gaps and a quiet mountain square"],
		["High summit",Vector2(1100,-2700),"Snow, exposed ridges and a panorama of the entire valley"],
		["Railway viaduct",Vector2(1480,branch_z(1500)+145),"Arched railway crossing and a secondary ravine"],
		["Glacial lake",Vector2(river_x(-3350)-145,-3350),"High water, scree shores and snow-covered peaks"]
	]
	locations.append_array(Geography.SITES)
	for location in locations:
		var p: Vector2 = location[1]
		launches.append({"name":location[0],"position":Vector3(p.x,height(p.x,p.y),p.y),"description":location[2]})

func river_x(z: float) -> float:
	var t := -z-1600.0
	return -250.0+sin(t*0.0033)*210.0+sin(t*0.007)*55.0

func river_y(z: float) -> float:
	var north := minf(-z,3280.0)
	return 70.0+maxf(0,north-1750.0)*0.085+smoothstep(2385.0,2410.0,north)*65.0+smoothstep(3060.0,3090.0,north)*38.0

func road_x(z: float) -> float:
	var base := river_x(z)+145.0+sin(z*0.004)*20.0
	var portal := river_x(-2890)+145.0+sin(-2890*0.004)*20.0
	return lerpf(base,portal,1.0-smoothstep(50,110,absf(z+2890)))

func road_y(z: float) -> float:
	var north := -z
	return 105.0+maxf(0,north-1750)*0.085+smoothstep(2250,2550,north)*65+smoothstep(2920,3220,north)*38+sin(z*0.002)*8

func viaduct_y() -> float:
	var z := branch_z(1500)
	return maxf(_raw_height(1385,z),_raw_height(1615,z))+55.0

func cave_x() -> float:
	return river_x(-2740)+125.0

func branch_z(x: float) -> float:
	return -1400.0+sin(x*0.003)*160.0

func water_height(x: float, z: float) -> float:
	var lake := Vector2((x+250.0)/140.0,(z+1600.0)/180.0).length()
	if lake < 2.0 and height(x,z)<70.0:
		return 70.0
	var upper := Vector2((x-river_x(-3350))/112.0,(z+3350)/110.0).length()
	if upper < 2.0 and height(x,z)<river_y(-3350):
		return river_y(-3350)
	if z <= -1740 and z >= -3520 and absf(x-river_x(z)) < 22.0+sin(z*0.021)*1.5+sin(z*0.053)*0.7:
		return river_y(z)
	return Geography.water_height(x,z)

func _raw_height(x: float,z: float) -> float:
	var n := ridge.get_noise_2d(x,z)
	var ridged := 1.0-sqrt(n*n+0.012)
	var height := 90.0+pow(ridged,2.5)*370.0+detail.get_noise_2d(x,z)*9.0
	# A high massif with broken ridge detail, rather than uniform rounded hills.
	height += exp(-Vector2(x-1100,z+2700).length_squared()/280000.0)*510.0
	height += exp(-Vector2(x+1250,z+3300).length_squared()/350000.0)*260.0
	height += exp(-Vector2(x+400,z+3650).length_squared()/240000.0)*340.0
	if z < -1400 and z > -3680:
		var distance := absf(x-river_x(z))
		var canyon := 1.0-smoothstep(100.0,350.0,absf(z+2200))
		var bank := lerpf(85.0,28.0,canyon)+detail.get_noise_2d(x*0.2,z*0.2)*16.0
		var valley := smoothstep(bank,bank+290.0,distance)
		var floor_height := river_y(z)-5.0
		var terrace := floor_height+smoothstep(10,28,distance)*10.0+detail.get_noise_2d(x*0.6,z*0.6)*2.5*smoothstep(28,70,distance)
		var bedrock := river_y(z)+35.0
		var flank := 0.5*(height+bedrock+sqrt((height-bedrock)*(height-bedrock)+400.0))
		var carved := lerpf(terrace,flank,valley)
		var reach := smoothstep(-3680,-3500,z)*(1.0-smoothstep(-1580,-1400,z))
		height = lerpf(height,carved,reach)
	var lower_offset := Vector2((x+250)/140.0,(z+1600)/180.0)
	var lower_lake := lower_offset.length()*(1.0+0.09*sin(lower_offset.angle()*3)+0.04*sin(lower_offset.angle()*7))
	height = lerpf(64.0,height,smoothstep(0.85,1.75,lower_lake))
	for islet in [Vector2(-300,-1640),Vector2(-190,-1550)]:
		height += 13.0*exp(-Vector2(x-islet.x,z-islet.y).length_squared()/650.0)
	var upper_offset := Vector2((x-river_x(-3350))/112.0,(z+3350)/110.0)
	var upper_lake := upper_offset.length()*(1.0+0.10*sin(upper_offset.angle()*4)+0.05*sin(upper_offset.angle()*7))
	height = lerpf(river_y(-3350)-7.0,height,smoothstep(0.85,1.85,upper_lake))
	if x > 850 and x < 2400:
		var distance := absf(z-branch_z(x))
		var ravine := lerpf(150.0+(x-850)*0.04,height,smoothstep(22.0,230.0,distance))
		height = lerpf(height,ravine,smoothstep(850,1050,x)*(1.0-smoothstep(2200,2400,x)))
	# A terrain trench is covered by a true hollow rock shell, not a solid hill.
	var cave := (1.0-smoothstep(12,32,absf(x-cave_x())))*(1.0-smoothstep(58,100,absf(z+2740)))
	height = lerpf(height,river_y(-2740)+18.0,cave)
	var shoulder := smoothstep(11,17,absf(x-cave_x()))*(1.0-smoothstep(19,48,absf(x-cave_x())))*(1.0-smoothstep(32,85,absf(z+2740)))
	height += shoulder*13.0
	var tunnel := (1.0-smoothstep(7,22,absf(x-road_x(-2890))))*(1.0-smoothstep(60,95,absf(z+2890)))
	height = lerpf(height,road_y(-2890),tunnel)
	var alcove := (1.0-smoothstep(10,30,absf(x-river_x(-2400)-50)))*(1.0-smoothstep(45,90,absf(z+2410)))
	height = lerpf(height,river_y(-2385)+15.0,alcove)
	return Geography.height(x,z,height)

func height(x: float,z: float) -> float:
	var key := Vector2(x,z)
	if cache.has(key):
		return cache[key]
	var result := _raw_height(x,z)
	var village := Vector2(x+1050,z+2550).length()
	result = lerpf(village_height,result,smoothstep(55,100,village))
	if z < -1800 and z > -3220:
		var road := road_x(z)
		var amount := 1.0-smoothstep(5.0,30.0,absf(x-road))
		if amount>0:
			result = lerpf(result,road_y(z),amount)
	# Abutments blend the bridge and railway decks into actual approach terrain.
	var bridge_distance := absf(x-river_x(-2050))
	var bridge_grade := smoothstep(48,65,bridge_distance)*(1.0-smoothstep(85,210,bridge_distance))*(1.0-smoothstep(5,23,absf(z+2050)))
	if bridge_grade>0: result = lerpf(result,river_y(-2050)+27.25,bridge_grade)
	var rail_distance := absf(x-1500)
	var rail_grade := smoothstep(115,125,rail_distance)*(1.0-smoothstep(125,450,rail_distance))*(1.0-smoothstep(6,30,absf(z-branch_z(1500))))
	if rail_grade>0: result = lerpf(result,viaduct_y()+0.35,rail_grade)
	# Portals must be cut after road grading; otherwise a nearby road can seal them.
	var cave_cut := (1.0-smoothstep(11,17,absf(x-cave_x())))*(1.0-smoothstep(58,100,absf(z+2740)))
	result = lerpf(result,river_y(-2740)+18.0,cave_cut)
	var tunnel_cut := (1.0-smoothstep(7,14,absf(x-road_x(-2890))))*(1.0-smoothstep(60,95,absf(z+2890)))
	result = lerpf(result,road_y(-2890),tunnel_cut)
	for site in launches:
		var p: Vector3 = site.position
		var distance := Vector2(x-p.x,z-p.z).length()
		if distance < 24:
			result = lerpf(p.y,result,smoothstep(12,24,distance))
	cache[key] = result
	return result
