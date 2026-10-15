# FinEcho

An offline-first personal finance app built with Flutter. FinEcho keeps
accounts, transactions, and budgets private on the user's device.

## Onboarding

The first-run flow introduces local-first storage, voice logging, optional
Android SMS automation, and app-lock setup. Progress is persisted between
steps so users can resume where they left off.

### Screenshots

| Screen | Light | Dark |
| --- | --- | --- |
| Welcome | `![Welcome light](docs/screenshots/onboarding/welcome_light.png)` | `![Welcome dark](docs/screenshots/onboarding/welcome_dark.png)` |
| Flow introduction | `![Onboarding light](docs/screenshots/onboarding/onboarding_light.png)` | `![Onboarding dark](docs/screenshots/onboarding/onboarding_dark.png)` |
| Security setup | `![Security setup light](docs/screenshots/onboarding/security_setup_light.png)` | `![Security setup dark](docs/screenshots/onboarding/security_setup_dark.png)` |
| Home after setup | `![Home light](docs/screenshots/onboarding/home_light.png)` | `![Home dark](docs/screenshots/onboarding/home_dark.png)` |

## Security

The app lock protects the home, accounts, statistics, and settings surfaces.
During onboarding, the user configures a six-digit PIN. FinEcho stores only a
salted HMAC-SHA256 PIN verifier, never the raw PIN, and applies a temporary
lockout after five consecutive failed attempts.

### Screenshots

| Screen | Light | Dark |
| --- | --- | --- |
| App lock | `![App lock light](docs/screenshots/security/app_lock_light.png)` | `![App lock dark](docs/screenshots/security/app_lock_dark.png)` |
| Locked home | `![Locked home light](docs/screenshots/security/locked_home_light.png)` | `![Locked home dark](docs/screenshots/security/locked_home_dark.png)` |

## CI/CD

GitHub Actions provides a FAST gate for formatting, code generation, static
analysis, and tests with coverage, followed by a FULL Android build gate. A
dispatch-only release workflow builds an unsigned standard APK until product
flavors are introduced. Pull requests are labeled from a repository-managed
configuration.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
