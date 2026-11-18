extends Node3D

const DroneScript = preload("res://scripts/drone.gd")
const WorldScript = preload("res://scripts/training_world.gd")
const HudScript = preload("res://scripts/hud.gd")
const PhoneScript = preload("res://scripts/phone_receiver.gd")
const Catalog = preload("res://scripts/training_catalog.gd")
const TrainingScript = preload("res://scripts/training_session.gd")

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
var crash_reason := "HARD IMPACT"
var fpv_tilt := 30.0
var audio: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var audio_phase := 0.0
var muted := false
var phone: Node
var show_phone := false
var show_fleet := false
var fleet_was_paused := false
var best_laps := {}
var training: Node
var show_training := false
var training_cursor := 0
var training_was_paused := false
var ground_clock := 0.0
var show_explorer := false
var explorer_cursor := 0
var explorer_was_paused := false
var home_marker := false
var exploration: Node3D

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
	training = Node.new()
	training.set_script(TrainingScript)
	training.sim = self
	add_child(training)
	previous_position = drone.global_position
	camera = Camera3D.new()
	camera.fov = 85
	camera.near = 0.035
	camera.far = 7000
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
	exploration=Node3D.new()
	exploration.set_script(load("res://scripts/exploration.gd"))
	exploration.sim=self
	add_child(exploration)
	get_tree().paused = show_help
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if show_explorer:
		match event.physical_keycode:
			KEY_UP:
				explorer_cursor = wrapi(explorer_cursor-1,0,field.topography.launches.size())
			KEY_DOWN:
				explorer_cursor = wrapi(explorer_cursor+1,0,field.topography.launches.size())
			KEY_ENTER:
				start_exploring()
			KEY_ESCAPE,KEY_F6:
				toggle_explorer()
		if event.physical_keycode not in [KEY_F7,KEY_F8,KEY_F9,KEY_F10,KEY_F11,KEY_G,KEY_Y,KEY_P,KEY_O]: return
	if show_training:
		match event.physical_keycode:
			KEY_UP:
				training_cursor = wrapi(training_cursor-1,0,Catalog.ACTIVITIES.size())
			KEY_DOWN:
				training_cursor = wrapi(training_cursor+1,0,Catalog.ACTIVITIES.size())
			KEY_ENTER:
				start_training()
			KEY_ESCAPE, KEY_F5:
				toggle_training()
		return
	if show_fleet and event.physical_keycode not in [KEY_F4, KEY_ENTER, KEY_ESCAPE, KEY_2, KEY_3, KEY_4, KEY_5, KEY_F11]:
		return
	match event.physical_keycode:
		KEY_F10:
			exploration.cycle_season()
		KEY_G:
			exploration.toggle_guide()
		KEY_Y:
			exploration.toggle_recording()
		KEY_P:
			exploration.toggle_playback()
		KEY_O:
			exploration.toggle_hints()
		KEY_F6:
			toggle_explorer()
		KEY_F7:
			field.apply_atmosphere(field.atmosphere+1)
			flash(["CLEAR MORNING","GOLDEN HOUR","VALLEY MIST"][field.atmosphere])
		KEY_F8:
			field.high_quality = not field.high_quality
			field.apply_atmosphere(field.atmosphere)
			flash("HIGH GRAPHICS" if field.high_quality else "PERFORMANCE GRAPHICS")
		KEY_F9:
			home_marker = not home_marker
			flash("HOME MARKER ON" if home_marker else "HOME MARKER OFF")
		KEY_F5:
			toggle_training()
		KEY_F4:
			toggle_fleet()
		KEY_2, KEY_3, KEY_4, KEY_5:
			select_airframe(int(event.physical_keycode - KEY_0))
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
			if show_fleet:
				toggle_fleet()
			elif show_help:
				show_help = false
				get_tree().paused = paused
				flash("SPACE TO ARM  /  HOLD W GENTLY TO LIFT OFF")
		KEY_F1:
			show_help = not show_help
			get_tree().paused = show_help or paused
		KEY_ESCAPE:
			if phone.recovering:
				phone.cancel_auto_recovery()
				flash("PHONE SIGNAL DELAYED / WAIT FOR LINK THEN RESUME")
				return
			if show_fleet:
				toggle_fleet()
				return
			elif show_help:
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
				drone.throttle = drone.hover_throttle()
				flash("LEVEL HOVER THROTTLE SET  /  NO ALTITUDE HOLD")
		KEY_B:
			wind_level = (wind_level + 1) % 3
			restart_scoring()
			training.refresh_best()
			flash(["CALM AIR", "LIGHT WIND  /  2 M/S + GUSTS", "BREEZY  /  5 M/S + GUSTS"][wind_level])
		KEY_M:
			muted = not muted
		KEY_BRACKETLEFT:
			fpv_tilt = maxf(0, fpv_tilt - 5)
		KEY_BRACKETRIGHT:
			fpv_tilt = minf(45, fpv_tilt + 5)

