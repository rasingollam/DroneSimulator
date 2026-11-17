extends RefCounted
## Positions are metres in the shared world. Every activity remains freely selectable.
const ZONES := [Vector3.ZERO, Vector3(-350, 0, 250), Vector3(-350, 0, -330), Vector3(350, 0, 200), Vector3(350, 0, -350), Vector3(-100, 0, 600)]
const ACTIVITIES := [
	{"id": "airfield", "name": "Airfield circuit", "level": "FOUNDATION", "zone": 0, "kind": "race", "tip": "Cross the teal gate in order. Start and finish at gate 01.", "spawn": Vector3(0, 0.18, 9), "size": Vector2(3.2, 2.2), "gold": 32.0, "silver": 50.0,
	"route": [Vector3(0,3,-18),Vector3(0,4,-48),Vector3(22,5,-74),Vector3(48,4,-60),Vector3(54,3,-26),Vector3(34,3,0),Vector3(10,2.8,12)]},
	{"id": "hover", "name": "Hover box", "level": "LESSON 01", "zone": 1, "kind": "hover", "tip": "Hold inside the 3 m-high box at under 0.7 m/s for 10 continuous seconds.", "spawn": Vector3(-350,0.18,285), "target": Vector3(-350,3,275), "size": Vector2(3,2), "route": []},
	{"id": "landing", "name": "Precision landing", "level": "LESSON 02", "zone": 1, "kind": "landing", "tip": "Take off above 1.5 m, fly to the marked pad, then settle gently for 1 second.", "spawn": Vector3(-350,0.18,285), "target": Vector3(-335,0.10,265), "size": Vector2(3,2), "route": []},
	{"id": "meadow", "name": "Meadow figure eight", "level": "BEGINNER", "zone": 1, "kind": "race", "tip": "Smooth coordinated turns. Keep height through the crossover.", "spawn": Vector3(-350,0.18,285), "size": Vector2(3.5,2.5), "gold": 38.0, "silver": 60.0,
	"route": [Vector3(-350,4,270),Vector3(-375,4,250),Vector3(-370,5,225),Vector3(-345,4,240),Vector3(-320,5,260),Vector3(-325,4,285)]},
	{"id": "forest", "name": "Pine slalom", "level": "INTERMEDIATE", "zone": 2, "kind": "race", "tip": "Read the next gap early. Thread the trunks without cutting the turn.", "spawn": Vector3(-350,0.18,-280), "size": Vector2(2.0,1.6), "gold": 27.0, "silver": 45.0,
	"route": [Vector3(-350,3,-295),Vector3(-362,3,-315),Vector3(-340,4,-335),Vector3(-362,3,-355),Vector3(-340,5,-375),Vector3(-318,5,-345),Vector3(-322,4,-305)]},
	{"id": "industrial", "name": "Freight yard technical", "level": "ADVANCED", "zone": 3, "kind": "race", "tip": "Low container gaps, a warehouse pass and an elevated gantry.", "spawn": Vector3(350,0.18,255), "size": Vector2(1.8,1.4), "gold": 32.0, "silver": 55.0,
	"route": [Vector3(350,3,240),Vector3(350,3,215),Vector3(370,4,195),Vector3(350,7,175),Vector3(330,3,195),Vector3(325,3,230)]},
	{"id": "quarry", "name": "Quarry elevation run", "level": "ADVANCED", "zone": 4, "kind": "race", "tip": "Climb the tower, descend through the tilted gate, then recover smoothly.", "spawn": Vector3(350,0.18,-295), "size": Vector2(2.8,2.2), "gold": 38.0, "silver": 65.0,
	"route": [Vector3(350,5,-310),Vector3(370,17,-330),Vector3(350,28,-355),Vector3(330,10,-375),Vector3(315,4,-345),Vector3(325,5,-315)]},
	{"id": "bridge", "name": "Lakeside bridge run", "level": "INTERMEDIATE", "zone": 5, "kind": "race", "tip": "Fly beneath the bridge deck over water. Keep a positive recovery margin.", "spawn": Vector3(-100,0.18,650), "size": Vector2(2.6,1.5), "gold": 46.0, "silver": 75.0,
	"route": [Vector3(-100,4,630),Vector3(-60,3,600),Vector3(10,2,600),Vector3(70,2,600),Vector3(110,7,575),Vector3(20,10,560),Vector3(-80,6,585)]},
	{"id": "explorer", "name": "Cross-country explorer", "level": "ENDURANCE", "zone": 0, "kind": "race", "tip": "A kilometre-scale tour. Use the map and height changes to plan ahead.", "spawn": Vector3(0,0.18,9), "size": Vector2(7,5), "gold": 160.0, "silver": 260.0,
	"route": [Vector3(0,15,-50),Vector3(-240,45,-230),Vector3(-350,18,-330),Vector3(150,65,-370),Vector3(350,35,-350),Vector3(350,30,200),Vector3(0,55,500),Vector3(-100,20,600),Vector3(-350,25,250),Vector3(-100,25,50)]}
]

static func activity(index: int) -> Dictionary:
	return ACTIVITIES[clampi(index, 0, ACTIVITIES.size() - 1)].duplicate(true)

static func medal(activity_data: Dictionary, seconds: float) -> String:
	if seconds <= 0:
		return "--"
	if seconds <= float(activity_data.gold):
		return "GOLD"
	if seconds <= float(activity_data.silver):
		return "SILVER"
	return "BRONZE"
