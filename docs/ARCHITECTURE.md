# FinEcho Architecture

## Architecture standard

FinEcho is an offline-first Flutter application built with **MVVM/BLoC** and a **repository pattern**. Every feature is feature-first and is split into a `data`, `view`, and `view_model` area. Views render immutable state and dispatch user intents. ViewModels—implemented with `Bloc` or `Cubit`—own feature state and orchestration. Feature services coordinate business rules and repository calls. The encrypted SQLite database is the single source of truth, and every financial read or write goes through a repository contract in `core`.

```text
Flutter View
    -> ViewModel (Bloc or Cubit)
        -> Feature Service
            -> Repository contract
                -> SQLite repository implementation
                    -> encrypted local database
```

Use `flutter_bloc` for state management. Prefer `Bloc` for event-driven flows and `Cubit` for simpler feature state.

## Responsibilities

| Component | Responsibility |
|---|---|
| View | Screens, widgets, navigation, accessibility, loading and error presentation. |
| ViewModel | Immutable feature state, user intents, state transitions, and service orchestration. |
| Model | Plain data classes for accounts, transactions, budgets, categories, drafts, and payloads. |
| Service | Feature business rules, validation, and coordination between repositories and platform adapters. |
| Repository | The only path to encrypted SQLite, secure preferences, and other durable local stores. |
| Platform adapter | Biometric/PIN access, secure key storage, microphone/STT bridge, Android SMS bridge, and notification channels. |

## Feature organization

Every feature uses the same shape:

```text
lib/
  app/                       # bootstrap, dependency injection, routing, app theme, app shell
    bootstrap/
    di/
    router/
    theme/
    widgets/                 # shell-only widgets such as bottom navigation and environment badge

  core/                      # shared application foundation
    database/                # encrypted SQLite schema, migrations, and query helpers
      schema/
      migrations/
    repositories/
      contracts/             # abstract repository interfaces consumed by feature services
      implementations/       # SQLite-backed repository implementations
    models/                  # shared immutable data models
    widgets/                 # reusable cross-feature widgets
      finance/
      feedback/
      overlays/
      motion/
    utils/

  platform/                  # native and device-service adapters
    speech/
    android_sms/
    notifications/
    security/

  features/
    transaction/
      data/
        models/              # feature-specific data models and mappers
        repositories/        # thin feature repository facades
      view/
        screens/
        widgets/
      view_model/
        models/               # immutable state, event, and form models
        services/             # feature orchestration and business rules
    account/
      data/
      view/
      view_model/
        models/
        services/
    budget/
      data/
      view/
      view_model/
        models/
        services/
    analytics/
      data/
      view/
      view_model/
        models/
        services/
    speech_to_text/
      data/
      view/
      view_model/
        models/
        services/
    sms_ingestion/
      data/
      view/
      view_model/
        models/
        services/
    notifications/
      data/
      view/
      view_model/
        models/
        services/
    onboarding/
      data/
      view/
      view_model/
        models/
        services/
    settings/
      data/
      view/
      view_model/
        models/
        services/
```

The same structure repeats for `security` and any future feature. Feature-specific widgets stay under `view/widgets`. Only widgets reused by multiple features move to `core/widgets`.

## Repository pattern

The encrypted SQLite database in `core/database` is FinEcho’s single financial source of truth. Feature services never open the database, import SQLite packages, or execute SQL directly. They call repository contracts.

### Repository contracts

| Contract | Responsibility |
|---|---|
| `AccountRepository` | Create, edit, archive, and watch accounts; manage card linking and sender mappings. |
| `TransactionRepository` | Create, edit, delete, confirm, and watch transactions, including manual, voice, SMS, and transfer entries. |
| `BudgetRepository` | Manage budget targets, thresholds, usage, snooze state, and recurring-budget projections. |
| `CategoryRepository` | Manage categories, merchant rules, suggestions, and user corrections. |
| `AnalyticsRepository` | Produce dashboard summaries, trends, recurring charges, unusual-spend detection, and forecasts. |
| `SpeechRepository` | Persist voice drafts, transcripts, parser results, and review state. |
| `SmsIngestionRepository` | Store Android SMS events, parsing rules, card mappings, dedupe keys, and unlinked-card state. |
| `NotificationRepository` | Manage schedules, cancellation, channels, payloads, throttling, and deep-link resolution. |
| `SettingsRepository` | Manage user preferences, automation toggles, permission state, exports, and data controls. |
| `SecurityRepository` | Manage biometric/PIN state, app lock, unlock attempts, and secure-key readiness. |

Repository contracts expose immutable models rather than SQLite rows. Streams are used for data the UI observes; commands return explicit `Future` results. Only `core/repositories/implementations` may import database helpers or SQL.

### Data flow

1. Views render immutable state and emit user intents.
2. ViewModels receive feature services or repository facades through dependency injection.
3. Feature services coordinate business rules and call repository contracts.
4. Repository implementations own database transactions, validation, and row mapping.
5. Platform adapters are injected into feature services, never into Views.
6. Cross-feature coordination uses repository streams or app-level events, not direct imports between feature internals.

