# Vector Flight Lab v1.3.0

Six connected practice districts, nine training activities, detailed scenery and a more resilient Android radio.

- **Expanded world:** 2.4 × 2.4 km terrain with airfield, meadow, pine woodland, freight yard, quarry and lakeside bridge. F5 selects lessons and circuits; all areas remain reachable in free flight.
- **Pilot training:** steady-hover and precision-landing lessons, technical and endurance circuits, persistent personal bests and medals separated by drone size, mode and wind.
- **Proper scenery assets:** scanned rocks, a modular brick factory kit, crates, drums and photographed PBR materials; source checksums and CC0 credits are included.
- **Ground fixes:** stable small-frame contacts, matching paved-surface collision, thin painted markings and clearer chase-view arms. The original FPV camera is preserved.
- **Phone disconnect fix:** a brief signal gap freezes physics after 350 ms and can recover within two seconds without re-arming. Sustained loss still disarms and requires explicit resume/re-arm. Intentional pauses remain paused.
- **Controller 1.3:** foreground Wi-Fi latency lock, transient socket retries, malformed/stale telemetry rejection and a safe disconnect request when only the telemetry return path fails.
- **Documentation:** expanded world gallery and real Android emulator screenshots. Tests cover receiver recovery, the exact Java sender and end-to-end Java/Godot control.

## Update

Update the PC repository, restart the simulator, and install **VectorController.apk** over your existing app. The package and signing key are unchanged. Use controller 1.3 and the updated PC together for the disconnect fix; no uninstall is needed.

Android 6.0+ is supported. Pair on the same private network, tap Start/Resume, then Arm. After a sustained link loss, reconnect with neutral controls and restart deliberately.

Physics parameters remain engineering estimates rather than validated brand replicas. Android rendering and protocol flow were checked in an emulator; physical-device multitouch, real Wi-Fi quality and haptic feel still need device validation.
