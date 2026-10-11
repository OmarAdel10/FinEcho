# FinEcho Project Context

This is the FinEcho project, an offline-first personal finance tracker built with Flutter using MVVM/BLoC architecture.

The project follows the specifications in the `docs/` directory.

Key aspects:
- MVVM/BLoC architecture with repository pattern
- Multiple currencies support (account-level currency, amounts stored as integer minor units)
- Error handling strategy (centralized error handling, user-friendly messages, logging)
- Commit style using emojis (refer to the Commit style section in DEVELOPMENT_ENVIRONMENT.md)
- Localization: English (default) and Arabic (using flutter_intl and flutter_localizations)
- UI inspiration taken from https://libraries.dev/ for animations and voice components (recreated in Flutter)
- Branching strategy: feature-branch workflow with `development` as integration branch, strict thread isolation, no deletion of branches.
- Plane integration: all work tracked in Plane via `planecli` with state transitions from Backlog to Done.
- Shorebird integration: used for over-the-air updates to bypass store review for critical patches.

For detailed specifications, refer to the `docs/` directory.
