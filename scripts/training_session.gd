extends Node
const Catalog = preload("res://scripts/training_catalog.gd")
var sim: Node3D
var selected := 0
var activity: Dictionary = Catalog.activity(0)
var hold := 0.0
var elapsed := 0.0
var took_off := false
var complete := false
var records := ConfigFile.new()
var records_path := ""
var flight_seconds := 0.0
var distance_metres := 0.0
var impacts := 0
var save_clock := 0.0

func _ready() -> void:
	# Test scenes never read or overwrite the pilot's real progress.
	records_path = str(sim.get_meta("progress_path", "" if sim.get_meta("controller_port",42424) == 0 else "user://training.cfg"))
	if not records_path.is_empty():
		records.load(records_path)
	flight_seconds = float(records.get_value("pilot","flight_seconds",0.0))
	distance_metres = float(records.get_value("pilot","distance_metres",0.0))
	impacts = int(records.get_value("pilot","impacts",0))

func key_for(id: String, inches: int, acro: bool, wind: int) -> String:
	return '%s_%d_%s_w%d' % [id,inches,"acro" if acro else "angle",wind]

func current_key() -> String:
	return key_for(activity.id,sim.drone.inches,sim.drone.acro,sim.wind_level)

func best_for(index: int) -> float:
	return float(records.get_value(key_for(Catalog.ACTIVITIES[index].id,sim.drone.inches,sim.drone.acro,sim.wind_level),"best",0.0))

func completions(index: int) -> int:
	return int(records.get_value(key_for(Catalog.ACTIVITIES[index].id,sim.drone.inches,sim.drone.acro,sim.wind_level),"completions",0))

func select_activity(index: int) -> bool:
	if sim.drone.armed or index < 0 or index >= Catalog.ACTIVITIES.size():
		sim.flash("DISARM BEFORE CHANGING TRAINING AREA")
		return false
	selected = index
	activity = Catalog.activity(index)
	sim.field.set_course(activity)
	sim.drone.spawn_transform = Transform3D(Basis.IDENTITY,activity.spawn)
	sim.completed_laps = 0
	sim.reset_flight()
	refresh_best()
	sim.flash(activity.name.to_upper()+" / SPACE TO ARM",5.0)
	return true

func refresh_best() -> void:
	sim.best_lap = best_for(selected) if selected>=0 else 0.0

func reset_attempt() -> void:
	hold = 0.0
	elapsed = 0.0
	took_off = false
	complete = false

func update(delta: float) -> void:
	if sim.drone.armed and not sim.drone.crashed:
		if sim.drone.height_above_pad() > 0.2:
			flight_seconds += delta
			distance_metres += sim.drone.linear_velocity.length()*delta
		elapsed += delta
	save_clock += delta
	if save_clock > 30.0:
		save_progress()
		save_clock = 0
	if complete or sim.drone.crashed or activity.kind in ["race","free"]:
		return
	var position: Vector3 = sim.drone.global_position
	var offset: Vector3 = position-activity.target
	var good := false
	if activity.kind == "hover":
		good = sim.drone.armed and absf(offset.x) <= 2 and absf(offset.z) <= 2 and absf(offset.y) <= 0.5 and sim.drone.linear_velocity.length() < 0.7
	else:
		took_off = took_off or (sim.drone.armed and sim.drone.height_above_pad() > 1.5)
		good = took_off and absf(offset.x) < 1.65 and absf(offset.z) < 1.65 and sim.drone.get_contact_count() > 0 and sim.drone.linear_velocity.length() < 0.25 and sim.drone.global_basis.y.dot(Vector3.UP) > 0.98
	hold = hold+delta if good else 0.0
	if hold >= (10.0 if activity.kind == "hover" else 1.0):
		complete = true
		record_result(elapsed)
		sim.flash("LESSON COMPLETE / "+activity.name.to_upper()+" / F5 NEXT EXERCISE",8.0)

func record_result(seconds: float) -> void:
	if seconds <= 0 or not is_finite(seconds):
		return
	var key := current_key()
	var previous := float(records.get_value(key,"best",0.0))
	if previous <= 0 or seconds < previous:
		records.set_value(key,"best",seconds)
	records.set_value(key,"completions",int(records.get_value(key,"completions",0))+1)
	refresh_best()
	save_progress()

func progress_text() -> String:
	if activity.kind=="free":
		return "FREE ROAM / F6 LAUNCH SITES / F7 LIGHT / F8 QUALITY / F9 HOME"
	if activity.kind == "race":
		return "GATE %02d / %02d   %s" % [sim.next_gate+1,sim.field.gates.size(),"%.1f s" % sim.lap_time if sim.course_started else "CROSS 01 TO START"]
	if complete:
		return "COMPLETE / R TO REPEAT / F5 NEXT EXERCISE"
	if activity.kind == "hover":
		return "STEADY HOVER  %.1f / 10.0 s" % hold
	return "TAKE OFF ABOVE 1.5 m" if not took_off else "GENTLE LANDING  %.1f / 1.0 s" % hold

func save_progress() -> void:
	if records_path.is_empty():
		return
	records.set_value("pilot","flight_seconds",flight_seconds)
	records.set_value("pilot","distance_metres",distance_metres)
	records.set_value("pilot","impacts",impacts)
	var error := records.save(records_path)
	if error != OK:
		push_warning("Could not save training progress: "+error_string(error))

func _exit_tree() -> void:
	save_progress()
