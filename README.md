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

The app lock protects every protected screen. During onboarding, the user
configures a six-digit PIN. FinEcho stores only a salted HMAC-SHA256 PIN
verifier, never the raw PIN, and applies a temporary lockout after five
consecutive failed attempts. Lock metadata and the verifier live in platform
secure storage, configured users are challenged at cold start, the app relocks
when it is paused while a protected screen is open, and Android sets
`FLAG_SECURE` app-wide to block screenshots and recents previews. If secure
storage cannot be read, the app shows a recovery screen instead of protected
content. That screen offers retry and an explicitly destructive `Erase app
data` action; because the verifier is unreadable in this state, the action is
unauthenticated by design and clears local data before the app can continue.

### Screenshots

| Screen | Light | Dark |
| --- | --- | --- |
| App lock | `![App lock light](docs/screenshots/security/app_lock_light.png)` | `![App lock dark](docs/screenshots/security/app_lock_dark.png)` |
| Locked home | `![Locked home light](docs/screenshots/security/locked_home_light.png)` | `![Locked home dark](docs/screenshots/security/locked_home_dark.png)` |

## Transactions

The home surface lists recent transactions and supports manual entry for
income, expenses, and transfers. Amounts are validated as positive values
attached to a real account, and entry works fully offline. Account and
category management arrive with their own features.

### Screenshots

| Screen | Light | Dark |
| --- | --- | --- |
| Home ledger | `![Home ledger light](docs/screenshots/transaction/home_ledger_light.png)` | `![Home ledger dark](docs/screenshots/transaction/home_ledger_dark.png)` |

## Statistics

The statistics surface summarizes weekly, monthly, and yearly income and
spending from local history. It shows per-category and per-account breakdowns,
projected month-end spending, recurring charges, unusual-spending detection,
and budget progress, all computed on device.

### Screenshots

| Screen | Light | Dark |
| --- | --- | --- |
| Statistics overview | `![Statistics light](docs/screenshots/analytics/statistics_light.png)` | `![Statistics dark](docs/screenshots/analytics/statistics_dark.png)` |
| Insights and budgets | `![Insights light](docs/screenshots/analytics/insights_light.png)` | `![Insights dark](docs/screenshots/analytics/insights_dark.png)` |

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
