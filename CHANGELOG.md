# Changelog

## 1.2.0 — Airframes and environment

- Four selectable, physically dimensioned 2/3/4/5-inch builds with individual mass, inertia, thrust, drag, motor response, collision envelopes and controller torque scaling.
- Airframe comparison/rotating model preview (F4), quick number-key selection and per-airframe session best laps.
- Android 1.2 airframe selection and selected-profile hover telemetry; existing haptics retained.
- CC0 photographed terrain/asphalt/bark/pine textures, HDR sky, shared tree/grass meshes, smooth terrain and a detailed flyable hangar/interior with service props.
- Forward+ lighting, MSAA, ambient occlusion and OpenGL fallback launcher; minimal HUD/live sticks retained.
- Bounded ground-effect/rotor-plane-drag approximations; recent-speed contact handling for CCD impacts.
- Per-profile physics and switching checks; isolated UDP test ports avoid interfering with a running game.

Profile coefficients remain engineering estimates, not validated aircraft replicas. Physical Android validation remains pending.

## 1.1.0 — Initial public release

- Godot outdoor practice field with a force-driven quadcopter, four motor models, wind, drag, collisions, Angle mode and Acro mode.
- Keyboard Mode 2 controls and an Android dual-stick controller with local UDP pairing, telemetry and disconnect handling.
- Android controller 1.1 with optional pickup, neutral and limit haptic cues.
- Full-screen PC view, minimal/instrument/hidden HUD modes, FPV/chase cameras and translucent bottom-center stick indicators.
- Sequential training gates, lap timing, reset, automated physics/control/network checks and installation documentation.

The physics model uses approximate coefficients. Android installation, rendering, multitouch performance and haptic feel still require physical-device validation.
