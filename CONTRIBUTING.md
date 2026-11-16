# Contributing

Bug reports, reproducible flight-model improvements, controller fixes, and documentation improvements are welcome.

## Development

1. Fork and clone the repository.
2. Import `project.godot` in Godot 4.5.1 or later. The baseline used for validation is 4.5.1.
3. Run the relevant checks in [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).
4. Open a pull request explaining the problem, resulting behavior, and validation.

Keep changes focused. Use SI units in physics code, document the source of measured coefficients, and preserve the independent-motor force model. Distinguish engineering approximations from validated real-aircraft behavior. For visible UI changes, include a screenshot. For controller changes, check throttle persistence, axis signs, two-finger behavior, pause/reset, and lost-link handling.

Do not commit engine binaries, SDKs, caches, pairing codes, credentials, or signing keys. The Android package uses a local development signing key; forks generate their own and cannot install updates over another publisher's build without uninstalling that build first.

Contributions are provided under the repository's MIT license. Third-party assets or code must have compatible licenses and clear attribution.
