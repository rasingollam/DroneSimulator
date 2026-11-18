extends Node
## Versioned, paired LAN controller protocol. Full-state packets supersede old ones.

const PORT := 42424
const HOLD_MS := 350
const TIMEOUT_MS := 2000
const ACTIONS := ["", "arm", "disarm", "reset", "camera", "mode", "pause", "resume", "disconnect", "drone2", "drone3", "drone4", "drone5"]
var sim: Node3D
var socket := PacketPeerUDP.new()
var pin := ""
var addresses := PackedStringArray()
var connected := false
var enabled := true
var listen_error := OK
var peer_ip := ""
var peer_port := 0
var session := ""
var last_sequence := -1
var action_ack := 0
var last_received_ms := 0
var received_packets := 0
var loss_reason := "Waiting for phone"
var listen_port := PORT
var recovering := false
var recovery_auto_resume := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pin = "%06d" % (Crypto.new().generate_random_bytes(4).decode_u32(0) % 1000000)
	for address in IP.get_local_addresses():
		if address.count(".") == 3 and not address.begins_with("127.") and not address.begins_with("169.254."):
			addresses.append(address)
	# Test scenes use an ephemeral port so they never collide with a running game.
	listen_error = socket.bind(int(sim.get_meta("controller_port", PORT)), "0.0.0.0", 65536)
	if listen_error == OK:
		listen_port = socket.get_local_port()
	if listen_error != OK:
		loss_reason = "Port 42424 unavailable; close other simulator windows"

func _process(_delta: float) -> void:
	if listen_error != OK:
		return
	# Bounded work prevents incoming traffic from starving the simulation.
	for i in range(mini(socket.get_available_packet_count(), 128)):
		var bytes := socket.get_packet()
		var ip := socket.get_packet_ip()
		var port := socket.get_packet_port()
		if bytes.size() > 1200 or not enabled:
			continue
		var parsed: Variant = JSON.parse_string(bytes.get_string_from_utf8())
		if parsed is Dictionary:
			_accept(parsed, ip, port)
	if connected:
		var silence := Time.get_ticks_msec() - last_received_ms
		if silence > TIMEOUT_MS:
			lose_link("PHONE DISCONNECTED / FLIGHT PAUSED")
		elif silence > HOLD_MS:
			if not recovering:
				recovering = true
				recovery_auto_resume = not sim.get_tree().paused
				loss_reason = "Brief signal gap; holding flight"
				sim.flash("PHONE SIGNAL DELAYED / HOLDING FLIGHT",3.0)
			# Freeze physics instead of flying on stale stick commands.
			sim.paused = true
			sim.get_tree().paused = true

func _number(value: Variant, minimum: float, maximum: float) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and float(value) >= minimum and float(value) <= maximum

