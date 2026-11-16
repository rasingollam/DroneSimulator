extends Node3D

const DroneScript = preload("res://scripts/drone.gd")
const WorldScript = preload("res://scripts/training_world.gd")
const HudScript = preload("res://scripts/hud.gd")
const PhoneScript = preload("res://scripts/phone_receiver.gd")

var drone: RigidBody3D
var field: Node3D
var hud: Control
var camera: Camera3D
var fpv := false
var show_help := false
var hud_mode := 0 # 0: minimal, 1: instruments, 2: hidden
var paused := false
var wind_level := 0
var next_gate := 0
var completed_laps := 0
var lap_time := 0.0
var best_lap := 0.0
var course_started := false
var previous_position := Vector3.ZERO
var session_time := 0.0
var message := "WELCOME TO THE FIELD"
var message_time := 0.0
var crash_speed := 0.0
var fpv_tilt := 15.0
var audio: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var audio_phase := 0.0
var muted := false
var phone: Node
var show_phone := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	field = Node3D.new()
	field.set_script(WorldScript)
	field.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(field)
	drone = RigidBody3D.new()
	drone.set_script(DroneScript)
	drone.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(drone)
	drone.hard_landing.connect(_on_crash)
	previous_position = drone.global_position
	camera = Camera3D.new()
	camera.fov = 85
	camera.near = 0.035
	camera.far = 1400
	add_child(camera)
	camera.position = drone.position + Vector3(0, 2.2, 5)
	camera.look_at(drone.position + Vector3(0, 0.6, -3))
	camera.current = true
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Control.new()
	hud.set_script(HudScript)
	hud.sim = self
	canvas.add_child(hud)
	_setup_audio()
	phone = Node.new()
	phone.set_script(PhoneScript)
	phone.sim = self
	add_child(phone)
	get_tree().paused = show_help
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_F11:
			var mode := DisplayServer.window_get_mode()
			var is_fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if is_fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
		KEY_F3:
			hud_mode = (hud_mode + 1) % 3
		KEY_F2:
			show_phone = not show_phone
			if show_phone:
				phone.enabled = true
				paused = true
				get_tree().paused = true
		KEY_K:
			phone.use_keyboard()
		KEY_ENTER:
			if show_help:
				show_help = false
				get_tree().paused = paused
				flash("SPACE TO ARM  /  HOLD W GENTLY TO LIFT OFF")
		KEY_F1:
			show_help = not show_help
			get_tree().paused = show_help or paused
		KEY_ESCAPE:
			if show_help:
				show_help = false
			else:
				paused = not paused
			get_tree().paused = paused
		KEY_SPACE:
			if not show_help and not paused and not drone.remote_active:
				drone.set_armed(not drone.armed)
				flash("MOTORS ARMED  /  THROTTLE ZERO" if drone.armed else "MOTORS DISARMED")
		KEY_R:
			reset_flight()
		KEY_C:
			toggle_camera()
		KEY_TAB:
			toggle_mode()
		KEY_H:
			if drone.armed and not paused and not show_help and not drone.remote_active:
				drone.throttle = sqrt(drone.mass * 9.80665 / (4.0 * drone.MAX_THRUST))
				flash("LEVEL HOVER THROTTLE SET  /  NO ALTITUDE HOLD")
		KEY_B:
			wind_level = (wind_level + 1) % 3
			flash(["CALM AIR", "LIGHT WIND  /  2 M/S + GUSTS", "BREEZY  /  5 M/S + GUSTS"][wind_level])
		KEY_M:
			muted = not muted
		KEY_BRACKETLEFT:
			fpv_tilt = maxf(0, fpv_tilt - 5)
		KEY_BRACKETRIGHT:
			fpv_tilt = minf(45, fpv_tilt + 5)

func reset_flight() -> void:
	drone.reset_drone()
	next_gate = 0
	course_started = false
	lap_time = 0.0
	field.set_active_gate(next_gate)
	previous_position = drone.spawn_transform.origin
	flash("RETURNED TO LANDING PAD / ARM TO FLY")

func toggle_camera() -> void:
	fpv = not fpv
	camera.fov = 105.0 if fpv else 85.0
	flash("FPV CAMERA" if fpv else "CHASE CAMERA")

func toggle_mode() -> void:
	drone.acro = not drone.acro
	drone.rate_integral = Vector3.ZERO
	flash("ACRO / RELEASED STICKS STOP ROTATION, NOT TILT" if drone.acro else "ANGLE / SELF-LEVELING ENABLED")

