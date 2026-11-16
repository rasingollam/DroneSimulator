# Physics model

The aircraft is a Godot `RigidBody3D`. Translation and rotation come from forces, gravity and contact response, not scripted flight movement. The controller adjusts motor forces in `_integrate_forces()` at **240 physics ticks per second**. See [Godot's rigid-body documentation](https://docs.godotengine.org/en/4.5/tutorials/physics/rigid_body.html).

| Quantity | Value |
| --- | --- |
| Mass | 0.80 kg |
| Diagonal inertia | (0.005, 0.009, 0.005) kg·m² |
| Motor offsets | ±0.165 m in body X/Z |
| Diagonal motor spacing | 0.467 m, 450-class frame |
| Visual propeller diameter | 0.229 m, approximately 9 inches |
| Maximum thrust | 6.5 N per motor |
| Motor time constant | 0.045 s |
| Reaction torque / thrust | 0.018 m |
| Gravity | 9.80665 m/s² |
| Air density | 1.225 kg/m³ |
| Effective drag areas X/Y/Z | (0.035, 0.075, 0.035) m² |

## Forces and control

Four normalized motor speeds approach their targets using first-order dynamics. Each produces `thrust = maximum_thrust * speed²` along body up at its own position. Counter-rotating diagonal pairs contribute opposite reaction torques.

A body-rate PID controller computes desired torque. Mixing combines collective power, pitch/roll torque and yaw reaction torque; outputs saturate to motor limits. Integral bounds and ground/low-throttle reset reduce windup; derivative filtering reduces noise.

Angle mode adds a geometric leveling loop and commands up to 30° bank/pitch. Acro commands up to 4.2 rad/s pitch/roll and 2.8 rad/s yaw. Releasing an Acro stick stops rotation while retaining tilt. Neither mode holds altitude or position.

Quadratic drag uses body-coordinate air-relative velocity and axis-dependent effective areas. Small quadratic rotational drag is also applied. Wind changes relative air velocity. Godot calculates gravity, friction and restitution; continuous collision detection reduces tunneling.

The H shortcut sets power once:

```text
hover_throttle = sqrt(mass * gravity / (4 * maximum_motor_thrust)) ≈ 0.55
```

This balances weight only when level at nominal parameters. It does not cancel existing vertical velocity or compensate for banking.

## Contacts and limits

The collider is a simplified frame envelope, not individual propeller blades. Contact after pre-contact speed above 3.8 m/s triggers a crash and disarms. This is a simple threshold, not structural stress analysis. Reset returns to the landing pad, disarmed. Leaving the field boundary also returns the aircraft to the pad.

Height is relative to the flat field datum, not radar altitude above terrain or obstacles. Camera tracking and HUD indicators do not affect aircraft dynamics.

Coefficients are engineering approximations. Detailed blade aerodynamics, propwash, vortex-ring state, ground effect, battery sag, flexible frames, ESC internals, radio latency and structural damage are omitted. The procedural world is not photorealistic.

For closer transfer to real flight, measure mass, inertia, thrust/torque curves and drag, then tune rates and controller gains against real flight logs. Physical-radio/gamepad input would improve precision and muscle-memory transfer. The simulator does not establish real-world flight proficiency.
