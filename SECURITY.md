# Security

Vector Flight Lab is a simulator. The phone controller must never be connected to real aircraft hardware.

Phone control is intended for a trusted private local network. UDP packets are paired with a six-digit code and session/sequence checks, but the protocol is **not encrypted** and pairing is not a substitute for cryptographic authentication. Do not expose UDP 42424 or the optional TCP 8765 download helper to the internet or forward them through a router.

The optional transfer helper serves only the installation page and APK. Stop it after transferring the app. Store signing keys outside source control. The included APK is a locally signed development build, not a Play Store release.

For a suspected vulnerability, use GitHub's private vulnerability reporting if it is available for this repository. Otherwise contact the maintainer privately through their GitHub profile. Do not post credentials or sensitive exploit details in a public issue.