func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	session_time += delta
	var strength: float = [0.0, 2.0, 5.0][wind_level]
	var gust := 1.0 + 0.22 * sin(session_time * 0.73) + 0.12 * sin(session_time * 1.81)
	drone.wind = Vector3(strength * gust, 0, strength * 0.3)
	var sock := field.get_node("Windsock") as Node3D
	sock.rotation.y = atan2(drone.wind.x, drone.wind.z) if wind_level > 0 else 0.0
	sock.rotation.x = -0.9 if wind_level == 0 else sin(session_time * 3) * 0.05
	if drone.armed and not drone.crashed:
		if course_started:
			lap_time += delta
		_check_gate()
	previous_position = drone.global_position
	if drone.position.y < -8 or Vector2(drone.position.x, drone.position.z).length() > 460:
		drone.reset_drone()
		course_started = false
		next_gate = 0
		field.set_active_gate(0)
		flash("FIELD BOUNDARY  /  RETURNED TO PAD")

func _process(delta: float) -> void:
	message_time = maxf(0.0, message_time - delta)
	# Cameras do not alter the aircraft's simulated orientation.
	if fpv:
		camera.global_transform = drone.global_transform * Transform3D(Basis(Vector3.RIGHT, deg_to_rad(fpv_tilt)), Vector3(0, 0.065, -0.16))
	else:
		var behind := Vector3(drone.global_basis.z.x, 0, drone.global_basis.z.z).normalized()
		if behind.length_squared() < 0.1:
			behind = Vector3.BACK
		var target := drone.global_position + behind * 4.6 + Vector3.UP * 1.9
		# Keep chase view outside static scenery using a camera obstruction ray.
		var query := PhysicsRayQueryParameters3D.create(drone.global_position + Vector3.UP * 0.3, target)
		query.exclude = [drone.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			target = hit.position + hit.normal * 0.25
		camera.global_position = camera.global_position.lerp(target, 1.0 - exp(-delta * 7.0))
		camera.look_at(drone.global_position + Vector3.UP * 0.3 - drone.global_basis.z * 2.0)
	_update_audio()
	hud.queue_redraw()

func _check_gate() -> void:
	var gate: Node3D = field.gates[next_gate]
	var before := gate.to_local(previous_position)
	var after := gate.to_local(drone.global_position)
	if before.z > 0.0 and after.z <= 0.0:
		var crossing := before.lerp(after, before.z / (before.z - after.z))
		# Whole aircraft must fit through the aperture, in the correct order/direction.
		if absf(crossing.x) < 2.85 and absf(crossing.y) < 1.85:
			if next_gate == 0:
				if course_started:
					completed_laps += 1
					if best_lap <= 0.0 or lap_time < best_lap:
						best_lap = lap_time
					flash("LAP %d COMPLETE  /  %.2f S" % [completed_laps, lap_time])
				else:
					flash("COURSE STARTED  /  FOLLOW THE TEAL GATE")
				course_started = true
				lap_time = 0.0
			else:
				flash("GATE %02d CLEARED" % (next_gate + 1))
			next_gate = (next_gate + 1) % field.gates.size()
			field.set_active_gate(next_gate)

func _on_crash(speed: float) -> void:
	crash_speed = speed
	flash("HARD IMPACT  /  %.1f M/S  /  PRESS R TO RESET" % speed, 8.0)

func flash(text: String, duration: float = 3.5) -> void:
	message = text
	message_time = duration

func _setup_audio() -> void:
	audio = AudioStreamPlayer.new()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.08
	audio.stream = generator
	audio.volume_db = -24.0
	add_child(audio)
	audio.play()
	playback = audio.get_stream_playback()

func _update_audio() -> void:
	if playback == null:
		return
	var motor_average := 0.0
	for speed in drone.motor_speeds:
		motor_average += speed * 0.25
	var count := playback.get_frames_available()
	var gain := motor_average * 0.35 if not muted and not get_tree().paused else 0.0
	for i in range(count):
		audio_phase = fmod(audio_phase + (85.0 + motor_average * 350.0) / 22050.0, 1.0)
		var sample := (sin(audio_phase * TAU) + 0.3 * sin(audio_phase * TAU * 2.01) + 0.15 * sin(audio_phase * TAU * 4.0)) * gain
		playback.push_frame(Vector2(sample, sample))

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(audio):
		audio.stop()
		audio.stream = null
	playback = null
