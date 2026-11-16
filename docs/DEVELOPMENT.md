# Development

## Prerequisites

- Standard Godot **4.5.1**, the validated baseline; no .NET runtime is needed.
- Python 3 for checks and optional APK transfer.
- JDK 17 for Java tests and Android builds.
- APK builds: Windows, SDK platform 35 and build-tools 35.0.1, installed with Google's [SDK tools](https://developer.android.com/tools/sdkmanager) or Android Studio. This native Java app needs no Godot Android templates, Gradle or NDK.

Keep downloaded engines, SDKs and keys outside source control. The ignored `tools/` directory is an optional local tool location. Add `tools/.gdignore` if you use it so Godot skips scanning its contents.

## Checks

```bash
python tests/run_checks.py --godot /path/to/godot --java-home /path/to/jdk-17
```

The runner accepts `GODOT_BIN` and `JAVA_HOME`, searches PATH, and recognizes the optional local workspace tool layout. Godot tests run sequentially because the simulator binds UDP 42424. Close other simulator windows first. Local UDP/HTTP networking must be allowed.

Individual checks:

```bash
godot --headless --path . --script tests/physics_test.gd
godot --headless --path . --script tests/integration_test.gd
godot --headless --path . --script tests/phone_test.gd
python tests/transfer_test.py
godot --path . --script tests/visual_capture.gd
```

The capture script briefly runs the full-screen scene and saves ignored screenshots under `tests/`. Review the guide, pairing, chase and FPV views. Do not publish active pairing codes or private network details.

`tests/controller_host.gd` and `android-controller/tests/ControllerLinkTest.java` provide an additional sender-to-Godot harness. It uses the APK sender source with a desktop monotonic-clock substitute and desktop `org.json` implementation. Start the host, then run the compiled Java harness with `tools/controller_host.json` and `tools/controller_test.done` arguments. The default suite tests the real receiver with UDP without this additional JSON dependency.

The Java tests do not execute the Android activity or vibration motor. APK package/signature checks and desktop tests do not replace physical-device installation, rendering, multitouch and haptic validation; those remain pending.

## Android build

```powershell
.\android-controller\build.ps1 -Jdk 'C:\path\to\jdk-17' -Sdk 'C:\path\to\android-sdk'
```

The script runs javac, aapt2, D8, zipalign and apksigner, verifies signatures/package metadata and writes `dist/VectorController.apk` plus its SHA-256 checksum. Test sources are excluded from the APK. The app uses only Android platform APIs.

A local development key is created at ignored `tools/android/controller-local.jks` if absent. The conventional development-only password is `android`; this is not a production signing workflow. Keep the key private and retain it for updates. A fork's different key cannot update the distributed APK without uninstalling it first. Production distribution should use a protected keystore and signing workflow.

## Architecture

| Source | Responsibility |
| --- | --- |
| `scripts/drone.gd` | Motor dynamics, rigid body and PID/mixer |
| `scripts/training_world.gd` | Procedural field, terrain and colliders |
| `scripts/main.gd` | Input, cameras, wind, gates and audio |
| `scripts/hud.gd` | Instruments, live sticks, guide and pairing screen |
| `scripts/phone_receiver.gd` | UDP validation, sessions, commands and failsafe |
| `ControlState.java` | Touch math, throttle persistence and response curve |
| `ControllerLink.java` | Android sender, telemetry, retries and timeout |
| `HapticCues.java` / `StickHaptics.java` | Cue detection and Android feedback |
| `MainActivity.java` | Native UI and multitouch routing |

Use SI units in physics code. Preserve explicit state changes, neutral/zero-throttle handshake, and the rule that stale or retransmitted commands cannot automatically resume after lost link.
