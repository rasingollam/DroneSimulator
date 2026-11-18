extends RefCounted
## Each mesh worker owns its sampler/cache; no live scene nodes are read off-thread.
const Catalog = preload("res://scripts/training_catalog.gd")
var topology: RefCounted
var noise := FastNoiseLite.new()
func _init(existing: RefCounted=null) -> void:
	topology = existing if existing!=null else preload("res://scripts/mountain_topography.gd").new()
	noise.seed = 132
	noise.frequency = 0.003
	noise.fractal_octaves = 3
func sample(x: float,z: float) -> float:
	var edge := 1.0
	for centre in Catalog.ZONES:
		edge = minf(edge,smoothstep(100,210,Vector2(x-centre.x,z-centre.z).length()))
	var old := maxf(0,(32+noise.get_noise_2d(x,z)*64)*edge)
	var approach := (1-smoothstep(18,45,absf(z-600)))*(1-smoothstep(130,180,absf(x-30)))
	old *= 1-approach
	var lake := (1-smoothstep(50,70,absf(x-40)))*(1-smoothstep(70,90,absf(z-600)))
	old = lerpf(old,-5,lake)
	var boundary := maxf(absf(x),absf(z))
	return old if boundary<=1200 else lerpf(old,topology.height(x,z),smoothstep(1200,1400,boundary))
