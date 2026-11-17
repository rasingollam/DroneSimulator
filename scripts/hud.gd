extends Control

var sim: Node3D
var regular: SystemFont
var bold: SystemFont
var mono: SystemFont
const INK := Color("e2eee9")
const MUTED := Color("859d9e")
const TEAL := Color("6ef0ce")
const AMBER := Color("edb86b")
const PANEL := Color(0.025, 0.065, 0.075, 0.89)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	regular = SystemFont.new()
	regular.font_names = PackedStringArray(["Segoe UI", "DejaVu Sans"])
	bold = SystemFont.new()
	bold.font_names = regular.font_names
	bold.font_weight = 700
	mono = SystemFont.new()
	mono.font_names = PackedStringArray(["Consolas", "DejaVu Sans Mono"])

func text(value: String, at: Vector2, size_px: int = 16, color: Color = INK, font: Font = null) -> void:
	draw_string(regular if font == null else font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func line(a: Vector2, b: Vector2, color: Color = Color(0.45, 0.65, 0.64, 0.22), width: float = 1.0) -> void:
	draw_line(a, b, color, width, true)

func panel(rect: Rect2) -> void:
	draw_style_box(_panel_style(), rect)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = Color(0.45, 0.65, 0.64, 0.24)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style

func pill(value: String, rect: Rect2, color: Color = TEAL) -> void:
	draw_rect(rect, Color(color, 0.10))
	draw_rect(rect, Color(color, 0.5), false, 1.0)
	text(value, rect.position + Vector2(12, 21), 12, color, bold)

func _draw() -> void:
	if sim == null or not is_instance_valid(sim.drone):
		return
	var viewport := get_viewport_rect().size
	var scale_factor := minf(viewport.x / 1440.0, viewport.y / 900.0)
	var offset := (viewport - Vector2(1440, 900) * scale_factor) / 2.0
	draw_set_transform(offset, 0.0, Vector2.ONE * scale_factor)
	if sim.show_fleet:
		_fleet()
		return
	var d: RigidBody3D = sim.drone
	if sim.hud_mode == 1:
		_header(d)
		_telemetry(d)
		_map(d)
		_flight_overlay(d, offset, scale_factor)
	elif sim.hud_mode == 0:
		_minimal(d)
	if sim.hud_mode != 2:
		_stick_indicators(d)
	var show_message: bool = sim.hud_mode == 1 or not d.armed or sim.message.begins_with("PHONE") or sim.message.begins_with("LAP ")
	if sim.hud_mode != 2 and show_message and sim.message_time > 0 and not sim.show_help and not sim.show_phone and not d.crashed:
		var width := maxf(440, mono.get_string_size(sim.message, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 48)
		panel(Rect2((1440 - width) / 2, 681, width, 38))
		text(sim.message, Vector2((1440 - width) / 2 + 24, 705), 14, TEAL, mono)
	if d.crashed and not sim.show_help and not sim.show_phone:
		panel(Rect2(494, 371, 452, 135))
		text("HARD IMPACT", Vector2(607, 419), 28, AMBER, bold)
		var reset_hint := "Tap RESET on your phone to return to the pad." if d.remote_active else "Press R to return to the pad."
		text(reset_hint, Vector2(535, 459), 16, INK)
	if sim.paused and not sim.show_help and not sim.show_phone and not sim.show_fleet:
		_veil(Color(0.01, 0.035, 0.045, 0.26))
		panel(Rect2(480, 365, 480, 150))
		text("PAUSED", Vector2(651, 424), 30, INK, bold)
		var resume_hint := "Tap START / RESUME on your phone" if d.remote_active else "ESC to resume"
		text(resume_hint, Vector2(562 if d.remote_active else 660, 470), 16, MUTED)
	if sim.show_help and not sim.show_phone:
		_help()
	if sim.show_phone:
		_phone_help()
	if sim.show_fleet:
		_fleet()
	elif sim.hud_mode == 1 and sim.phone != null and sim.phone.connected and not sim.show_help:
		pill("PHONE CONNECTED / F2 SETTINGS", Rect2(555, 172, 330, 32), TEAL)
	elif sim.hud_mode == 1 and not sim.show_help:
		text("F2  PHONE CONTROLLER", Vector2(629, 703), 13, TEAL, mono)

func _screen_bounds() -> Rect2:
	var viewport := get_viewport_rect().size
	var factor := minf(viewport.x / 1440.0, viewport.y / 900.0)
	var margin := (viewport - Vector2(1440, 900) * factor) / 2.0
	return Rect2(-margin / factor, viewport / factor)

func _veil(color: Color) -> void:
	draw_rect(_screen_bounds(), color)

func _quiet_text(value: String, at: Vector2, color: Color = INK) -> void:
	text(value, at + Vector2.ONE, 13, Color(0, 0, 0, 0.8), mono)
	text(value, at, 13, color, mono)

func _minimal(d: RigidBody3D) -> void:
	var bounds := _screen_bounds()
	var left := Vector2(bounds.position.x + 28, bounds.end.y - (49 if not d.armed else 27))
	var state := "IMPACT" if d.crashed else ("ARMED" if d.armed else "DISARMED")
	var source := "PHONE" if sim.phone != null and sim.phone.connected else ("LINK LOST" if d.remote_active else "KEYBOARD")
	_quiet_text('%s  ·  %d" %s  ·  %s  ·  %s' % [state, d.inches, d.profile.name, "ACRO" if d.acro else "ANGLE", source], left, TEAL if d.armed else INK)
	if not d.armed:
		_quiet_text("F1 help   F2 phone   F3 display   F4 airframes", left + Vector2(0, 23), Color(INK, 0.7))
	var speed := Vector2(d.linear_velocity.x, d.linear_velocity.z).length() * 3.6
	_quiet_text("%.1f m   %.0f km/h" % [d.height_above_pad(), speed], Vector2(bounds.end.x - 196, bounds.end.y - 27), Color(INK, 0.8))

func _stick_indicators(d: RigidBody3D) -> void:
	var bounds := _screen_bounds()
	var center := Vector2(bounds.get_center().x, bounds.end.y - 104)
	# Show the phone's received command immediately, before flight-controller smoothing.
	var command: Vector3 = d.remote_stick if d.remote_active else d.stick
	var throttle: float = d.remote_throttle if d.remote_active else d.throttle
	_gimbal(center + Vector2(-94, 0), Vector2(-command.y, 1.0 - 2.0 * throttle), "THROTTLE / YAW")
	_gimbal(center + Vector2(94, 0), Vector2(-command.z, command.x), "PITCH / ROLL")

func _gimbal(center: Vector2, value: Vector2, caption: String) -> void:
	value = value.clamp(Vector2(-1, -1), Vector2.ONE)
	draw_circle(center, 66, Color(0.025, 0.065, 0.075, 0.23))
	draw_arc(center, 66, 0, TAU, 80, Color(0.86, 0.95, 0.92, 0.30), 1.2, true)
	var guide := StyleBoxFlat.new()
	guide.bg_color = Color.TRANSPARENT
	guide.border_color = Color(0.8, 0.94, 0.89, 0.16)
	guide.set_border_width_all(1)
	guide.set_corner_radius_all(8)
	draw_style_box(guide, Rect2(center - Vector2.ONE * 44, Vector2.ONE * 88))
	line(center - Vector2(54, 0), center + Vector2(54, 0), Color(0.8, 0.94, 0.89, 0.23))
	line(center - Vector2(0, 54), center + Vector2(0, 54), Color(0.8, 0.94, 0.89, 0.23))
	var knob := center + value * 44.0
	line(center, knob, Color(TEAL, 0.35), 1.5)
	draw_circle(center, 2, Color(INK, 0.35))
	draw_circle(knob, 16, Color(TEAL, 0.13))
	draw_circle(knob, 8, Color(TEAL, 0.9))
	draw_arc(knob, 8, 0, TAU, 32, Color(INK, 0.65), 1.0, true)
	var caption_width := mono.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var at := center + Vector2(-caption_width / 2.0, 85)
	text(caption, at + Vector2.ONE, 11, Color(0, 0, 0, 0.65), mono)
	text(caption, at, 11, Color(INK, 0.7), mono)

func _header(d: RigidBody3D) -> void:
	panel(Rect2(24, 22, 1392, 78))
	draw_rect(Rect2(24, 22, 5, 78), TEAL)
	text("VECTOR", Vector2(49, 62), 30, INK, bold)
	text("F L I G H T   L A B", Vector2(51, 83), 10, MUTED, bold)
	line(Vector2(232, 41), Vector2(232, 82))
	text("FIELD 01", Vector2(256, 54), 12, TEAL, mono)
	text("Meadow training ground", Vector2(256, 79), 17)
	pill("ACRO / RATE" if d.acro else "ANGLE / SELF-LEVEL", Rect2(551, 45, 171, 33), AMBER if d.acro else TEAL)
	pill("FPV  %02d°" % int(sim.fpv_tilt) if sim.fpv else "CHASE VIEW", Rect2(737, 45, 130, 33), INK)
	var state := "CRASHED" if d.crashed else ("ARMED" if d.armed else "DISARMED")
	draw_circle(Vector2(918, 62), 4, AMBER if not d.armed else TEAL)
	text(state, Vector2(932, 68), 13, AMBER if not d.armed else TEAL, bold)
	text("240 Hz", Vector2(1097, 54), 16, INK, mono)
	text("PHYSICS", Vector2(1097, 77), 10, MUTED)
	text("F1", Vector2(1336, 58), 16, TEAL, mono)
	text("FLIGHT GUIDE", Vector2(1299, 80), 10, MUTED)

func _telemetry(d: RigidBody3D) -> void:
	panel(Rect2(24, 120, 247, 337))
	text("LIVE TELEMETRY", Vector2(43, 149), 11, TEAL, bold)
	text("GROUND SPEED", Vector2(43, 182), 11, MUTED)
	var speed := Vector2(d.linear_velocity.x, d.linear_velocity.z).length() * 3.6
	text("%04.1f" % speed, Vector2(40, 230), 46, INK, mono)
	text("km/h", Vector2(198, 226), 13, MUTED)
	line(Vector2(43, 246), Vector2(252, 246))
	text("HEIGHT / FIELD", Vector2(43, 272), 11, MUTED)
	text("%05.2f" % d.height_above_pad(), Vector2(43, 309), 31, INK, mono)
	text("m", Vector2(217, 307), 13, MUTED)
	text("VERTICAL", Vector2(43, 341), 11, MUTED)
	text("%+.1f m/s" % d.linear_velocity.y, Vector2(151, 341), 14, INK, mono)
	text("THROTTLE", Vector2(43, 376), 11, MUTED)
	text("%02d %%" % roundi(d.throttle * 100), Vector2(199, 376), 14, TEAL, mono)
	draw_rect(Rect2(43, 390, 209, 5), Color(0.3, 0.45, 0.45, 0.3))
	draw_rect(Rect2(43, 390, 209 * d.throttle, 5), TEAL)
	var hover := sqrt(d.mass * 9.80665 / (4.0 * d.MAX_THRUST))
	line(Vector2(43 + 209 * hover, 386), Vector2(43 + 209 * hover, 400), AMBER)
	text("THRUST  %04.1f N" % d.total_thrust, Vector2(43, 430), 12, MUTED, mono)
	text("Reference: landing pad elevation", Vector2(29, 477), 11, Color(0.9, 0.96, 0.91, 0.7))
	panel(Rect2(24, 497, 247, 93))
	text("AIR CONDITIONS", Vector2(43, 525), 11, MUTED, bold)
	text("CALM" if sim.wind_level == 0 else "WIND  %.1f m/s" % d.wind.length(), Vector2(43, 558), 21, INK, mono)
	text("B  cycle wind", Vector2(43, 578), 11, MUTED)

func _map(d: RigidBody3D) -> void:
	panel(Rect2(1148, 120, 268, 299))
	text("TRAINING CIRCUIT", Vector2(1167, 149), 11, TEAL, bold)
	var map_rect := Rect2(1168, 167, 228, 186)
	for i in range(7):
		line(Vector2(map_rect.position.x + i * 38, 167), Vector2(map_rect.position.x + i * 38, 353), Color(0.4, 0.65, 0.63, 0.10))
	for i in range(5):
		line(Vector2(1168, 167 + i * 46), Vector2(1396, 167 + i * 46), Color(0.4, 0.65, 0.63, 0.10))
	var points := PackedVector2Array()
	for gate in sim.field.gates:
		points.append(_map_point(gate.position))
	points.append(points[0])
	draw_polyline(points, Color(0.5, 0.67, 0.63, 0.4), 1.5, true)
	for i in range(sim.field.gates.size()):
		var at: Vector2 = points[i]
		draw_circle(at, 5 if i == sim.next_gate else 3, TEAL if i == sim.next_gate else MUTED)
		text(str(i + 1), at + Vector2(7, 4), 10, MUTED, mono)
	var pos := _map_point(d.position)
	pos = pos.clamp(map_rect.position, map_rect.end)
	var forward := Vector2(-d.global_basis.z.x, -d.global_basis.z.z).normalized()
	var side := Vector2(-forward.y, forward.x)
	draw_colored_polygon(PackedVector2Array([pos + forward * 8, pos - forward * 5 + side * 4, pos - forward * 5 - side * 4]), INK)
	text("N", Vector2(1378, 181), 10, MUTED, mono)
	line(Vector2(1167, 367), Vector2(1396, 367))
	var distance: float = d.position.distance_to(sim.field.gates[sim.next_gate].position)
	text("NEXT  %02d / 07" % (sim.next_gate + 1), Vector2(1167, 396), 14, INK, mono)
	text("%03d m" % int(distance), Vector2(1342, 396), 14, TEAL, mono)
	panel(Rect2(1148, 435, 268, 131))
	text("LAP %02d" % (sim.completed_laps + 1), Vector2(1167, 465), 11, MUTED, bold)
	text(_time(sim.lap_time), Vector2(1167, 504), 29, INK, mono)
	text("BEST  " + (_time(sim.best_lap) if sim.best_lap > 0 else "--:--.--"), Vector2(1167, 542), 13, MUTED, mono)

func _map_point(pos: Vector3) -> Vector2:
	return Vector2(1210 + pos.x * 2.05, 322 + pos.z * 1.7)

func _time(seconds: float) -> String:
	return "%02d:%05.2f" % [int(seconds) / 60, fmod(seconds, 60)]

func _flight_overlay(d: RigidBody3D, offset: Vector2, scale_factor: float) -> void:
	var center := Vector2(720, 426)
	var heading := fposmod(rad_to_deg(atan2(-d.global_basis.z.x, d.global_basis.z.z)), 360.0)
	panel(Rect2(624, 119, 192, 42))
	text("HDG  %03d°" % roundi(heading), Vector2(666, 146), 15, INK, mono)
	for x in [-1, 1]:
		line(center + Vector2(x * 12, 0), center + Vector2(x * 28, 0), Color(0.8, 1, 0.95, 0.65), 1.5)
	line(center + Vector2(0, 9), center + Vector2(0, 16), Color(0.8, 1, 0.95, 0.65), 1.5)
	draw_circle(center, 2, Color(0.8, 1, 0.95, 0.65))
	if sim.fpv:
		var roll := d.rotation.z
		var pitch := d.rotation.x
		for i in [-2, -1, 0, 1, 2]:
			var y: float = pitch * 170 + i * 35.0
			var a := Vector2(-55 if i == 0 else -24, y).rotated(roll)
			var b := Vector2(55 if i == 0 else 24, y).rotated(roll)
			line(center + a, center + b, Color(0.8, 1, 0.95, 0.35), 1.0)
	var gate: Node3D = sim.field.gates[sim.next_gate]
	var target := gate.position + Vector3.UP * 3.1
	if not sim.camera.is_position_behind(target):
		var screen: Vector2 = (sim.camera.unproject_position(target) - offset) / scale_factor
		if screen.x > 295 and screen.x < 1130 and screen.y > 190 and screen.y < 695:
			var diamond := PackedVector2Array([screen + Vector2(0, -8), screen + Vector2(8, 0), screen + Vector2(0, 8), screen + Vector2(-8, 0), screen + Vector2(0, -8)])
			draw_polyline(diamond, TEAL, 1.5, true)
			text("%02d" % (sim.next_gate + 1), screen + Vector2(14, 5), 12, TEAL, mono)
	if not d.armed and not d.crashed:
		text("SPACE TO ARM", Vector2(639, 651), 19, INK, bold)
		text("W / S adjusts throttle · release to keep setting", Vector2(550, 678), 13, INK)

func _footer(d: RigidBody3D) -> void:
	panel(Rect2(24, 785, 1392, 92))
	_stick(Vector2(80, 831), Vector2(d.stick.y * -1, 1.0 - d.throttle * 2.0), "L")
	text("W / S   THROTTLE", Vector2(126, 821), 12, INK, mono)
	text("A / D   YAW", Vector2(126, 846), 12, MUTED, mono)
	line(Vector2(328, 805), Vector2(328, 859))
	_stick(Vector2(387, 831), Vector2(-d.stick.z, d.stick.x), "R")
	text("↑ / ↓   PITCH", Vector2(433, 821), 12, INK, mono)
	text("← / →   ROLL", Vector2(433, 846), 12, MUTED, mono)
	line(Vector2(633, 805), Vector2(633, 859))
	text("SPACE", Vector2(660, 821), 12, TEAL, mono)
	text("arm / disarm", Vector2(720, 821), 12, INK)
	text("R", Vector2(660, 847), 12, TEAL, mono)
	text("reset", Vector2(720, 847), 12, INK)
	text("C", Vector2(863, 821), 12, TEAL, mono)
	text("camera", Vector2(904, 821), 12, INK)
	text("TAB", Vector2(863, 847), 12, TEAL, mono)
	text("flight mode", Vector2(904, 847), 12, INK)
	text("H", Vector2(1045, 821), 12, TEAL, mono)
	text("hover throttle", Vector2(1083, 821), 12, INK)
	text("ESC", Vector2(1045, 847), 12, TEAL, mono)
	text("pause", Vector2(1083, 847), 12, INK)
	text("%.0f g" % (d.mass * 1000), Vector2(1291, 821), 14, INK, mono)
	text('%d-INCH QUAD' % d.inches, Vector2(1278, 847), 10, MUTED)

func _stick(center: Vector2, value: Vector2, side: String) -> void:
	draw_circle(center, 29, Color(0.15, 0.25, 0.25, 0.5))
	draw_arc(center, 29, 0, TAU, 48, Color(0.5, 0.7, 0.67, 0.4), 1, true)
	line(center - Vector2(24, 0), center + Vector2(24, 0))
	line(center - Vector2(0, 24), center + Vector2(0, 24))
	draw_circle(center + value * 21, 5, TEAL)
	text(side, center + Vector2(-36, -25), 10, MUTED, mono)

func _help() -> void:
	_veil(Color(0.015, 0.04, 0.05, 0.84))
	panel(Rect2(310, 124, 820, 654))
	draw_rect(Rect2(310, 124, 820, 4), TEAL)
	text("V E C T O R   /   F L I G H T   L A B", Vector2(356, 173), 12, TEAL, bold)
	text("Learn to fly. Feel the physics.", Vector2(353, 227), 36, INK, bold)
	text("One open field. Four motors. Your first flight starts here.", Vector2(356, 261), 17, MUTED)
	line(Vector2(356, 289), Vector2(1084, 289))
	text("01   LEFT STICK", Vector2(356, 323), 12, TEAL, bold)
	text("W / S", Vector2(356, 361), 24, INK, mono)
	text("Raise / lower throttle", Vector2(500, 359), 16)
	text("A / D", Vector2(356, 398), 24, INK, mono)
	text("Yaw left / right", Vector2(500, 396), 16)
	text("02   RIGHT STICK", Vector2(761, 323), 12, TEAL, bold)
	text("↑ / ↓", Vector2(761, 361), 24, INK, mono)
	text("Pitch forward / back", Vector2(890, 359), 16)
	text("← / →", Vector2(761, 398), 24, INK, mono)
	text("Roll left / right", Vector2(890, 396), 16)
	line(Vector2(356, 427), Vector2(1084, 427))
	text("YOUR FIRST TAKEOFF", Vector2(356, 460), 12, TEAL, bold)
	text("1", Vector2(356, 494), 17, TEAL, mono)
	text("Press SPACE to arm. Raise throttle past ~%d%% for this airframe." % roundi(sim.drone.hover_throttle() * 100), Vector2(386, 494), 16)
	text("2", Vector2(356, 526), 17, TEAL, mono)
	text("Release W to keep throttle. Tap S to descend. H sets level-hover power.", Vector2(386, 526), 16)
	text("3", Vector2(356, 558), 17, TEAL, mono)
	text("Use small arrow-key inputs. Aim for the teal gate. R resets after a crash.", Vector2(386, 558), 16)
	text("ANGLE self-levels. TAB switches to ACRO; tilt stays when sticks are released.", Vector2(356, 601), 14, MUTED)
	text("F2 pairs phone. F3 cycles displays. F4 chooses airframes. F11 full screen.", Vector2(356, 625), 14, MUTED)
	text("Keyboard inputs are smoothed; real radio sticks provide much finer control.", Vector2(356, 659), 13, AMBER)
	text("Physics-based training model. Handling needs validation against your real drone.", Vector2(356, 682), 13, MUTED)
	draw_rect(Rect2(356, 710, 728, 42), TEAL)
	text("ENTER   /   ENTER THE FIELD", Vector2(581, 737), 14, Color("092c2a"), bold)

func _fleet() -> void:
	_veil(Color(0.015, 0.03, 0.04, 0.20))
	text("AIRFRAME HANGAR", Vector2(64, 95), 16, TEAL, bold)
	text("Find your flying style.", Vector2(61, 151), 42, INK, bold)
	text("2 / 3 / 4 / 5 to select  ·  ENTER or F4 to return to the field", Vector2(64, 187), 17, INK)
	text("Open-prop builds · all-up mass includes battery · shared stick rates for comparison", Vector2(64, 219), 14, Color(INK, 0.8))
	var Profiles = preload("res://scripts/drone_profiles.gd")
	for i in range(4):
		var inches := i + 2
		var p := Profiles.get_profile(inches)
		var x := 64.0 + i * 333.0
		var selected: bool = sim.drone.inches == inches
		panel(Rect2(x, 532, 313, 285))
		if selected:
			draw_rect(Rect2(x, 532, 313, 3), p.color)
		text('%d"' % inches, Vector2(x + 20, 577), 31, p.color, bold)
		text(p.name, Vector2(x + 80, 568), 18, INK, bold)
		text(p.role, Vector2(x + 80, 591), 12, MUTED)
		line(Vector2(x + 20, 610), Vector2(x + 293, 610))
		text("%.0f g AUW     %dS / %d mAh" % [p.mass * 1000, p.cells, p.capacity], Vector2(x + 20, 637), 13, INK, mono)
		text("%d mm frame   %d ms motor" % [roundi(p.wheelbase * 1000), roundi(p.tau * 1000)], Vector2(x + 20, 662), 13, MUTED, mono)
		text("%.1f:1 T/W     ~%d%% hover" % [4 * p.thrust / (p.mass * 9.80665), roundi(Profiles.hover(inches) * 100)], Vector2(x + 20, 687), 13, INK, mono)
		text(p.motor, Vector2(x + 20, 712), 12, MUTED, mono)
		text("%.1f N total · %.0f mm props" % [4 * p.thrust, inches * 25.4], Vector2(x + 20, 740), 12, MUTED, mono)
		pill("SELECTED" if selected else "PRESS %d TO SELECT" % inches, Rect2(x + 20, 766, 273, 32), p.color if selected else MUTED)
	text("Representative simulation setups. Thrust, inertia, drag and response are estimates; real builds vary.", Vector2(64, 856), 14, INK)

func _phone_help() -> void:
	_veil(Color(0.015, 0.04, 0.05, 0.90))
	panel(Rect2(340, 170, 760, 560))
	draw_rect(Rect2(340, 170, 760, 4), TEAL)
	text("ANDROID / TOUCH CONTROLLER", Vector2(380, 220), 14, TEAL, bold)
	text("Pair your phone", Vector2(378, 271), 38, INK, bold)
	text("Connect phone and PC to the same private Wi-Fi network.", Vector2(380, 311), 17, MUTED)
	text("PC ADDRESS", Vector2(380, 362), 12, MUTED, bold)
	var address := "No IPv4 address found" if sim.phone.addresses.is_empty() else "  /  ".join(sim.phone.addresses)
	text(address, Vector2(380, 399), 24, INK, mono)
	text("PAIRING CODE", Vector2(380, 448), 12, MUTED, bold)
	text(sim.phone.pin, Vector2(377, 498), 44, TEAL, mono)
	text("Open Vector Controller on your phone and enter these details.", Vector2(380, 541), 16, INK)
	text("Then tap START / RESUME, ARM, and gently raise the left stick.", Vector2(380, 570), 16, INK)
	text("Allow Godot on Private networks if Windows Firewall asks.", Vector2(380, 610), 14, AMBER)
	text(sim.phone.loss_reason + "  /  UDP 42424", Vector2(380, 644), 13, MUTED, mono)
	text("F2  close settings       K  disconnect phone and use keyboard", Vector2(380, 693), 13, TEAL, mono)
