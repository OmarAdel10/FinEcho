# FinEcho Development Environment

## Required tooling

- Flutter stable SDK and Dart bundled with that Flutter release.
- Android Studio with Android SDK, emulator, and a physical Android device for SMS-related testing.
- Xcode and CocoaPods on macOS for iOS builds (not available).
- Git and GitHub repository access.
- JDK version required by the selected Flutter/Android Gradle Plugin pairing.
- VS Code with the Flutter and Dart extensions.

Record exact versions in `.tool-versions` once the team selects them. Use `flutter doctor` before starting work.

## Project setup

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
```

Keep secrets out of the repository. Use local environment files ignored by Git for signing and release credentials.

FinEcho is currently **specification-only**. Do not add runtime dependencies, platform configuration, or application code until the user has reviewed and approved these specs.

## Planned runtime packages

Add these packages when implementation begins:

| Package                           | Purpose                                              |
| --------------------------------- | ---------------------------------------------------- |
| `flutter_bloc`                  | MVVM ViewModels implemented as`Bloc` or `Cubit`. |
| `flutter_screenutil`            | Responsive sizing for phone-first layouts.           |
| `pinput`                        | Six-digit PIN fallback.                              |
| `another_flutter_splash_screen` | Native animated splash behavior.                     |
| `lottie`                        | Lightweight motion and repeated state animations.    |
| `sqflite_sqlcipher`             | Encrypted local SQLite storage.                      |
| `flutter_localizations`         | Built-in Flutter localization widgets.               |
| `flutter_intl`                  | Internationalization utilities for Flutter.          |

Do not install them during the specification phase.

## Stitch design reference

The generated Stitch export is stored directly under `deliverables/stitch/`:

- Design system: `deliverables/stitch/editorial_ledger/DESIGN.md`
- Screen folders: `deliverables/stitch/01_animated_splash/` through `deliverables/stitch/10_settings_system/`
- Extra splash reference: `deliverables/stitch/splash_screen/`

Use `screen.png` as the visual source of truth and `code.html` only as a layout reference. Do not copy its HTML into the Flutter implementation.

The current export is incomplete: the `screen.png` files for `04_onboarding_automation`, `06_home_ledger`, `08_accounts_vaults`, `09_statistics_analytics`, and `10_settings_system` are placeholder text rather than images. Re-export those five screens before implementation. Until then, `docs/DESIGN_PROMPT.md` is the canonical design specification and `editorial_ledger/DESIGN.md` is reference-only.

## Build flavors

FinEcho uses three product flavors: `development`, `staging`, and `production`. Configure matching Android `productFlavors` and iOS schemes, and keep the flavor names and environment values centralized so the same names are used by Flutter, Gradle, Xcode, VS Code, and CI.

| Flavor          | Purpose                                                                          | Example command                                                                          |
| --------------- | -------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `development` | Local iteration, verbose diagnostics, and sample data.                           | `flutter run --flavor development --dart-define=ENVIRONMENT=development`               |
| `staging`     | Release-like behavior with isolated data and a visible non-production indicator. | `flutter run --flavor staging --dart-define=ENVIRONMENT=staging`                       |
| `production`  | Final release behavior with no diagnostics or sample data.                       | `flutter build apk --release --flavor production --dart-define=ENVIRONMENT=production` |

For iOS release builds, use `flutter build ipa --release --flavor production --dart-define=ENVIRONMENT=production`.

### VS Code launch configurations

Keep `.vscode/launch.json` aligned with these three flavors so they can be started directly from the editor with the Flutter and Dart extension:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "FinEcho (development)",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": [
        "--flavor",
        "development",
        "--dart-define=ENVIRONMENT=development"
      ],
      "flutterMode": "debug"
    },
    {
      "name": "FinEcho (staging)",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": [
        "--flavor",
        "staging",
        "--dart-define=ENVIRONMENT=staging"
      ],
      "flutterMode": "debug"
    },
    {
      "name": "FinEcho (production)",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": [
        "--flavor",
        "production",
        "--dart-define=ENVIRONMENT=production"
      ],
      "flutterMode": "release"
    }
  ]
}
```

If `launch.json` already exists, add these configurations alongside the existing ones rather than replacing unrelated debugger entries.

## App icon and splash assets

The production icon package is stored under `assets/icon/`. These files are the source assets for launcher-icon and native-splash generation:

| Asset                                        | Purpose                                   |
| -------------------------------------------- | ----------------------------------------- |
| `assets/icon/app_icon_dark_1024.png`       | iOS app icon and default launcher base.   |
| `assets/icon/adaptive_background_1024.png` | Android adaptive-icon background layer.   |
| `assets/icon/adaptive_foreground_1024.png` | Android adaptive-icon foreground layer.   |
| `assets/icon/monochrome_1024.png`          | Android 13+ themed/monochrome icon layer. |
| `assets/icon/splash_mark_1024.png`         | Native splash mark.                       |

Use the same icon package for all three flavors. If a flavor later needs a distinct launcher treatment, add flavor-specific generated outputs through Android `productFlavors` or iOS schemes rather than replacing the shared source assets.

## Localization

FinEcho supports American English (default) and Arabic. Use the `flutter_intl` package to generate localizable strings and the `flutter_localizations` package for Flutter's built-in localizations.

