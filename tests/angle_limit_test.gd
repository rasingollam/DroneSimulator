extends SceneTree
const Drone=preload("res://scripts/drone.gd")
var failures:=0
var craft: RigidBody3D
func _initialize() -> void: call_deferred("run")
func check(value: bool,label: String) -> void:
 print("PASS: " if value else "FAIL: ",label)
 if not value: failures+=1
func steps(count: int) -> void:
 for i in range(count): await physics_frame
func start(inches: int,command: Vector3) -> void:
 if is_instance_valid(craft):
  craft.queue_free()
  await process_frame
 craft=RigidBody3D.new()
 craft.set_script(Drone)
 craft.inches=inches
 craft.spawn_transform.origin=Vector3(0,500,0)
 root.add_child(craft)
 craft.test_input=true
 await steps(3)
 craft.set_armed(true)
 craft.throttle=0.75
 craft.test_stick=command
func run() -> void:
 for inches in [2,3,4,5]:
  for command in [Vector3(-1,0,0),Vector3(1,0,0),Vector3(0,0,-1),Vector3(0,0,1),Vector3(-0.5,0,0),Vector3(0,0,0.5)]:
   await start(inches,command)
   await steps(600)
   var actual: Vector3=craft.global_basis.get_euler(EULER_ORDER_YXZ)*180/PI
   var expected: Vector3=command*80
   check(absf(actual.x-expected.x)<1 and absf(actual.z-expected.z)<1,"%d-inch stick %s settles at pitch %.1f / roll %.1f degrees" % [inches,command,actual.x,actual.z])
  craft.test_stick=Vector3.ZERO
  await steps(480)
  check(craft.global_basis.y.dot(Vector3.UP)>0.999 and craft.angular_velocity.length()<0.08,"%d-inch releases back to level" % inches)
 await start(5,Vector3(-1,0,-1))
 await steps(720)
 var angles: Vector3=craft.global_basis.get_euler(EULER_ORDER_YXZ)*180/PI
 check(absf(angles.x+80)<1 and absf(angles.z+80)<1,"Combined pitch/roll commands retain their individual 80-degree limits")
 craft.test_stick=Vector3.ZERO
 await steps(720)
 check(craft.global_basis.y.dot(Vector3.UP)>0.999 and craft.angular_velocity.length()<0.08,"Combined steep tilt releases back to level without a sustained spin")
 await start(5,Vector3(0,-0.3,-0.75))
 await steps(720)
 var turning: Vector3=craft.global_basis.get_euler(EULER_ORDER_YXZ)*180/PI
 check(absf(turning.x)<1 and absf(turning.z+60)<1 and craft.angular_velocity.y< -0.5,"Banked Angle-mode yaw retains the commanded pitch and roll")
 craft.queue_free()
 await process_frame
 print("ANGLE LIMIT TESTS: ","ALL PASSED" if failures==0 else str(failures)+" FAILED")
 quit(0 if failures==0 else 1)
