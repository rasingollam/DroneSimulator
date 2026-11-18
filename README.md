# Vector Flight Lab

**A physics-based drone simulator in Godot, with an Android phone as your touch radio.**

[![Checks](https://github.com/rasingollam/DroneSimulator/actions/workflows/checks.yml/badge.svg)](https://github.com/rasingollam/DroneSimulator/actions/workflows/checks.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Godot 4.5.1](https://img.shields.io/badge/Godot-4.5.1-478cbf)](https://godotengine.org/)

Practice throttle, yaw, pitch and roll across six training districts and a mountain wilderness in one connected landscape. Fly with the keyboard or use two simultaneous touch sticks on your Android phone while watching the PC screen.

**[Get the Android remote](https://github.com/rasingollam/DroneSimulator/releases/latest/download/VectorController.apk)** · [Training guide](docs/TRAINING.md) · [Physics and realism](docs/PHYSICS.md) · [Asset credits](THIRD_PARTY_NOTICES.md)

![Full-screen flight view with translucent live stick indicators](docs/images/training-field.png)

> **Project status:** working practice prototype. The aircraft uses engineering approximations, not measured parameters from a particular real drone. This is not a validated digital twin. Android installation, rendering, multitouch performance and haptic feel still need physical-device validation.

## Features

- Selectable **2-, 3-, 4- and 5-inch open-prop drones**, each with its own mass, inertia, thrust, drag, collision dimensions and motor response.
- Four independent motors applying thrust and reaction torque to a rigid body at 240 physics ticks per second.
- Motor spool response, quadratic drag, gravity, wind/gusts, contacts and impact-triggered motor cutoff.
- **Angle** self-leveling and **Acro** body-rate modes, with FPV and chase cameras.
- Textured field, HDR sky/reflections, wind-animated grass and pine foliage, smooth highlands, a flyable curved-roof hangar, service buildings and training obstacles. Environment photographs are CC0 assets from Poly Haven; see [credits](THIRD_PARTY_NOTICES.md).
- **8 × 8 km landscape** with a 3.8 km flight radius, six training districts and eighteen scenic launch points. Fly river valleys, two cascades, alpine lakes, pine forests, a natural arch, a cave, road tunnel, cliff road, stone bridge and railway viaduct.
- Free roaming without checkpoints or a race clock; campsites, a lakeside cabin, abandoned village and snowy summit. Morning, golden-hour and mist presets, optional home marker and High/Performance graphics modes.
- Continuous terrain edges across streamed detail levels, matching ground collision, broad natural slopes, triplanar rock textures and height/slope blended scree and snow.
- Nine training activities: hover/landing lessons, technical circuits and a cross-country route.
- Scanned rock meshes, detailed factory facade modules, crates and drums; concrete, metal, timber, gravel and forest-floor PBR materials. Assets are bundled for offline use.
- Saved personal bests, lesson completions, medal targets, airborne time, distance and impact count. Records are separated by activity, airframe, flight mode and wind.
- Full-screen view with minimal, instrument and hidden HUD modes; translucent bottom-center stick indicators.
- Lightweight **Android controller** with persistent throttle, two-finger input, telemetry and a round-trip delay display.
- Optional haptic cues for stick pickup, neutral crossings and travel limits.
- Local Wi-Fi pairing, acknowledged commands, stale-packet rejection and lost-link pause/disarm.

## Run the simulator

Install the **standard Godot 4.5.1 editor** or a compatible later Godot 4 release. No C#, addons, external art downloads or paid dependencies are needed. The verified baseline is Godot 4.5.1 on Windows; other platforms have not been validated.

```bash
git clone https://github.com/rasingollam/DroneSimulator.git
cd DroneSimulator
```

Import **`project.godot`** into Godot and press **F5**. If Godot is on your PATH, you can instead run:

```bash
godot --path .
```

On Windows, `Launch.cmd` uses `godot` on PATH, or an optionally supplied portable engine in `tools/`. **Engine binaries, Android SDKs and signing keys are not included in the repository.**

The simulator opens full screen, disarmed, with a clear view. **F1** opens the guide; **F2** opens pairing; **F3** cycles HUD modes; **F4** opens airframe comparison; **F5** opens training; **F6** opens world exploration; **F7** changes lighting; **F8** changes graphics quality; **F9** toggles the home marker; **F11** toggles full screen. The upgraded visuals use Forward+ (Vulkan); `Launch-low-graphics.cmd` or `godot --path . --rendering-method gl_compatibility` provides a reduced-effects OpenGL fallback.

## Explore the world

Press **F6 while disarmed**, choose a launch site with Up/Down or a click, then press Enter. Start at **Lake overlook** and follow the river upstream through the stone bridge and natural arch to the waterfalls, cavern and high lake. Try the western pine saddle, forgotten village, railway ravine and summit for different terrain and lines.

**F7** cycles morning, golden hour and mist. **F8** switches High/Performance effects. **F9** toggles a home marker; **R** returns to your chosen launch pad. Fly freely without compulsory gates. Your total flying time and distance still accumulate. **F5** returns to the training activities.

![River valley and stone bridge](docs/images/mountain-river-valley.png)

<details>
<summary>Explorer menu, cave, waterfall and railway views</summary>

![Mountain launch selector](docs/images/mountain-explorer.png)

| Cave passage | Waterfall |
| --- | --- |
| ![Open-ended cave entrance](docs/images/mountain-cave.png) | ![River cascade](docs/images/mountain-waterfall.png) |

![Railway viaduct across the ravine](docs/images/mountain-viaduct.png)

</details>

| High lake | Mountain panorama |
| --- | --- |
| ![Alpine lake and surrounding slopes](docs/images/mountain-glacial-lake.png) | ![View down the valley from the summit](docs/images/mountain-summit.png) |

| Coastal cliffs and sea stacks | Rice foothills |
| --- | --- |
| ![Coastal exploration region](docs/images/frontier-coast.png) | ![Flooded terraced farmland](docs/images/frontier-terraces.png) |

<details>
<summary>More world expansion screenshots</summary>

![Second page of the eighteen-site explorer](docs/images/frontier-menu.png)

| Alpine bowl | Cableway |
| --- | --- |
| ![Snow bowl and rocky ridges](docs/images/frontier-winter.png) | ![Mountain cableway](docs/images/frontier-cableway.png) |

| Quarry and conveyors | Braided river |
| --- | --- |
| ![Quarry region](docs/images/frontier-quarry.png) | ![Braided river channels](docs/images/frontier-delta.png) |

![Optional scenic trail](docs/images/frontier-trail.png)

</details>

The second F6 page reaches **slot canyons, coastal cliffs and sea stacks, flooded rice terraces, braided rivers, an alpine bowl, landslide terrain, a branching mine, a reservoir dam and a ridge cableway**. There are now eighteen launch points. Explore side gorges, timber crossings, conveyor gaps, an avalanche gallery, ruined houses, boathouses, lookout towers and a dry alcove behind the waterfall.

| Control | Exploration feature |
| --- | --- |
| **G** | Cycle six optional scenic trails, then switch them off |
| **Y** | Start recording; press again to save. Disarming or crashing also ends the run |
| **P** | Show/hide your saved flight ghost; arming starts its clock |
| **O** | Show/hide landing spot markers |
| **F10** | Cycle summer, autumn and winter vegetation/snow |
| **M** | Mute motors and environmental audio |

Find hidden camps, a wreck, mine offices and lakeside ruins. Discoveries and two-second settled landings save across sessions. Moving cloud shadows, animated cable cars, a rotating lighthouse beacon, flowing water and spatial water/bird ambience give the routes life. [Exploration and replay guide](docs/EXPLORATION.md).

The distant landscape is always visible. Nearby terrain detail and physical ground load ahead of the aircraft on a CPU worker, with shared boundary vertices between detail levels. Allow time for the larger world to build at startup. High quality uses Forward+ reflections, ambient occlusion, shadows and mist volumes; actual frame rate depends on the GPU, resolution and view.

## Choose your drone

Press **F4** while disarmed, choose with **2 / 3 / 4 / 5**, and press **Enter** to return. The rotating preview shows the selected physical-size model and its specifications. Switching resets the aircraft and circuit; it never arms automatically. Android controller 1.2 also includes an **AIRFRAME** button.

| Build | Ready-to-fly mass | Pack | Approx. hover | Intended comparison |
| --- | --- | --- | --- | --- |
| 2-inch MICRO | 60 g | 2S 420 mAh | 43% | Light backyard micro |
| 3-inch SCOUT | 125 g | 3S 550 mAh | 42% | Light freestyle |
| 4-inch RANGE | 229 g | 4S 750 mAh | 43% | Light explorer |
| 5-inch APEX | 652 g | 6S 1400 mAh | 36% | Full-size freestyle |

These are representative builds, not brand replicas or a claim that every quad of that size flies the same. [Profile data, sources and estimated parameters](docs/DRONE_PROFILES.md) explain the basis and limits. Shared stick rates allow comparisons without arbitrary sensitivity changes.

![Airframe comparison with a close-up rotating drone model](docs/images/airframe-hangar.png)

## Fly with your Android phone

**[Download the controller APK](https://github.com/rasingollam/DroneSimulator/releases/latest/download/VectorController.apk)** · [Releases](https://github.com/rasingollam/DroneSimulator/releases) · [Installation and troubleshooting](dist/INSTALL.md)

The APK controls the PC simulator; it does not run the 3D world on the phone. Android 6.0+ and a multitouch screen are required.

**Controller 1.3 fixes frequent re-arming after brief signal gaps.** Update the PC simulator and install the new APK over the existing app; the signing key and package are unchanged.

| Pair with your PC | Connected touch radio |
| --- | --- |
| ![Android controller pairing dialog with PC address and code fields](docs/images/mobile-pairing.png) | ![Connected Android remote with dual sticks, haptics and airframe controls](docs/images/mobile-remote.png) |

<details>
<summary>Live mobile-controller screenshot</summary>

![Android remote controlling an actual isolated Godot flight with live throttle and telemetry](docs/images/mobile-live.png)

</details>

These are actual Android 6.0 emulator captures of controller 1.3, paired with an isolated Godot simulator through a test bridge. They demonstrate the app interface and telemetry; physical-phone multitouch and haptic feel still need device validation. [Screenshot capture notes](docs/SCREENSHOTS.md).

1. Install `VectorController.apk` on your phone. Android may ask you to allow installation from your browser or file manager.
2. Connect PC and phone to the **same private local network**. Avoid guest Wi-Fi/client isolation.
3. Start the simulator and press **F2**.
4. In the app, enter the displayed PC IPv4 address and six-digit pairing code.
5. Tap **Start / Resume**, then **Arm**. Gently raise throttle above the **HOVER** value for your selected airframe (about 36% for the default 5-inch build).

| Stick | Vertical | Horizontal | On release |
| --- | --- | --- | --- |
| Left | Throttle | Yaw | Throttle stays; yaw centers |
| Right | Pitch | Roll | Both center |

Movement is relative to where each thumb engages, so touching or re-gripping does not jump throttle. A dead zone and response curve soften center control. PC stick indicators show received commands before aircraft smoothing.

**Haptics:** a short tap confirms pickup, a light tick marks neutral, and a limit bump marks full axis travel or zero/full throttle. Use **HAPTICS ON/OFF** to toggle. Enable Android touch vibration if needed. Strength depends on the phone; vibration affects the whole device, not individual thumbs.

After **350 ms** without valid packets, the PC freezes physics instead of flying on stale controls. A fresh packet from the same paired session within **two seconds** restores an interrupted flight without clearing throttle or re-arming. An intentional pause stays paused, and Escape during a signal hold cancels automatic recovery.

After **two seconds** of sustained loss, the PC disarms and clears controls. Reconnecting then requires neutral sticks and zero throttle, followed by deliberate resume and arming. The app retries transient socket errors and ignores malformed replies; sustained telemetry loss also requests a safe PC disconnect. It requests foreground low-latency Wi-Fi where supported and releases that lock on leaving the app. **K** returns to keyboard control; **F2** enables pairing again.

Allow Godot on **Private networks** if Windows Firewall asks. Control uses **UDP 42424**. No cloud service or router port forwarding is needed. Pairing traffic is **not encrypted**; use a trusted private LAN and read [SECURITY.md](SECURITY.md).

For optional Wi-Fi APK transfer, install Python 3 and run `Install-on-phone.cmd`, or `python android-controller/serve_apk.py`. Open the displayed local address on the phone. The helper uses TCP 8765, serves only the APK and installation page, and should be stopped after transfer. USB file transfer also works.

## Keyboard and display controls

| Key | Action |
| --- | --- |
| **W / S** | Increase / decrease persistent throttle |
| **A / D** | Yaw left / right |
| **↑ / ↓** | Pitch forward / back |
| **← / →** | Roll left / right |
| **Space** | Arm / disarm; throttle returns to zero |
| **H** | Set level-hover power; no altitude hold |
| **Tab** | Angle / Acro |
| **C** | Chase / FPV camera |
| **[ / ]** | Adjust FPV camera tilt (30° upward by default) |
| **B** | Calm / light wind / breezy |
| **R** | Return to pad, disarmed; restart circuit attempt |
| **Escape** | Pause / resume |
| **F1 / F2** | Guide / phone pairing |
| **F3** | Minimal display → full instruments → hidden HUD |
| **F4 / 2–5** | Airframe comparison / select size while disarmed |
| **F5** | Training menu; arrows or mouse to select, Enter or launch button to start |
| **F6** | Scenic mountain launch selector (disarm first) |
| **F7 / F8 / F9** | Lighting preset / graphics quality / home marker |
| **F10** | Summer / autumn / winter scenery |
| **G / Y / P / O** | Scenic trail / flight recording / saved ghost / landing hints |
| **F11** | Full screen / windowed |
| **K** | Disconnect phone and use keyboard |
| **M** | Mute / unmute motors |

Hold W gently past hover power, then release to keep that setting. Tap S to descend. Small pitch/roll inputs are easier to control than long holds. Some keyboards cannot register all simultaneous key combinations.

**Angle** commands up to 80° pitch/roll per axis and self-levels on release. **Acro** commands rotation rates; releasing the stick stops rotation while retaining tilt. Neither mode holds altitude or position. Banking redirects thrust, so maintaining height requires additional throttle.

## World and training

Press **F5 while disarmed** to choose a lesson or circuit. All districts remain accessible in free flight. Launching an activity moves you to its launch pad, disarmed; **R** returns there. Select activities on the PC, then fly with controller 1.3 on your phone.

![Training selector and connected-world overview](docs/images/training-menu.png)

| District | Activities and practice |
| --- | --- |
| Airfield | Original seven-gate circuit; cross-country explorer |
| Rural meadow | Ten-second hover box, precision landing, figure-eight turns |
| Pine woodland | Lower-altitude slalom between solid trunks |
| Freight yard | Container gaps, open warehouse and elevated gantry |
| Quarry | Tower climb, tilted descent gate and recovery |
| Lakeside | Bridge underpass over water, dock and shoreline |

Race through the teal opening in the correct direction and numerical order. The timer starts at gate 01 and finishes on returning through 01 after every other gate. Gate clearance accounts for the aircraft's physical span. Changing flight mode or wind restarts the scoring attempt. Hard impacts and water contact stop the motors; reset to retry.

The F3 instrument display scales its map to the selected activity. Height telemetry uses a downward collision ray at 10 Hz to estimate height above the surface below, including raised pads and structures. See the [training guide](docs/TRAINING.md) for tolerances, medal targets, saved records and a suggested learning path.

### World screenshot gallery

Captured directly in Godot from the playable world. Select an image to inspect its full resolution.

| Rural meadow and figure-eight circuit | Pine woodland slalom |
| --- | --- |
| ![Meadow with open barn, crop rows, landing pads and figure-eight gates](docs/images/meadow.png) | ![Pine slalom weaving between physical tree trunks](docs/images/pine-slalom.png) |
| **Freight yard technical circuit** | **Lakeside bridge run** |
| ![Freight yard with warehouse passage, stacked containers, gantry and factory buildings](docs/images/freight-yard.png) | ![Lakeside bridge with a flyable underpass, shoreline rocks and dock](docs/images/lakeside-bridge.png) |
| **Hover lesson and instruments** | **Original FPV camera view** |
| ![Hover box with live telemetry, target marker and lesson hold timer](docs/images/hover-lesson.png) | ![FPV view from the original camera position](docs/images/fpv.png) |

### Materials and prop detail

![Factory district using detailed brick facade modules and PBR surfaces](docs/images/scenery-factory.png)

![Quarry using scanned rock meshes and photographed surface materials](docs/images/scenery-quarry.png)

![Freight props with photographed wood, hardware and surface wear](docs/images/freight-props.png)

## Physics and realism

Each airframe is a `RigidBody3D` with profile-specific mass/inertia, motor lever arms, drag and thrust limits. A body-rate PID controller mixes commands into four motor forces; rotor speed has a profile-specific 18–45 ms response and thrust is proportional to speed squared. Ground effect and rotor-plane drag use bounded engineering approximations. Gravity and contact response remain engine-driven.

Detailed blade aerodynamics, propwash/vortex-ring state, battery sag, frame flex, RF latency and structural damage are not modeled. Frame/battery colliders are simplified. Parameters are not calibrated against real flight logs. Touchscreens cannot reproduce spring tension or physical-stick muscle memory.

See [Physics model and parameters](docs/PHYSICS.md) for coefficients and limitations.

## Development and checks

Install **Python 3**, **Godot 4.5.1** and a **JDK** for the Java tests. No Python packages are required.

```bash
python tests/run_checks.py --godot /path/to/godot
```

The runner checks project import, gravity/hover/attitude behavior, ground stability, matching terrain edges/manifold geometry, mountain launch/portal collision, district/circuit collision, lesson scoring and persistence, keyboard integration, the real UDP receiver, control math, haptic detection, asset/APK checksums and restricted APK transfer. GitHub Actions runs the same checks. Physical Android input and vibration require manual validation.

The exact Java sender also has corrupted-packet, socket-error, short-gap and sustained-loss tests, plus an end-to-end test against an isolated Godot process. Supply `--json-jar /path/to/json-20240303.jar` to include them locally; CI downloads this test-only runtime with a pinned SHA-256 checksum. The APK uses Android's built-in JSON implementation and has no extra runtime dependency.

The Android app is plain Java, with no external app libraries or Gradle dependencies. Build on Windows using **OpenJDK 17**, **SDK platform 35** and **build-tools 35.0.1**:

```powershell
.\android-controller\build.ps1 -Jdk 'C:\path\to\jdk-17' -Sdk 'C:\path\to\android-sdk'
```

See [Development and build instructions](docs/DEVELOPMENT.md). Keep your generated development signing key private. Builds signed by another publisher cannot update the distributed APK in place.

## Project layout

```text
scenes/                  Main Godot scene
scripts/                 Aircraft, world, cameras, HUD and phone receiver
android-controller/      Android source, build script and transfer helper
dist/                    APK, SHA-256 checksum and phone setup guide
tests/                   Physics, input, network and artifact checks
docs/                    Training, physics and development guides; screenshots
assets/                  Bundled CC0 models, PBR textures, HDR sky and shaders
dev/                     Optional checksum-verified scenery download helper
```

## Contributing and license

Issues and focused pull requests are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md). For vulnerabilities, see [SECURITY.md](SECURITY.md). See [CHANGELOG.md](CHANGELOG.md) for changes.

Code and generated geometry are licensed under the **[MIT License](LICENSE)**. The included source models, photographs and HDRI are CC0; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and `assets/sources.json`. Godot, Android tools and Java are separate dependencies with their own licenses and are not redistributed here.