## Account model

FinEcho supports the following account types:

| Enum value | Display label |
|---|---|
| `cash` | Cash |
| `debitCard` | Debit card |
| `creditCard` | Credit card |
| `prepaidMezza` | Prepaid / Mezza |
| `bank` | Bank account |
| `wallet` | Wallet |
| `savings` | Savings |
| `other` | Other |

Balances are stored as a decimal value (using integer minor units or a dedicated money type) to avoid floating-point inaccuracies. Credit cards track `creditLimit` and `outstandingBalance`; available credit is derived. Prepaid/Mezza accounts are stored-value balances and support top-ups. Card and sender linking applies to debit, credit, and prepaid/Mezza accounts.
The system supports multiple currencies. Each account has a currency field, and all monetary values are stored in the account's currency. Currency conversion is handled at the service layer when needed.


## Dedicated feature modules

- **`speech_to_text`**: owns the local speech model, microphone capture, transcription, parser, confidence handling, and editable voice draft state.
- **`sms_ingestion`**: owns Android-only SMS reception, parsing, dedupe, card mapping, and draft creation. iOS uses a no-op adapter and never reads SMS.
- **`notifications`**: owns channels, schedules, throttling, payload routing, and notification preferences.

These modules are peers of `transaction`, `account`, and the other features. They expose their own Views, ViewModels, Models, and Services.

## Core reusable widgets

Widgets used by multiple features live in `core/widgets`. Core widgets are presentational only: immutable state in, intent callbacks out, and no service, repository, or database imports.

| Group | Widgets |
|---|---|
| App shell and responsive primitives | `FinEchoScaffold`, `EnvironmentBadge`, `BottomNavigationShell`, `MotionScope`, `AnimatedNavigationShell`, `SectionCard` |
| Finance primitives | `AmountText`, `AccountTypeIcon`, `CategoryChip`, `ConfidenceBadge`, `StatusPill`, `TransactionRow`, `AccountCard`, `MetricTile`, `SegmentedPeriodSelector` |
| Feedback, overlays, and states | `AnimatedButton`, `AnimatedSearchField`, `TopSnackBar`, `AnimatedDialog`, `AnimatedBottomSheet`, `WaveformOverlay`, `ThinkingDialog`, `LoadingOverlay`, `SkeletonTile`, `EmptyState`, `ErrorState`, `PermissionCard` |
| Charts and data visualization | `ChartCard`, `RingChart`, `CategoryBarChart`, `TrendChart`, `BudgetGauge`, `ChartLegend` |
| Platform and sequence primitives | `SplashGate`, `PinEntryField`, `MotionIllustration` |

Core widgets must:

- Keep 44px minimum touch targets and visible focus states.
- Expose reduced-motion behavior through `MotionScope`.
- Remain accessible with text, color, and semantic labels, never color alone.
- Avoid direct navigation or persistence; screens and ViewModels own those decisions.

Feature-only widgets remain in `features/<feature>/view/widgets`. A widget moves to `core/widgets` only after at least two features need it.

## Local data model

| Table | Key fields | Purpose |
|---|---|---|
| accounts | id, name, type, currency, balance, masked_identifier, linked_account_id, credit_limit, outstanding_balance | Financial containers. |
| transactions | id, account_id, category_id, amount, timestamp, type, source, raw_text | Ledger records. |
| categories | id, parent_category_id, name, icon_key, color_hex | Spending taxonomy. |
| budgets | id, category_id, allocated_amount, period, start_date | Category budget targets. |
| speech_drafts | id, transcript, parsed_amount, parsed_payee, parsed_category, status | Voice-entry review state. |
| sms_messages | id, sender, received_at, fingerprint, parsed_payload, status | Android SMS ingestion state. |
| sms_parsing_rules | id, account_id, sender_pattern, amount_pattern, payee_pattern | Android parsing configuration. |
| notification_schedules | id, title, body, scheduled_time, repeat_interval, payload | Persistent local reminder rules. |

Foreign keys are enabled. Transaction timestamp, account, and category fields are indexed. Database migrations are versioned and tested.

## Security model

- App-lock metadata and the PIN verifier use platform secure storage (Android
  Keystore-backed storage; Android is the only configured platform). The
  storage backend is `flutter_secure_storage`, pinned to an exact version: the
  payload is encrypted with AES-GCM and the key is wrapped by the Android
  keystore. The legacy encrypted shared preferences path is not used, and the
  plugin is configured not to erase stored values on a keystore error, so a
  failure surfaces on the recovery screen instead of silently removing the
  lock. The store is also asked whether it still holds entries that the current
  backend cannot read, because a missing entry reads as an empty value rather
  than an error. The app fails closed on that report, so an upgrade from an
  older backend reaches the recovery screen instead of silently dropping the
  lock. The verifier is a random-salted PBKDF2-HMAC-SHA256 derivation (100,000
  iterations, 32-byte output) compared in constant time; the raw PIN is never
  stored.
  Verifiers persisted by earlier versions (single HMAC-SHA256 round, no version
  marker) are still verified against the legacy derivation; a newly configured
  PIN is always written in the current format. A corrupt verifier payload or an
  unsupported payload version is rejected while decoding, so it reaches the
  recovery screen instead of locking the user out. Tests and explicitly
  configured in-memory graphs may substitute fakes; the secure graph is the
  default and in-memory storage is the explicit opt-out.
