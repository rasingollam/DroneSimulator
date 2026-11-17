# Changelog

## 1.3.0 — Connected world, pilot training and link recovery

- Expanded the landscape to 2.4 × 2.4 km, with a 1.1 km flight radius and six connected districts: airfield, rural meadow, pine woodland, freight yard, quarry and lakeside bridge.
- Added nine activities, including hover/landing lessons, progressively tighter circuits and a cross-country route; F5 opens the activity selector and world overview.
- Added persistent personal bests, lesson completions, medal targets, airborne time, distance and impacts. Results are separated by activity, airframe, control mode and wind condition.
- Integrated CC0 scanned rocks, a modular brick factory facade kit, crates and drums, plus PBR concrete, timber, corrugated metal, gravel and forest-floor materials. Added source checksums and a reproducible download helper.
- Refined shoreline geometry, water rendering, tree placement and district surfaces; shared geometry/materials, cached collision hulls, instanced factory modules and distance culling limit rendering cost.
- Fixed ground wobble using small-frame contact tolerances and solid central/pad collision surfaces; zero-throttle motors no longer fight the floor.
- Matched runway/apron collisions to their visible surfaces and thinned painted markings so small drone arms remain visible. Improved chase framing while preserving the original FPV camera.
- Added surface-relative height telemetry, water-contact failure handling, activity-scaled navigation and lesson HUD feedback.
- Expanded automated checks for district collision, flyable gate apertures, lesson scoring, record persistence and stable launch pads; refreshed documentation and screenshot galleries.
- Fixed frequent phone re-arming after brief packet/telemetry gaps: physics holds after 350 ms and recovers within a two-second grace period without restoring an intentionally paused session. Sustained loss still disarms and requires explicit resume/re-arm.
- Android controller 1.3 preserves stick state through short stalls, retries transient socket errors, rejects damaged/stale telemetry and requests a safe disconnect on sustained one-way telemetry loss. Added foreground Wi-Fi latency locks and exact-sender fault-injection/end-to-end tests.
- Added real Android emulator screenshots of pairing, connected controls and a live isolated simulator session.

Update the PC simulator and install controller 1.3 for the link-recovery fix. The APK updates the existing package in place with the same signing key.

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