func _accept(packet: Dictionary, ip: String, port: int) -> void:
	if packet.get("v") != 1 or packet.get("pin") != pin:
		return
	if not packet.get("session") is String or packet.session.length() < 8 or packet.session.length() > 64:
		return
	if not _number(packet.get("seq"), 0, 1e12) or float(packet.seq) != floor(float(packet.seq)):
		return
	if not _number(packet.get("sent"), 0, 1e15):
		return
	if not _number(packet.get("throttle"), 0, 1) or not _number(packet.get("yaw"), -1, 1) or not _number(packet.get("pitch"), -1, 1) or not _number(packet.get("roll"), -1, 1):
		return
	if not _number(packet.get("action_id"), 0, 1e12) or float(packet.action_id) != floor(float(packet.action_id)) or packet.get("action") not in ACTIONS:
		return
	var just_paired := false
	if connected:
		if ip != peer_ip or port != peer_port or packet.session != session:
			return
	else:
		# Pair/re-pair only at zero power with all centering axes neutral.
		if packet.throttle > 0.02 or absf(packet.yaw) > 0.05 or absf(packet.pitch) > 0.05 or absf(packet.roll) > 0.05:
			return
		if packet.session == session and int(packet.seq) <= last_sequence:
			return
		peer_ip = ip
		peer_port = port
		if packet.session != session:
			session = packet.session
			last_sequence = -1
			action_ack = 0
		connected = true
		just_paired = true
		loss_reason = "Phone connected"
		sim.drone.set_armed(false)
		sim.drone.remote_active = true
		sim.show_help = false
		sim.show_phone = false
		# Connection never starts flight on its own.
		sim.paused = true
		sim.get_tree().paused = true
		sim.flash("PHONE CONNECTED / TAP START ON PHONE")
	if int(packet.seq) <= last_sequence:
		return
	last_sequence = int(packet.seq)
	last_received_ms = Time.get_ticks_msec()
	received_packets += 1
	if recovering:
		recovering = false
		if recovery_auto_resume and not sim.show_help and not sim.show_phone and not sim.show_fleet and not sim.show_training and not sim.show_explorer:
			sim.paused = false
			sim.get_tree().paused = false
			sim.flash("PHONE SIGNAL RESTORED",2.0)
		recovery_auto_resume = false
		loss_reason = "Phone connected"
	sim.drone.remote_throttle = float(packet.throttle)
	sim.drone.remote_stick = Vector3(float(packet.pitch), -float(packet.yaw), -float(packet.roll))
	if just_paired:
		# Discard in-flight commands from before a link loss; reconnect stays paused.
		action_ack = maxi(action_ack, int(packet.action_id))
	elif int(packet.action_id) > action_ack:
		action_ack = int(packet.action_id)
		_action(packet.action)
	if not connected:
		return
	var reply := {"v": 1, "session": session, "seq": last_sequence, "sent": packet.sent,
		"action_ack": action_ack, "armed": sim.drone.armed, "paused": sim.get_tree().paused,
		"acro": sim.drone.acro, "crashed": sim.drone.crashed, "fpv": sim.fpv,
		"height": sim.drone.height_above_pad(), "speed": sim.drone.linear_velocity.length() * 3.6,
		"throttle": sim.drone.throttle, "drone_inches": sim.drone.inches,
		"drone_name": sim.drone.profile.name, "hover_throttle": sim.drone.hover_throttle()}
	socket.set_dest_address(ip, port)
	socket.put_packet(JSON.stringify(reply).to_utf8_buffer())

func _action(action: String) -> void:
	match action:
		"arm":
			if not sim.get_tree().paused and sim.drone.remote_throttle <= 0.02 and sim.drone.remote_stick.length() < 0.1:
				sim.drone.set_armed(true)
		"disarm":
			sim.drone.set_armed(false)
		"reset":
			sim.reset_flight()
		"camera":
			sim.toggle_camera()
		"mode":
			sim.toggle_mode()
		"pause":
			sim.paused = true
			sim.get_tree().paused = true
		"resume":
			# PC training selection must be completed deliberately before resuming.
			if sim.show_training or sim.show_explorer:
				return
			sim.show_fleet = false
			sim.show_help = false
			sim.show_phone = false
			sim.paused = false
			sim.get_tree().paused = false
		"disconnect":
			lose_link("PHONE DISCONNECTED / FLIGHT PAUSED")
		"drone2", "drone3", "drone4", "drone5":
			sim.select_airframe(int(action.right(1)))

func lose_link(reason: String) -> void:
	recovering = false
	recovery_auto_resume = false
	connected = false
	peer_ip = ""
	sim.drone.remote_throttle = 0.0
	sim.drone.remote_stick = Vector3.ZERO
	sim.drone.set_armed(false)
	sim.drone.stick = Vector3.ZERO
	sim.paused = true
	sim.get_tree().paused = true
	loss_reason = reason
	sim.flash(reason, 8.0)

func cancel_auto_recovery() -> void:
	recovery_auto_resume = false

func use_keyboard() -> void:
	if connected or sim.drone.remote_active:
		lose_link("KEYBOARD CONTROL / ESC TO RESUME")
	enabled = false
	sim.drone.remote_active = false
	sim.show_phone = false

func _exit_tree() -> void:
	socket.close()
