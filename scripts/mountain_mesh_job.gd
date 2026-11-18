extends RefCounted
## All LODs share a five-metre boundary. Border cells fan to its exact vertices.
var sampler: RefCounted
var vertices := PackedVector3Array()
var normals := PackedVector3Array()
var tangents := PackedFloat32Array()
var uvs := PackedVector2Array()
var indices := PackedInt32Array()
var lookup := {}
var normal_cache := {}
var chunk_key: Vector2i

func vertex(x: float,z: float) -> int:
	var local := Vector2(x,z)
	if lookup.has(local): return lookup[local]
	var px := chunk_key.x*200+x
	var pz := chunk_key.y*200+z
	var y: float = sampler.sample(px,pz)
	# Match the training terrain's ten-metre boundary triangles.
	if (absf(px)==1200 and absf(pz)<=1200) or (absf(pz)==1200 and absf(px)<=1200):
		if absf(px)==1200:
			var a := floorf(pz/10)*10
			y = lerpf(sampler.sample(px,a),sampler.sample(px,a+10),fposmod(pz,10)/10)
		else:
			var a := floorf(px/10)*10
			y = lerpf(sampler.sample(a,pz),sampler.sample(a+10,pz),fposmod(px,10)/10)
	var index := vertices.size()
	lookup[local] = index
	vertices.append(Vector3(x,y,z))
	var normal := smooth_normal(px,pz)
	normals.append(normal)
	var tangent := (Vector3.RIGHT-normal*normal.x).normalized()
	tangents.append_array(PackedFloat32Array([tangent.x,tangent.y,tangent.z,-1]))
	uvs.append(Vector2(px,pz)*0.1)
	return index

func build(key: Vector2i,step: int) -> Dictionary:
	chunk_key = key
	var count: int = 200/step
	for z in range(count):
		for x in range(count):
			var px := x*step
			var pz := z*step
			if step==5 or (x>0 and z>0 and x<count-1 and z<count-1):
				var a := vertex(px,pz)
				var b := vertex(px+step,pz)
				var c := vertex(px,pz+step)
				var d := vertex(px+step,pz+step)
				indices.append_array(PackedInt32Array([a,b,c,b,d,c]))
				continue
			var ring: Array[int] = []
			# Clockwise from above; subdivide exposed chunk boundaries only.
			for offset in range(0,step,5 if z==0 else step): ring.append(vertex(px+offset,pz))
			for offset in range(0,step,5 if x==count-1 else step): ring.append(vertex(px+step,pz+offset))
			for offset in range(0,step,5 if z==count-1 else step): ring.append(vertex(px+step-offset,pz+step))
			for offset in range(0,step,5 if x==0 else step): ring.append(vertex(px,pz+step-offset))
			var centre := vertex(px+step*0.5,pz+step*0.5)
			for i in range(ring.size()): indices.append_array(PackedInt32Array([centre,ring[i],ring[(i+1)%ring.size()]]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_TANGENT]=tangents
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=indices
	return {"key":key,"arrays":arrays}

func grid_normal(x: float,z: float) -> Vector3:
	var key := Vector2(x,z)
	if not normal_cache.has(key):
		normal_cache[key] = Vector3(sampler.sample(x-2,z)-sampler.sample(x+2,z),4,sampler.sample(x,z-2)-sampler.sample(x,z+2)).normalized()
	return normal_cache[key]

func smooth_normal(x: float,z: float) -> Vector3:
	# One common normal field for every LOD prevents slope-based material patches
	# when a detailed chunk meets distant geometry. Height/collision stay detailed.
	var a := floorf(x/20)*20
	var b := floorf(z/20)*20
	var u := (x-a)/20
	var v := (z-b)/20
	var n00 := grid_normal(a,b)
	var n10 := grid_normal(a+20,b)
	var n01 := grid_normal(a,b+20)
	if u+v<=1: return (n00+(n10-n00)*u+(n01-n00)*v).normalized()
	var n11 := grid_normal(a+20,b+20)
	return (n11+(n01-n11)*(1-u)+(n10-n11)*(1-v)).normalized()
