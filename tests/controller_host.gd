extends SceneTree
## Host for the Android Java sender integration test; never packaged in the APK.
var sim: Node3D
var elapsed := 0.0
var total := 0.0
var ready_to_test := false
var status_path := "res://tools/controller_host.json"
var done_path := "res://tools/controller_test.done"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2:
		status_path = args[0]
		done_path = args[1]
	if FileAccess.file_exists(done_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(done_path))
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
	if FileAccess.file_exists(done_path) or total > 45:
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
	var file := FileAccess.open(status_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"pin": sim.phone.pin, "connected": sim.phone.connected,
		"paused": paused, "armed": sim.drone.armed, "height": sim.drone.position.y, "port": sim.phone.listen_port}))
