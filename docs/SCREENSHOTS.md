# Screenshot provenance

The README images are direct captures of the running simulator and Android app. They are not concept renders or generated mockups.

## PC simulator

`tests/visual_capture.gd` captures the normal field, FPV camera and airframe selector. `tests/expansion_capture.gd` captures the F5 training menu, district overviews, lesson instruments and scenery details. Run these with the standard Godot renderer, not headless mode:

```bash
godot --path . --script tests/visual_capture.gd
godot --path . --script tests/expansion_capture.gd
```

The scripts use temporary controller ports and isolated progress so captures cannot pair with a running pilot session. PNG outputs in `tests/` are ignored; selected originals are copied to `docs/images/`. Screenshots use Forward+ rendering with the project's included assets.

## Mountain scenery

`tests/mountain_capture.gd` captures the explorer selector and actual in-engine scenery views at 1440 × 900 with Forward+ rendering. The inspection camera uses a 75-degree view to examine the terrain; normal FPV remains at its original 105-degree field of view and mounting. The aircraft is hidden in scenery inspection shots. High graphics and morning lighting are used unless the filename identifies golden hour or mist. Screenshots are unretouched.

```bash
godot --path . --script tests/mountain_capture.gd
```

## Android remote

`mobile-pairing.png`, `mobile-remote.png` and `mobile-live.png` were captured from the signed controller 1.3 APK running in a 1280 × 720 Android 6.0 emulator. The connected/live views use the actual app sender and an isolated real Godot simulator, with a test-only UDP bridge to its temporary host port. No example telemetry was painted into the interface.

The pairing capture shows empty address/code fields. The connected view is paused and disarmed; the live view shows a real controlled test session. These images verify Android rendering and protocol operation in the emulator. They do not validate physical-phone touch ergonomics, real Wi-Fi conditions or vibration feel.

For a new Android capture, install the current `dist/VectorController.apk` on your chosen test device, pair it with an isolated simulator, and capture via Android's screenshot function or `adb exec-out screencap -p`. Preserve the original screenshot and identify the test device/emulator in any new captions.

## World expansion

`tests/frontier_capture.gd` captures the second page of the eighteen-site explorer and the coast, rice terraces, braided river, slot canyon, mine, dam, quarry, alpine bowl, seasons, cableway, waterfall alcove, lake islands and an enabled scenic guide. These are direct Forward+ captures of the running world at 1440 × 900 using the same inspection-camera conventions above. The teal line in the trail image is the optional G guide, drawn by the simulator. It is not a recorded player flight.

```bash
godot --path . --script tests/frontier_capture.gd
```
