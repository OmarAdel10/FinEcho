# FinEcho Product Requirements Document

## Product summary

FinEcho is an offline-first personal-finance tracker for Flutter. It helps an individual record, organize, and understand income and spending while keeping financial data on the device. The first release prioritizes clear manual tracking, optional on-device automation, and local-only storage rather than cloud account aggregation.

## Goals

- Make entering and reviewing transactions quick and understandable.
- Support accounts, budgets, analytics, and reminders in one local app.
- Convert voice entries and supported Android transaction SMS messages into reviewable transaction drafts.
- Categorize transactions automatically, while letting the user correct every result.
- Keep financial data private through on-device processing and encrypted local storage.

## Scope

### Core screens

1. Animated splash screen that initializes local services and checks the lock state.
2. Three-screen onboarding covering privacy, voice entry, and SMS automation.
3. Local sign-up or profile creation, biometric lock, and PIN fallback.
4. Home dashboard with net worth, period totals, quick actions, voice entry, and recent transactions.
5. Accounts screen for cash, wallet, bank, and card accounts, including Android SMS sender/card mapping.
6. Statistics screen for spending, income, budgets, recurring charges, and trends.
7. Settings and profile screen for security, permissions, automation, exports, reminders, and data controls.

The launcher and splash visuals use the shared icon package in `assets/icon/`; the animated splash uses `assets/icon/splash_mark_1024.png` as its native mark.

### Standout features

- Offline speech-to-text for spoken transaction entry.
- Android-only SMS parsing for locally received transactional messages, subject to user permission and platform policy.
- Rule-based and lightweight on-device auto-categorization.
- Card linking based on sender patterns and masked card digits found in supported messages.
- Budget recommendations based on prior local spending and a user savings target.
- Local notifications for budgets, unlinked cards, recurring payments, and reminders.

## Functional requirements

### Account and transaction management

- Users can create, edit, archive, and view cash, wallet, bank, and card accounts.
- Users can add income, expense, and transfer transactions manually.
- Every transaction has an amount, date, type, account, category, source, and optional note/payee.
- Account balances update atomically when a confirmed transaction is created, changed, or deleted.
- Users can review and correct any automated transaction before it becomes final.

### Automation

- The voice flow captures speech locally, extracts an amount/payee/category/account, and asks for confirmation.
- The SMS flow detects supported financial messages on Android, extracts available details using local rules, and creates a draft or confirmed transaction according to the user setting.
- When a supported message has no account mapping, FinEcho sends a local notification that deep-links to the card-linking screen.
- Categorization evaluates an exact merchant rule, then a regular expression rule, then an optional local statistical classifier. Low-confidence results remain uncategorized.
- Auto-budgeting proposes amounts; it never changes a user budget without confirmation.

### Budgets, analytics, and notifications

- Users can set category budgets and receive warnings at configurable thresholds such as 85% and 100%.
- The dashboard and statistics screen show weekly, monthly, and yearly totals by category and account.
- FinEcho identifies recurring transactions, unusual spikes, and projected month-end spending using local history.
- Scheduled reminders respect device timezone and can be turned off at any time.

### Security and privacy

- Financial records and parsing rules remain on-device.
- The database is encrypted and its key is held in OS secure storage.
- App unlock uses device biometrics when available, with a six-digit PIN fallback.
- Exports are initiated by the user and saved or shared through platform-controlled flows.

### Environment indicators

- Development and staging builds display a persistent, non-blocking environment indicator.
- Production builds display no environment indicator.
- The indicator must never obscure financial data or primary actions.

## Platform constraints

- The implementation follows MVVM/BLoC: Views render state, ViewModels own feature state with `Bloc`/`Cubit`, and Services own persistence and platform integration.
- The app provides three build flavors—`development`, `staging`, and `production`—with matching VS Code launch configurations.
- SMS reading and automatic SMS ingestion are Android-only. iOS does not provide a general SMS inbox API; the iOS app provides manual entry, voice entry, budgets, analytics, notifications, and local data tools.
- Offline STT model quality and download size must be selected for the target devices and languages.
- Permission denial must leave manual tracking fully usable.

## Acceptance criteria

- A new user can onboard, secure the app, create an account, and log a manual expense without network access.
- A voice entry produces an editable review sheet before persistence.
- A supported Android SMS can be parsed locally and routed to an account or an unlinked-card prompt.
- Budget thresholds produce local notifications when permission is granted.
- CI verifies formatting, static analysis, and tests for every pull request.

## Out of scope for the first release

- Cloud synchronization, banking APIs, remote analytics, and server-side accounts.
- Automatic iOS SMS ingestion.
- Autonomous edits to transactions or budgets without user confirmation.
