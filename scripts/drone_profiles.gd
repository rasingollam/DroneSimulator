extends RefCounted
## Representative open-prop builds. Inertia, thrust, drag and time constants are
## engineering estimates; dimensions/mass are guided by cited hardware examples.
const DATA := {
	2: {"name": "MICRO 2", "role": "Lightweight backyard micro", "mass": 0.060, "wheelbase": 0.095,
		"inertia": Vector3(0.000019, 0.000034, 0.000021), "thrust": 0.80, "tau": 0.018,
		"yaw_k": 0.0055, "drag": Vector3(0.0015, 0.0038, 0.0018), "cells": 2, "capacity": 420,
		"motor": "1002 / 15500 KV", "kv": 15500, "blades": 2, "color": Color("eead58"),
		"description": "Low momentum; most sensitive to gusts. Small gaps and gentle practice.", "body_height": 0.022,
		"battery_size": Vector3(0.016, 0.014, 0.048)},
	3: {"name": "SCOUT 3", "role": "Light freestyle", "mass": 0.125, "wheelbase": 0.143,
		"inertia": Vector3(0.00010, 0.000175, 0.000115), "thrust": 1.70, "tau": 0.025,
		"yaw_k": 0.008, "drag": Vector3(0.0027, 0.0065, 0.0031), "cells": 3, "capacity": 550,
		"motor": "1104 / 4300 KV", "kv": 4300, "blades": 3, "color": Color("75cfbd"),
		"description": "Compact, light and responsive. A middle step up from the micro.", "body_height": 0.028,
		"battery_size": Vector3(0.028, 0.021, 0.060)},
	4: {"name": "RANGE 4", "role": "Light explorer", "mass": 0.229, "wheelbase": 0.186,
		"inertia": Vector3(0.00031, 0.00055, 0.00036), "thrust": 3.10, "tau": 0.035,
		"yaw_k": 0.0105, "drag": Vector3(0.0042, 0.010, 0.0050), "cells": 4, "capacity": 750,
		"motor": "1404 / 2750 KV", "kv": 2750, "blades": 2, "color": Color("7aaed7"),
		"description": "Efficient cruising build. More carry and momentum than the micros.", "body_height": 0.032,
		"battery_size": Vector3(0.032, 0.026, 0.056)},
	5: {"name": "APEX 5", "role": "Full-size freestyle", "mass": 0.652, "wheelbase": 0.245,
		"inertia": Vector3(0.0017, 0.0030, 0.0019), "thrust": 12.50, "tau": 0.045,
		"yaw_k": 0.014, "drag": Vector3(0.013, 0.024, 0.016), "cells": 6, "capacity": 1400,
		"motor": "2207 / 1800 KV", "kv": 1800, "blades": 3, "color": Color("d68c77"),
		"description": "Highest punch and momentum. More room needed to recover and brake.", "body_height": 0.045,
		"battery_size": Vector3(0.036, 0.038, 0.075)}
}

static func get_profile(inches: int) -> Dictionary:
	return DATA.get(inches, DATA[5]).duplicate(true)

static func hover(inches: int) -> float:
	var p := get_profile(inches)
	return sqrt(p.mass * 9.80665 / (4.0 * p.thrust))