When implementation begins, add the following to `pubspec.yaml` under dependencies:

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  flutter_intl: ^0.1.0
```

Run `flutter pub get` and then use the Intl VS Code extension or the `flutter_intl` command to generate the localization files under `lib/l10n/`.

The default language is English (United States). Arabic translations will be provided in `app_ar.arb`.

All UI strings must be placed in the ARB files and accessed via the generated `AppLocalizations` widget.

These source files are intentionally not yet declared in `pubspec.yaml` because FinEcho is specification-only. Declare the `assets/icon/` directory and configure the icon generators when implementation begins.

## Suggested repository layout

```text
lib/
  app/
    bootstrap/
    di/
    router/
    theme/
    widgets/
  core/
    database/
      schema/
      migrations/
    repositories/
      contracts/
      implementations/
    models/
    widgets/
      finance/
      feedback/
      overlays/
      motion/
    utils/
  platform/
    speech/
    android_sms/
    notifications/
    security/
  features/
    transaction/
      data/
        models/
        repositories/
      view/
        screens/
        widgets/
      view_model/
        models/
        services/
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
assets/
  icon/
deliverables/
  stitch/
test/
integration_test/
android/
ios/
docs/
```

The same `data`, `view`, and `view_model` structure applies to `security` and any future feature.

## Team workflow

- Create a feature branch per independently reviewable change.
- Keep commits small and use imperative messages such as `feat: add transaction review sheet`.
- Open pull requests into the default branch; require CI before merge.
- Keep each feature’s View, ViewModel, Model, and Service changes together in the same branch.
- Use `git worktree` only when parallel feature work makes it useful, and keep each worktree on its own branch.

## CI/CD

GitHub Actions should run `flutter pub get`, `dart format --set-exit-if-changed lib test`, `flutter analyze`, and `flutter test --coverage` for pushes and pull requests. Add separate build jobs for the `development`, `staging`, and `production` flavors once platform signing and scheme setup are complete. Use Shorebird for over-the-air updates to bypass store review for critical patches.

## Platform permission notes

- Request notification, microphone, and biometric permissions just before the related feature needs them.
- Android SMS permissions must be justified, optional, and tested on real hardware and current Android versions.
- iOS does not receive a general SMS reading permission; keep that automation isolated to Android.

## Error handling

- Use a centralized error handling mechanism (e.g., a custom `ErrorHandler` class) to catch and log errors.
- Display user-friendly error messages via dialogs, snackbars, or toast notifications.
- Distinguish between expected errors (e.g., validation errors) and unexpected errors (e.g., crashes).
- Log unexpected errors to a local file or reporting service (if opted-in) for debugging.
- Ensure that error states do not leave the app in an inconsistent state; use transactions for critical operations.

## Commit style

- Use emojis to prefix commit messages according to the type of change:
  - ✨ `:sparkles:` for new features
  - 🐛 `:bug:` for bug fixes
  - 📝 `:memo:` for documentation
  - 💄 `:lipstick:` for UI and style changes
  - ♻️ `:recycle:` for refactoring
  - ✅ `:white_check_mark:` for tests
  - 🔨 `:hammer:` for major changes
  - ⚡️ `:zap:` for performance improvements
  - 🔥 `:fire:` for removing code or files
  - 💚 `:green_heart:` for CI/CD fixes
  - ⬇️ `:arrow_down:` for downgrading dependencies
  - ⬆️ `:arrow_up:` for upgrading dependencies
  - :patch: `:patch:` for patches
  - 🔒 `:lock:` for security-related changes
  - 🔖 `:bookmark:` for releasing / versioning
  - 🤖 `:robot:` for automated changes by bots
  - 🥗 `:green_salad:` for health-related changes (e.g., linting fixes)
- Keep the commit message short and descriptive in the present tense.
- Example: `:sparkles: add transaction list view`

## Design inspiration

- Take inspiration from https://libraries.dev/ for loading animations, voice UI, and border beam effects.
- Note that the components on libraries.dev are implemented in React, React Native, and SwiftUI, so we will recreate the desired effects using Flutter's animation system and custom painters.
- Specifically, we can implement:
  - Thinking dots: a pulsating dot animation for loading states.
  - Voice UI: a waveform animation that reacts to audio input.
  - Border beam: a moving gradient border effect for active inputs.
- Use Flutter's `AnimationController`, `CustomPainter`, and `ShaderMask` to achieve similar effects.

## Branching Strategy

- `development` is the canonical integration branch (remote-backed `origin/development`). Changes arrive ONLY via feature-branch merges (Pull Requests). Direct commits to `development` are FORBIDDEN.
- `master` is the stable/release branch. Tagged releases (`v*`) are cut from it. It runs CI; only `master` runs CD.
- Branch taxonomy:
  - `feature/{kebab-case-name}` — new capability or screen
  - `fix/{kebab-case-name}` — bug remediation
  - `refactor/{kebab-case-name}` — non-functional rewrite
  - `perf/{kebab-case-name}` — performance work
  - `chore/{kebab-case-name}` — tooling, deps, config
  - `docs/{kebab-case-name}` — documentation only
- Strict Thread Isolation: every independent feature, custom module, or screen layout configuration resides on its own dedicated branch.
- Work location: default = feature branch checked out in the master base. Worktree mode is used ONLY when 2+ features run in parallel and touch overlapping files.
- Sync: before merging, merge `origin/development` into the feature branch (prefer merge over rebase; rebase only with Git Workflow Master approval).
- Conflict protocol: a conflict touching another feature's domain = STOP and escalate to the orchestrator / user.
- NEVER DELETE BRANCHES. No branch — local or remote — is ever deleted for any reason (including after merge). Merged branches stay intact for audit and rollback.

## Plane Integration

- All future work and completion status is tracked in Plane via `planecli`.
- Project identifier: use the project's Plane identifier `FINECHO`.
- Future work found → create a work item.
- State transitions: Backlog → Todo → Planning → In Progress → Review → Done.
- Use `planecli work-item create` and `planecli work-item update --state`.
- Bulk sync: use the `plane-sync` skill.
- Never delete work items; close work by state change.
- Never mark done early; a work item moves to Done only after fresh verification output exists.
