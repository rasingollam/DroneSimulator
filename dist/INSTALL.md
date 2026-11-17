# Install Vector Controller on your Android phone

**Version 1.2 adds airframe selection and profile-specific hover guidance**, retaining haptic feedback. Install this APK over the existing app; the package and signing key are unchanged. It requires the updated PC simulator for airframe switching; old phone builds still control the PC, with size selection available on the PC keyboard.

1. Copy **VectorController.apk** from this folder to your phone with a USB cable, then open it on the phone. Alternatively, double-click **Install-on-phone.cmd** in the project folder and open the displayed local address in your phone browser to download the APK over Wi-Fi. This helper shares only the APK and its installation page. Close its window when finished.
2. Android may ask you to allow installation from the browser or file manager you used. Enable that permission for this installation. The APK is locally signed for direct installation; it is not a Play Store release. You can revoke the installer permission afterward.
3. Connect phone and PC to the **same private Wi-Fi network**. The PC may also use Ethernet on the same LAN. Avoid guest Wi-Fi/client isolation and VPNs while pairing.
4. Double-click **Launch.cmd** on the PC and press **F2**. Keep this simulator window open. Enter its IPv4 address and six-digit pairing code in the phone app. The code changes each time you restart the simulator.
5. If Windows Firewall asks, allow Godot on **Private networks**. If using Wi-Fi APK transfer, allow Python on Private networks too. The simulator receives on **UDP 42424**; the optional download helper uses **TCP 8765**. No router port forwarding is needed.
6. After the phone says **CONNECTED**, select an **AIRFRAME** while disarmed if desired, then tap **START / RESUME** and **ARM**. Slowly raise throttle just above the displayed **HOVER** setting (default 5-inch: about 36%). Release to keep throttle. Drag downward to descend. Start in Angle mode.

Use the phone's **AIRFRAME** button to choose 2-, 3-, 4- or 5-inch representative builds. Selection pauses and resets flight, leaves motors disarmed, and updates the HOVER label. On the PC, F4 opens a comparison/model preview and number keys 2–5 select sizes. See `docs/DRONE_PROFILES.md` for source data, estimates and limits.

## Stick behavior

- **Left:** drag up/down to adjust persistent throttle; left/right controls yaw and centers when released.
- **Right:** drag up/down for pitch, left/right for roll. Both center when released. Up pitches forward.
- Sticks use relative drag from where your thumb first touches, so touching or re-gripping never jumps the throttle. Each stick tracks its own finger. You can lift and re-grip to continue adjusting throttle.
- **Angle** self-levels. **Acro** preserves tilt after releasing the right stick. Neither mode holds position or altitude.
- **Pause** freezes flight. **Reset** returns to the pad, disarmed. **Disarm** cuts motor power. **FPV / Chase** changes the PC camera.
- Closing, backgrounding, or disconnecting the app makes the PC pause and disarm after **500 ms without valid control packets**. A neutral reconnect requires Start/Resume and Arm again. Throttle returns to zero after disarming or resetting.
- If you want keyboard controls again, press **K** on the PC. This disables phone takeover. Press F2 to enable phone pairing again.

The on-phone delay is measured **round-trip network time**, not total input-to-display latency. Poor Wi-Fi can still cause delay; use a nearby router with a strong signal. This controller operates the simulator only.

## Haptic stick feedback

Haptics are enabled by default. Use the **HAPTICS ON / OFF** button at the top of the phone screen to toggle them; the app remembers your choice. Turning them on plays a test tap.

- A short tap confirms a finger has engaged a stick.
- A light tick marks yaw, pitch or roll returning to neutral, crossing through neutral, or centering when released after moving away from center.
- A distinct limit bump marks full positive/negative yaw, pitch or roll, and zero/full throttle. Throttle does not have a midpoint/hover vibration and remains at its last setting when released.
- Holding at center or at a limit does not vibrate continuously. Hysteresis filters finger jitter, and cues are rate-limited to avoid overlapping vibrations. Simultaneous axis events merge into one cue, prioritizing a limit bump.

These are Android's system touch-feedback effects and respect its vibration preferences. Enable **Touch vibration / Haptic feedback** in Android settings if no taps are felt. Hardware and system settings determine the actual strength. Phones with no reported vibration motor show **NO VIBRATOR**. Vibration affects the whole phone, not individual thumbs. The cue logic is tested on the PC; actual tactile feel still needs testing on your phone.

## Troubleshooting

**Waiting / not connected:** Check the address and all six code digits, same-network connectivity, Private-network firewall access, and that only one simulator instance is running. A wrong code does not take control. Reopen CONNECT to retry. If multiple IPs appear under F2, use the Wi-Fi/Ethernet address rather than a VPN or virtual adapter address.

**Connected but not flying:** Tap Start/Resume first, then Arm. Arming requires neutral sticks and zero throttle. Raise throttle gently above the hover mark. The PC window should remain visible while you fly.

**App not installed:** Android 6.0 or newer and a multitouch screen are required. If an older copy signed with a different key is installed, uninstall it before installing this build. Check that your downloaded file is the complete APK.

The APK was built and its signature/package were checked on the PC. Touch math and the simulator's real UDP receiver have automated tests; installation and touch performance still need confirmation on your physical phone.
