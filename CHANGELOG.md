# Changelog

## Unreleased — World explorer

- Raised Angle mode from its implicit 30° single-axis limit to 80° per axis, with direct stick-to-angle mapping and heading-referenced self-leveling. Corrected coupled body-rate mapping for simultaneous steep pitch and roll. Acro rates retain their existing values.
- Set the default FPV camera tilt to 30° upward; bracket-key adjustment remains available.

- Added nine more launch sites (eighteen total), with a two-page F6 world selector.
- Added coastal cliffs/coves/sea stacks/cave/lighthouse, rice terraces and irrigation, braided rivers and gravel islands, alpine bowl/spires, landslide debris, a branching mine, a dam/hydro station, quarry conveyors and switchback track.
- Added lake islands, docks, boathouses, drowned ruins, hidden waterfall camp, forest cabin, expedition wreck, timber crossings, avalanche gallery, lookout towers and animated cable cars.
- Added six optional scenic trails (G), personal flight recording (Y), saved-flight ghost playback across airframes (P), optional landing markers (O), persistent discoveries and settled landing records.
- Added summer/autumn/winter scenery (F10), moving cloud shadows, a rotating lighthouse light and generated spatial water/bird ambience. M and pause apply to ambience.
- Batched stationary visual geometry while retaining collision, instanced crops and track details, and checked calm water/shoreline joins, cave clearances and cable/terrain clearance.
- Added exploration/replay tests and scenery captures, plus the exploration guide.


- Expanded the terrain to 8 × 8 km with a 3.8 km radial flight boundary and nine scenic free-roam launch sites (F6).
- Added river valleys, two waterfalls, alpine lakes, pine forests, a rock arch, hollow cave/tunnel, cliff road, stone bridge, rail viaduct, campsites, cabin, abandoned village and summit.
- Added morning/golden-hour/mist lighting (F7), High/Performance effects (F8) and optional home marker (F9).
- Rebuilt chunk edges with identical five-metre boundary vertices across every detail level; CPU workers stream nearby ground detail and matching collision.
- Smoothed excessive high-frequency mountain warping, faded valley endpoints, connected bridge/rail approaches, graded roads and cut open portals after grading. Water extends into terrain to meet the actual shoreline.
- Added CC0 cliff, scree and snow materials, triplanar cliff mapping, reduced texture repetition and sunset HDR lighting, with checksum provenance.
- Prevented stale water-contact checks during a pending physics reset, so recovery reaches the new launch point cleanly.
- Added terrain manifold/seam tests, launch/portal collision checks and native scenery captures. The existing Android 1.3 controller remains compatible.

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