- The startup flow loads the persisted onboarding and security state before
  showing any route. Configured users are routed to the protected area, where
  the gate shows the lock screen until the PIN is verified; unreadable secure
  storage shows a recovery screen instead of content. Retry re-reads secure
  storage. `Erase app lock` is intentionally destructive and unauthenticated
  because the PIN verifier is unreadable in this state; it removes the saved
  PIN and app-lock settings. Whenever a recovery reload finishes without a
  configured lock, the gate routes the app back to onboarding so the lock can
  be set up again. A normal start never moves the user away from the route they
  opened.
- Onboarding advances to the security-setup step explicitly before the security
  screen is opened, so the setup screen can complete onboarding after the PIN
  is stored.
- The security gate relocks the app when it is paused, and Android applies
  `FLAG_SECURE` app-wide so screens are excluded from screenshots and recents
  previews. Android cloud backup and device-to-device transfer exclude app data
  through `dataExtractionRules`; older Android versions also disable backup.
  Relocking on `inactive`/`hidden` and from app scope is deferred (FINECHO-28).
- Generate the database key using a cryptographically secure source.
- Store that key only in Android Keystore/iOS Keychain through secure storage.
- Open the local SQLCipher database only after the startup security flow succeeds.
- Avoid financial-data network calls and do not log raw SMS content or sensitive values in release builds.
- Require a user-initiated export and warn that exports may not be encrypted after leaving FinEcho.

## Automation pipelines

### Voice entry

The microphone adapter streams audio to an on-device speech model in a worker isolate. `VoiceCommandParser` converts the transcription into a transaction draft. The user reviews the draft before the transaction repository writes it within a database transaction.

### Android SMS ingestion

An Android native component receives permitted SMS events and forwards only the required fields to a background-safe Dart entry point. The worker matches an enabled parsing rule, extracts values, classifies the transaction, and writes it atomically. If the card is not mapped, the notification feature creates an `unlinked_card` payload. Duplicate detection uses sender, timestamp window, amount, and message fingerprint.

### Categorization

1. Exact merchant dictionary match.
2. User or institution regular-expression rule.
3. Optional local statistical classifier.
4. Uncategorized queue if confidence is below the configured threshold.

The user correction updates future local rules or training examples only after explicit consent.

## Notifications and navigation

`NotificationRepository` creates channels for budgets, reminders, and unlinked cards. Its payload contains a versioned, minimal route intent such as `{target: accounts, action: link_card, digits: 4921}`. The root navigation coordinator validates the payload and sends locked users through authentication before the target screen opens.

## Startup sequence

1. Initialize Flutter bindings, resolve the active build flavor, and build the dependency-injection container.
2. Obtain or create the protected database key.
3. Open and migrate the SQLCipher database.
4. Initialize notification channels, timezone data, and the deep-link handler.
5. Load onboarding and app-lock state.
6. Create feature services and BLoCs/Cubits.
7. Run the app.

## Environment configuration

FinEcho resolves one of three build flavors at startup: `development`, `staging`, or `production`. The flavor is stored in immutable `EnvironmentState` and injected through `EnvironmentConfig` before feature services and BLoCs/Cubits are created.

| Flavor | Behavior |
|---|---|
| `development` | Enables verbose diagnostics, sample data, and fake platform adapters during local development. |
| `staging` | Mirrors production behavior while keeping isolated data and a visible non-production indicator. |
| `production` | Uses release behavior with no sample data, verbose diagnostics, or raw SMS/sensitive logging. |

Views render immutable environment state, ViewModels expose it, and Services consume injected dependencies. The active flavor is an architectural input, not a runtime user setting.

## Testing strategy

- Unit-test ViewModels, feature services, models, parsers, categorization, and budgets.
- Test repository implementations against an encrypted test database.
- Use widget tests for key screens, reusable core widgets, and error states.
- Use integration tests for onboarding, manual entry, voice review, notification routing, and permission-denied fallbacks.
- Keep Android SMS and other platform integrations behind interfaces with fake implementations for CI.

## Architectural rules

- Views contain no business logic and never access services, repositories, or the database directly.
- ViewModels expose immutable state and never import Flutter widgets.
- Services own side effects, validation, and business rules, and call repository contracts.
- Models remain plain data classes with no I/O.
- Only repository implementations in `core` may import SQLite helpers or execute SQL.
- Platform integrations are isolated behind interfaces and can be faked in tests.
- Feature folders may import shared `core` and `platform` abstractions, but not another feature’s internal classes.
