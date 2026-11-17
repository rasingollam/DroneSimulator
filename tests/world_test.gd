extends SceneTree
const World = preload("res://scripts/training_world.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ", label)
	if not value:
		failures += 1

func ray(world: Node3D, start: Vector3, end: Vector3) -> Dictionary:
	return world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start, end))

func run() -> void:
	var world := Node3D.new()
	world.set_script(World)
	root.add_child(world)
	for i in range(3):
		await physics_frame
	var ground := ray(world, Vector3(5, 8, -5), Vector3(5, -2, -5))
	check(not ground.is_empty() and absf(ground.position.y) < 0.01, "Training field has solid level terrain")
	var pad := ray(world, Vector3(0, 5, 9), Vector3(0, -2, 9))
	check(not pad.is_empty() and pad.position.y > 0.04 and pad.position.y < 0.06, "Landing pad has a physical top surface")
	check(ray(world, Vector3(-54, 2, -16), Vector3(-54, 2, -46)).is_empty(), "Hangar doorway and central interior are flyable")
	check(not ray(world, Vector3(-54, 2, -37), Vector3(-70, 2, -37)).is_empty(), "Hangar walls block aircraft")
	check(not ray(world, Vector3(-54, 2, -37), Vector3(-54, 15, -37)).is_empty(), "Curved hangar roof has collision panels")
	world.queue_free()
	await process_frame
	print("WORLD TESTS: ", "ALL PASSED" if failures == 0 else str(failures) + " FAILED")
	quit(0 if failures == 0 else 1)
