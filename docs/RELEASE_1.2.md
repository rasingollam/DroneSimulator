# Vector Flight Lab v1.2.0 — Airframes and environment

Choose a representative **2-, 3-, 4- or 5-inch open-prop drone** and compare its handling in an upgraded training field.

- Each profile has its own physical mass, inertia, motor locations, thrust limits, reaction torque, drag, spool response, center-of-mass estimate and frame/battery colliders. Stick rates are shared for fair comparison.
- **F4** opens airframe comparison and a rotating model preview. **2 / 3 / 4 / 5** selects while disarmed; **Enter** returns to the field. Switching resets the aircraft and circuit and never arms it. Session lap bests are separated by airframe.
- **Android controller 1.2** adds an AIRFRAME button, selected-airframe telemetry and an accurate profile HOVER label. Haptics remain available. Existing phone builds still control the PC; use the PC keyboard to change size with those builds.
- The world now uses CC0 photographed grass, soil, asphalt, bark and pine needle textures, a captured HDR sky, instanced foliage/grass, smooth terrain and a detailed flyable hangar with interior/service props.
- Forward+ lighting, MSAA, mipmapped/anisotropic textures and ambient occlusion improve rendering. **Launch-low-graphics.cmd** offers an OpenGL fallback. The clear HUD and live stick indicators remain.

## Install

Update the PC source/project and run with Godot 4.5.1+. Install **VectorController.apk** over the previous app to use phone-side airframe selection. It is signed by the same development key. The APK is the controller only, not the PC simulator.

Use the same private LAN; F2 on PC shows its address/code. Select an airframe while disarmed, tap Start/Resume and Arm, then raise throttle above the displayed HOVER value. The default 5-inch build hovers at about 36%, not the old 55%. The 2/3/4-inch profiles hover around 42–43% in free air.

## Validation and limits

The full local suite passed: baseline and per-profile physics, Angle/Acro response, wind, reset, UI switching, keyboard input, real UDP control/selection/failsafe, Java control/haptic detection, checksum and APK transfer. APK signatures/package were checked. Full-screen visuals were reviewed at 1920×1080 on a GTX 1050 Ti, including all four model previews.

The profiles are **engineering approximations informed by published hardware**, not validated replicas. Inertia, thrust, drag and motor-response values remain estimates. Battery discharge/sag, propwash and detailed blade aerodynamics are not modeled. See docs/DRONE_PROFILES.md for sources and assumptions. Physical Android installation, multitouch/haptic feel and latency still need device validation. Control traffic is unencrypted and intended for a trusted private LAN.
