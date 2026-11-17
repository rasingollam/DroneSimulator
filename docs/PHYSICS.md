# Physics model

Each airframe is a Godot `RigidBody3D`. Translation/rotation result from forces, gravity and contacts, not scripted flight movement. Motor forces are applied in `_integrate_forces()` at **240 physics ticks per second**. [Godot rigid-body documentation](https://docs.godotengine.org/en/4.5/tutorials/physics/rigid_body.html).

## Per-airframe parameters

The authoritative values are in `scripts/drone_profiles.gd`. See [DRONE_PROFILES.md](DRONE_PROFILES.md) for the hardware references and which parameters are estimated.

| Profile | Mass kg | Inertia X/Y/Z kg·m² | Diagonal m | Thrust/motor N | Spool s | Reaction torque/thrust m |
| --- | --- | --- | --- | --- | --- | --- |
| 2-inch | 0.060 | 0.000019 / 0.000034 / 0.000021 | 0.095 | 0.80 | 0.018 | 0.0055 |
| 3-inch | 0.125 | 0.00010 / 0.000175 / 0.000115 | 0.143 | 1.70 | 0.025 | 0.0080 |
| 4-inch | 0.229 | 0.00031 / 0.00055 / 0.00036 | 0.186 | 3.10 | 0.035 | 0.0105 |
| 5-inch | 0.652 | 0.0017 / 0.0030 / 0.0019 | 0.245 | 12.50 | 0.045 | 0.0140 |

Mass includes an assumed pack. Center-of-mass height is an estimate above the carbon frame. The frame and battery have separate simplified box colliders; individual blades do not collide. Inertias are positive and satisfy the rigid-body principal-inertia triangle inequalities.

## Motor and control dynamics

Four normalized rotor speeds approach targets with first-order time constants. Each produces `T = Tmax * speed²` at its own location, along body up. Counter-rotating diagonals produce opposite reaction torques. Collective command is quadratic in throttle.

A body-rate controller computes body torque, using estimated inertia to scale proportional, integral and filtered derivative terms. The mixer translates collective and torque into motor targets, saturating each at physical limits. Integral bounds and ground/low-throttle reset reduce windup.

All profiles share 4.2 rad/s pitch/roll and 2.8 rad/s yaw rate limits for fair comparisons. Angle mode adds a geometric leveling loop with up to 30° bank/pitch. Acro release stops rotation but retains tilt. Neither mode holds altitude or position.

Hover power is `sqrt(m*g/(4*Tmax))` in free air, using gravity **9.80665 m/s²**. H sets this power once; it does not cancel existing vertical velocity. The selected profile's hover value is also sent to the phone.

## Aerodynamics and ground

Body-coordinate air-relative speed drives `-0.5 * density * drag_area * velocity * abs(velocity)` with density **1.225 kg/m³** and profile-specific effective areas. Effective linear rotor-plane drag scales with current thrust. Small quadratic rotational drag scales with inertia. These are low-order engineering approximations, not a blade-element solver.

Wind/gusts alter relative air velocity. A downward ray measures nearby ground when the aircraft is near level. A bounded classical rotor/ground lift-factor approximation increases lift by at most **15%** at very low clearance. It does not model propwash or vortex-ring behavior. Geometry/terrain contacts, friction and restitution remain engine-driven; continuous collision detection reduces tunneling.

The crash cutoff uses contact plus speed above **3.8 m/s** within the preceding **33 ms**. The short history handles CCD stopping a body before the engine reports contact. This is a training reset threshold, not structural stress analysis. Reset clears motor state, velocities and controller history, and returns disarmed to the pad.

Height telemetry estimates clearance above the collision surface below using a downward ray updated at 10 Hz, including raised pads and structures. It is a geometric estimate, not a simulated radar sensor. The environmental grass/foliage animation is decorative; air forces use the simulator's explicit wind vector. Contact with the lake surface is treated as a failed flight, with motor cutoff; buoyancy and underwater dynamics are not modeled.

## Limits

Detailed blade aerodynamics, propwash, vortex-ring state, battery discharge/sag, flexible frames, ESC internals, radio latency and structural damage are omitted. Pack cell count/capacity and motor KV describe the representative configuration; they do not independently generate a measured power curve. Thrust, drag, inertia and motor response are estimated, not fitted to real flight logs.

The automated tests establish force balance, stable control, directionality, mode behavior, switching and collision handling for each profile. They do not establish real-flight accuracy. A physical radio and calibration against measured hardware/logs are required for close transfer to a particular aircraft.
