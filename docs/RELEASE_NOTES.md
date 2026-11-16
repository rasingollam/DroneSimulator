# Vector Flight Lab v1.1.0

Initial public release of the Godot simulator and Android touch controller.

- Force-driven quadcopter with four motors, Angle/Acro modes, wind and collisions.
- Full-screen field with training gates, lap timing, FPV/chase cameras and live stick indicators.
- Android controller 1.1: two sticks, persistent throttle, telemetry and optional haptic cues.
- Local pairing, lost-link pause/disarm, neutral reconnect and acknowledged commands.

## Install

Download **VectorController.apk** onto an Android 6.0+ phone and install it. This is the controller only. Clone/download the repository and import `project.godot` in Godot 4.5.1 to run the PC simulator.

Use the same private LAN. Press **F2** on the PC, enter its address/code in the app, then tap **Start / Resume** and **Arm**. See **INSTALL.md** and the repository README. The APK SHA-256 checksum is supplied alongside the download.

This is a locally signed development APK. Builds signed by another key require uninstalling the installed app first.

## Validation and limitations

Physics, keyboard input, UDP handling, control math, haptic detection, transfer and Java/Godot communication have automated checks. APK package/signatures were verified. Android installation, rendering, multitouch and haptic feel have not yet been validated on a physical device or emulator.

Aircraft coefficients are approximate. Use a trusted private LAN; control traffic is not encrypted. This software does not operate real drones.
