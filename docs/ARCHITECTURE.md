# FinEcho Architecture

## Architecture standard

FinEcho is an offline-first Flutter app built with MVVM/BLoC. Every feature is organized around a View, a ViewModel implemented with `Bloc` or `Cubit`, a Model, and a Service. Views render immutable state and dispatch user intents. ViewModels own feature state and orchestration. Services own business rules, persistence, inference, and platform integration.

```text
Flutter View
    -> ViewModel (Bloc or Cubit)
        -> Feature Service
            -> encrypted SQLite, secure storage, STT, Android SMS bridge, notifications
```

Use `flutter_bloc` as the state-management package. Prefer `Bloc` for complex event-driven flows and `Cubit` for simpler feature state.

## Responsibilities

| Component | Responsibility |
|---|---|
| View | Screens, widgets, navigation, accessibility, loading and error presentation. |
| ViewModel | Immutable feature state, user intents, state transitions, and service orchestration. |
| Model | Plain data classes for transactions, accounts, budgets, categories, and drafts. |
| Service | Business rules and I/O: database access, categorization, local inference, integrations, and notifications. |
| Platform adapter | Biometric/PIN access, secure key storage, Android SMS bridge, microphone/STT bridge, and notification channels. |

## Feature organization

```text
lib/
  app/                  # bootstrap, routing, theme, dependency injection
    flavor/            # build-flavor and environment configuration
  features/
    transaction/
      views/            # screens and widgets
      viewmodels/       # Bloc/Cubit classes, events, and states
      models/           # feature-specific data classes
      services/         # transaction rules, persistence, and integrations
    account/
      views/
      viewmodels/
      models/
      services/
    budget/
      views/
      viewmodels/
      models/
      services/
    analytics/
      views/
      viewmodels/
      models/
      services/
    onboarding/
      views/
      viewmodels/
      models/
      services/
    settings/
      views/
      viewmodels/
      models/
      services/
  core/                 # shared theme, utils, error types, and routing helpers
  platform/             # native channel adapters and device-service interfaces
assets/
  icon/                 # launcher and splash source PNGs
```

Keep feature boundaries explicit. A feature may import shared `core` and `platform` abstractions, but it should not reach into another feature's internal services.

## Local data model

| Table | Key fields | Purpose |
|---|---|---|
| accounts | id, name, type, balance, masked_card_number | Financial containers. |
| transactions | id, account_id, category_id, amount, timestamp, type, source, raw_text | Ledger records. |
| categories | id, parent_category_id, name, icon_key, color_hex | Spending taxonomy. |
| budgets | id, category_id, allocated_amount, period, start_date | Category budget targets. |
| sms_parsing_rules | id, account_id, sender_pattern, amount_pattern, payee_pattern | Android parsing configuration. |
| notification_schedules | id, title, body, scheduled_time, repeat_interval, payload | Persistent local reminder rules. |

Foreign keys are enabled. Transaction timestamp, account, and category fields are indexed. Database migrations are versioned and tested.

## Security model

- Generate a database key using a cryptographically secure source.
- Store that key only in Android Keystore/iOS Keychain through secure storage.
- Open the local SQLCipher database only after the startup security flow succeeds.
- Avoid financial-data network calls and do not log raw SMS content or sensitive values in release builds.
- Require a user-initiated export and warn that exports may not be encrypted after leaving FinEcho.

## Automation pipelines

### Voice entry

The microphone adapter streams audio to an on-device model in a worker isolate. `VoiceCommandParser` converts transcription into a transaction draft. The user reviews the draft before `TransactionService` writes it within a database transaction.

### Android SMS ingestion

An Android native component receives permitted SMS events and forwards only the required fields to a background-safe Dart entry point. The worker matches an enabled parsing rule, extracts values, classifies the transaction, and writes it atomically. If the card is not mapped, the notification service creates an `unlinked_card` notification payload. Duplicate detection uses sender, timestamp window, amount, and message fingerprint.

### Categorization

1. Exact merchant dictionary match.
2. User or institution regular-expression rule.
3. Optional local statistical classifier.
4. Uncategorized queue if confidence is below the configured threshold.

The user correction updates future local rules or training examples only after explicit consent.

## Notifications and navigation

`LocalNotificationService` creates channels for budgets, reminders, and unlinked cards. Its payload contains a versioned, minimal route intent such as `{target: accounts, action: link_card, digits: 4921}`. The root navigation coordinator validates the payload and sends locked users through authentication before the target screen opens.

## Startup sequence

1. Initialize Flutter bindings, resolve the active build flavor, and build the dependency-injection container.
2. Obtain or create the protected database key.
3. Open and migrate the SQLCipher database.
4. Initialize notification channels, timezone data, and the deep-link handler.
5. Load onboarding and app-lock state.
6. Create feature services and BLoCs/Cubits.
7. Run the app.

## Environment configuration

FinEcho resolves one of three build flavors at startup: `development`, `staging`, or `production`. The flavor is stored in immutable `EnvironmentState` and injected through an `EnvironmentConfig` dependency before feature services and BLoCs/Cubits are created.

| Flavor | Behavior |
|---|---|
| `development` | Enables verbose diagnostics, sample data, and fake platform adapters during local development. |
| `staging` | Mirrors production behavior while keeping isolated data and a visible non-production indicator. |
| `production` | Uses release behavior with no sample data, verbose diagnostics, or raw SMS/sensitive logging. |

Views render immutable environment state, ViewModels expose it, and Services consume injected dependencies. The active flavor is an architectural input, not a runtime user setting.

## Testing strategy

- Unit-test ViewModels, feature services, models, parsers, categorization, and budgets.
- Test database access and migrations against an encrypted test database.
- Use widget tests for key screens and error states.
- Use integration tests for onboarding, manual entry, notification routing, and permission-denied fallbacks.
- Keep Android SMS and other platform integrations behind interfaces with fake implementations for CI.

## Architectural rules

- Views contain no business logic and never access services or the database directly.
- ViewModels expose immutable state and never import Flutter widgets.
- Services own side effects, validation, and business rules.
- Models remain plain data classes with no I/O.
- Platform integrations are isolated behind interfaces and can be faked in tests.
