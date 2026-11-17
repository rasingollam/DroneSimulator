extends SceneTree
## Host for the Android Java sender integration test; never packaged in the APK.
var sim: Node3D
var elapsed := 0.0
var total := 0.0
var ready_to_test := false

func _initialize() -> void:
	if FileAccess.file_exists("res://tools/controller_test.done"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("res://tools/controller_test.done"))
	call_deferred("start")

func start() -> void:
	sim = load("res://scenes/main.tscn").instantiate()
	sim.set_meta("controller_port", 0)
	root.add_child(sim)
	current_scene = sim
	ready_to_test = true
	_write_status()
	print("JAVA CONTROLLER HOST READY")

func _process(delta: float) -> bool:
	if not ready_to_test:
		return false
	elapsed += delta
	total += delta
	if elapsed > 0.05:
		_write_status()
		elapsed = 0
	if FileAccess.file_exists("res://tools/controller_test.done") or total > 45:
		ready_to_test = false
		sim.audio.stop()
		sim.playback = null
		paused = false
		call_deferred("finish")
	return false

func finish() -> void:
	await create_timer(0.05).timeout
	quit()

func _write_status() -> void:
	var file := FileAccess.open("res://tools/controller_host.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"pin": sim.phone.pin, "connected": sim.phone.connected,
		"paused": paused, "armed": sim.drone.armed, "height": sim.drone.position.y, "port": sim.phone.listen_port}))