func reset_flight() -> void:
	drone.reset_drone()
	if is_instance_valid(exploration):
		exploration.replay_clock=0
		exploration.replay_cursor=0
	next_gate = 0
	course_started = false
	lap_time = 0.0
	if is_instance_valid(training):
		training.reset_attempt()
	field.set_active_gate(next_gate)
	previous_position = drone.spawn_transform.origin
	flash("RETURNED TO LAUNCH PAD / ARM TO FLY")

func toggle_training() -> void:
	if drone.armed:
		flash("DISARM BEFORE OPENING TRAINING / SPACE OR PHONE DISARM")
		return
	show_training = not show_training
	if show_training:
		training_cursor = maxi(0,training.selected)
		training_was_paused = paused
		show_help = false
		show_phone = false
		show_fleet = false
		paused = true
	else:
		paused = training_was_paused
	get_tree().paused = paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if show_training else Input.MOUSE_MODE_HIDDEN

func start_training() -> void:
	if training.select_activity(training_cursor):
		show_training = false
		paused = training_was_paused
		get_tree().paused = paused
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _unhandled_input(event: InputEvent) -> void:
	if not (show_training or show_explorer) or not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var viewport := get_viewport().get_visible_rect().size
	var factor := minf(viewport.x/1440.0,viewport.y/900.0)
	var point: Vector2 = (event.position-(viewport-Vector2(1440,900)*factor)/2.0)/factor
	if show_explorer:
		if Rect2(95,189,535,486).has_point(point):
			explorer_cursor = clampi((explorer_cursor/9)*9+int((point.y-189)/54),0,field.topography.launches.size()-1)
		elif Rect2(690,750,600,40).has_point(point):
			start_exploring()
		return
	if Rect2(95,189,535,486).has_point(point):
		training_cursor = clampi(int((point.y-189)/54),0,Catalog.ACTIVITIES.size()-1)
	elif Rect2(690,750,600,40).has_point(point):
		start_training()

func toggle_explorer() -> void:
	if drone.armed:
		flash("DISARM BEFORE CHANGING LAUNCH SITES")
		return
	show_explorer = not show_explorer
	if show_explorer:
		explorer_was_paused = paused
		show_training = false
		show_fleet = false
		show_help = false
		show_phone = false
		paused = true
	else:
		paused = explorer_was_paused
	get_tree().paused = paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if show_explorer else Input.MOUSE_MODE_HIDDEN

func enter_free_roam(index: int) -> bool:
	if drone.armed: return false
	var spawn: Vector3 = field.mountains.launch_position(index)
	var site: Dictionary = field.topography.launches[index]
	training.selected = -1
	training.activity = {"id":"free_roam","kind":"free","name":site.name,"spawn":spawn,"target":spawn,"tip":"Explore at your own pace","route":[],"size":Vector2(3,2)}
	field.set_course(training.activity)
	drone.spawn_transform = Transform3D(Basis.IDENTITY,spawn)
	drone.ground_reference = spawn.y-0.16
	reset_flight()
	completed_laps = 0
	best_lap = 0
	flash(site.name.to_upper()+" / F7 LIGHT / F9 HOME",6)
	return true

func start_exploring() -> void:
	if enter_free_roam(explorer_cursor):
		show_explorer = false
		paused = explorer_was_paused
		get_tree().paused = paused
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func toggle_fleet() -> void:
	if drone.armed:
		flash("DISARM BEFORE CHANGING AIRFRAME")
		return
	show_fleet = not show_fleet
	if show_fleet:
		fleet_was_paused = paused
		reset_flight()
		show_help = false
		show_phone = false
		paused = true
	else:
		paused = fleet_was_paused
	get_tree().paused = paused

func select_airframe(inches: int) -> bool:
	if drone.armed:
		flash("DISARM BEFORE CHANGING AIRFRAME")
		return false
	if not drone.configure(inches):
		return false
	reset_flight()
	completed_laps = 0
	training.refresh_best()
	flash('%d-INCH %s / HOVER ABOUT %d%%' % [inches, drone.profile.name, roundi(drone.hover_throttle() * 100)])
	return true

func toggle_camera() -> void:
	fpv = not fpv
	camera.fov = 105.0 if fpv else 85.0
	flash("FPV CAMERA" if fpv else "CHASE CAMERA")

func toggle_mode() -> void:
	drone.acro = not drone.acro
	restart_scoring()
	training.refresh_best()
	drone.rate_integral = Vector3.ZERO
	flash("ACRO / RELEASED STICKS STOP ROTATION, NOT TILT" if drone.acro else "ANGLE / SELF-LEVELING ENABLED")

