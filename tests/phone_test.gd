extends SceneTree

var sim: Node3D
var client := PacketPeerUDP.new()
var sequence := 0
var failures := 0
var reply := {}
var packet := {"v": 1, "pin": "", "session": "test-phone-session", "seq": 0, "sent": 100,
	"throttle": 0.0, "yaw": 0.0, "pitch": 0.0, "roll": 0.0, "action": "", "action_id": 0}

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	print("PASS: " if condition else "FAIL: ", description)
	if not condition:
		failures += 1

func send(changes: Dictionary = {}) -> void:
	sequence += 1
	packet.seq = sequence
	packet.merge(changes, true)
	client.put_packet(JSON.stringify(packet).to_utf8_buffer())
	for i in range(8):
		await process_frame
	while client.get_available_packet_count() > 0:
		reply = JSON.parse_string(client.get_packet().get_string_from_utf8())

func run() -> void:
	sim = load("res://scenes/main.tscn").instantiate()
	root.add_child(sim)
	current_scene = sim
	await process_frame
	check(sim.phone.listen_error == OK, "UDP listener binds port 42424")
	client.bind(0, "127.0.0.1")
	client.set_dest_address("127.0.0.1", 42424)
	await send({"pin": "invalid"})
	check(not sim.phone.connected, "Wrong pairing code cannot take control")
	await send({"pin": sim.phone.pin, "throttle": 0.7})
	check(not sim.phone.connected, "Pairing requires zero throttle")
	await send({"throttle": 0.0})
	check(sim.phone.connected and sim.drone.remote_active and paused, "Real UDP handshake pairs and leaves flight paused")
	check(reply.get("session") == packet.session and reply.get("seq") == sequence, "Telemetry echoes session and packet sequence")
	await send({"action": "arm", "action_id": 1})
	check(not sim.drone.armed, "Arming while paused is rejected")
	await send({"action": "resume", "action_id": 2})
	check(not paused and not sim.show_help, "Phone can start the simulation")
	await send({"action": "arm", "action_id": 3})
	check(sim.drone.armed, "Explicit zero-throttle command arms")
	await send({"action": "", "throttle": 0.58, "pitch": -0.4, "yaw": 0.3, "roll": 0.2})
	check(sim.drone.remote_stick.is_equal_approx(Vector3(-0.4, -0.3, -0.2)), "Phone axes map to correct body pitch/yaw/roll signs")
	check(is_equal_approx(sim.drone.throttle, 0.58), "Analog throttle reaches physics controller directly")
	var accepted: int = sim.phone.last_sequence
	await send({"seq": accepted - 1, "throttle": 0.9})
	check(is_equal_approx(sim.drone.remote_throttle, 0.58), "Out-of-order packets cannot overwrite newer controls")
	await send({"throttle": 1.5})
	check(is_equal_approx(sim.drone.remote_throttle, 0.58), "Out-of-range control packets are rejected")
	var rogue := PacketPeerUDP.new()
	rogue.bind(0, "127.0.0.1")
	rogue.set_dest_address("127.0.0.1", 42424)
	var rogue_packet := packet.duplicate()
	rogue_packet.throttle = 0.0
	rogue_packet.session = "second-phone-session"
	rogue.put_packet(JSON.stringify(rogue_packet).to_utf8_buffer())
	for i in range(8):
		await process_frame
	check(sim.phone.session == "test-phone-session", "A second phone cannot hijack an active session")
	await send({"throttle": 0.58, "pitch": 0, "yaw": 0, "roll": 0, "action": "camera", "action_id": 4})
	check(sim.fpv and reply.action_ack == 4, "Camera command is applied and acknowledged")
	await send()
	check(sim.fpv, "Retransmitted action is applied exactly once")
	await create_timer(0.65, true).timeout
	check(not sim.phone.connected and paused and not sim.drone.armed, "500 ms signal timeout pauses physics and disarms")
	check(sim.drone.remote_throttle == 0.0 and sim.drone.remote_stick == Vector3.ZERO, "Signal timeout clears all controls")
	await send({"throttle": 0.58})
	check(not sim.phone.connected, "Reconnect with stale high throttle is rejected")
	await send({"throttle": 0.0, "action": "resume", "action_id": 5})
	check(sim.phone.connected and paused and not sim.drone.armed, "Neutral reconnect requires deliberate resume and re-arm")
	check(sim.fpv, "Reconnect does not replay an acknowledged camera command")
	check(paused and reply.action_ack == 5, "An in-flight resume command cannot auto-resume on reconnect")
	await send({"action": "resume", "action_id": 6})
	check(not paused, "A fresh explicit resume command works after reconnect")
	await send({"action": "reset", "action_id": 7})
	check(not sim.drone.armed and sim.next_gate == 0, "Remote reset restores safe flight state")
	sim.phone.use_keyboard()
	check(not sim.phone.enabled and not sim.drone.remote_active and not sim.phone.connected, "Keyboard handover releases remote ownership")
	client.close()
	rogue.close()
	print("PHONE TESTS: ", "ALL PASSED" if failures == 0 else str(failures) + " FAILED")
	sim.audio.stop()
	sim.playback = null
	paused = false
	await create_timer(0.05).timeout
	quit(0 if failures == 0 else 1)