func restart_scoring() -> void:
	# A time must be earned with one unchanged control mode and wind setting.
	course_started = false
	next_gate = 0
	lap_time = 0
	field.set_active_gate(0)
	training.reset_attempt()

func _physics_process(delta: float) -> void:
	if get_tree().paused or drone.respawn_requested:
		return
	session_time += delta
	var strength: float = [0.0, 2.0, 5.0][wind_level]
	var gust := 1.0 + 0.22 * sin(session_time * 0.73) + 0.12 * sin(session_time * 1.81)
	drone.wind = Vector3(strength * gust, 0, strength * 0.3)
	var sock := field.get_node("Windsock") as Node3D
	sock.rotation.y = atan2(drone.wind.x, drone.wind.z) if wind_level > 0 else 0.0
	sock.rotation.x = -0.9 if wind_level == 0 else sin(session_time * 3) * 0.05
	if drone.armed and not drone.crashed:
		if course_started and training.activity.kind == "race":
			lap_time += delta
		if training.activity.kind == "race":
			_check_gate()
	ground_clock += delta
	if ground_clock > 0.1:
		ground_clock = 0
		var query := PhysicsRayQueryParameters3D.create(drone.global_position+Vector3.UP*0.05,drone.global_position+Vector3.DOWN*500)
		query.exclude = [drone.get_rid()]
		var ground := get_world_3d().direct_space_state.intersect_ray(query)
		if not ground.is_empty():
			drone.ground_reference = ground.position.y
			if field.over_water(drone.position):
				drone.ground_reference = maxf(drone.ground_reference,field.water_height_at(drone.position.x,drone.position.z))
	training.update(delta)
	previous_position = drone.global_position
	if field.is_water(drone.position) and not drone.crashed:
		crash_reason = "WATER CONTACT"
		drone.crashed = true
		drone.set_armed(false)
		training.impacts += 1
		training.save_progress()
		flash("WATER CONTACT / PRESS R TO RECOVER",8)
	if drone.position.y < -25 or Vector2(drone.position.x, drone.position.z).length() > field.FLIGHT_RADIUS:
		reset_flight()
		flash("FIELD BOUNDARY  /  RETURNED TO PAD")

func _process(delta: float) -> void:
	message_time = maxf(0.0, message_time - delta)
	# Cameras do not alter the aircraft's simulated orientation.
	if show_fleet:
		var orbit := Time.get_ticks_msec() * 0.00020
		var radius: float = drone.profile.wheelbase * 2.5
		camera.fov = 55.0
		camera.global_position = drone.global_position + Vector3(sin(orbit) * radius, radius * 0.58, cos(orbit) * radius)
		camera.look_at(drone.global_position - Vector3.UP * drone.profile.wheelbase * 0.10)
	elif fpv:
		camera.fov = 105.0
		var scale: float = drone.profile.wheelbase / 0.245
		camera.global_transform = drone.global_transform * Transform3D(Basis(Vector3.RIGHT, deg_to_rad(fpv_tilt)), Vector3(0, 0.018, -0.070) * scale)
	else:
		camera.fov = 85.0
		var behind := Vector3(drone.global_basis.z.x, 0, drone.global_basis.z.z).normalized()
		if behind.length_squared() < 0.1:
			behind = Vector3.BACK
		var distance: float = (drone.ARM * 2.0 + drone.inches * 0.0254) * 3.0
		var target := drone.global_position + behind * distance + Vector3.UP * distance * 0.45
		# Keep chase view outside static scenery using a camera obstruction ray.
		var query := PhysicsRayQueryParameters3D.create(drone.global_position + Vector3.UP * 0.3, target)
		query.exclude = [drone.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			target = hit.position + hit.normal * 0.25
		camera.global_position = target
		camera.look_at(drone.global_position + Vector3.UP * distance * 0.03 - behind * distance * 0.20)
	_update_audio()
	hud.queue_redraw()

func _check_gate() -> void:
	if field.gates.is_empty():
		return
	var gate: Node3D = field.gates[next_gate]
	var before := gate.to_local(previous_position)
	var after := gate.to_local(drone.global_position)
	if before.z > 0.0 and after.z <= 0.0:
		var crossing := before.lerp(after, before.z / (before.z - after.z))
		# Whole aircraft must fit through the aperture, in the correct order/direction.
		var half: Vector2 = gate.get_meta("half_size",Vector2(3.09,2.09))
		var radius: float = (drone.ARM*2+drone.inches*0.0254)*0.5
		if absf(crossing.x) < half.x-radius and absf(crossing.y) < half.y-radius:
			if next_gate == 0:
				if course_started:
					completed_laps += 1
					training.record_result(lap_time)
					best_laps[drone.inches] = best_lap
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
	crash_reason = "HARD IMPACT"
	crash_speed = speed
	training.impacts += 1
	training.save_progress()
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
