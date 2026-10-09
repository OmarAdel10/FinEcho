# FinEcho Development Environment

## Required tooling

- Flutter stable SDK and Dart bundled with that Flutter release.
- Android Studio with Android SDK, emulator, and a physical Android device for SMS-related testing.
- Xcode and CocoaPods on macOS for iOS builds.
- Git and GitHub repository access.
- JDK version required by the selected Flutter/Android Gradle Plugin pairing.

Record exact versions in `.tool-versions` or CI configuration once the team selects them. Use `flutter doctor` before starting work.

## Project setup

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
```

Keep secrets out of the repository. Use local environment files ignored by Git for signing and release credentials.

Add `flutter_bloc` before implementing feature state. Keep feature ViewModels, Models, and Services colocated under their feature directory; do not split them into a separate layered architecture tree.

## Build flavors

FinEcho uses three product flavors: `development`, `staging`, and `production`. Configure matching Android `productFlavors` and iOS schemes, and keep the flavor names and environment values centralized so the same names are used by Flutter, Gradle, Xcode, VS Code, and CI.

| Flavor | Purpose | Example command |
|---|---|---|
| `development` | Local iteration, verbose diagnostics, and sample data. | `flutter run --flavor development --dart-define=ENVIRONMENT=development` |
| `staging` | Release-like behavior with isolated data and a visible non-production indicator. | `flutter run --flavor staging --dart-define=ENVIRONMENT=staging` |
| `production` | Final release behavior with no diagnostics or sample data. | `flutter build apk --release --flavor production --dart-define=ENVIRONMENT=production` |

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

Commit `.vscode/launch.json` so the team shares the same flavor launch targets.

## App icon and splash assets

The production icon package is stored under `assets/icon/`. These files are the source assets for launcher-icon and native-splash generation:

| Asset | Purpose |
|---|---|
| `assets/icon/app_icon_dark_1024.png` | iOS app icon and default launcher base. |
| `assets/icon/adaptive_background_1024.png` | Android adaptive-icon background layer. |
| `assets/icon/adaptive_foreground_1024.png` | Android adaptive-icon foreground layer. |
| `assets/icon/monochrome_1024.png` | Android 13+ themed/monochrome icon layer. |
| `assets/icon/splash_mark_1024.png` | Native splash mark. |

Use the same icon package for all three flavors. If a flavor later needs a distinct launcher treatment, add flavor-specific generated outputs through Android `productFlavors` or iOS schemes rather than replacing the shared source assets.

Add `flutter_launcher_icons` and `flutter_native_splash` as dev dependencies, then generate the platform outputs with:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Configure the generators with these paths:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon_dark_1024.png"
  adaptive_icon_background: "assets/icon/adaptive_background_1024.png"
  adaptive_icon_foreground: "assets/icon/adaptive_foreground_1024.png"
  adaptive_icon_monochrome: "assets/icon/monochrome_1024.png"
  remove_alpha_ios: true

flutter_native_splash:
  color: "#FFFFFF"
  image: "assets/icon/splash_mark_1024.png"
  android_12:
    color: "#FFFFFF"
    image: "assets/icon/splash_mark_1024.png"
```

Keep the source PNGs in `assets/icon/`; do not edit generated Android or iOS launcher resources directly.

## Suggested repository layout

```text
lib/
  app/                  # app bootstrap, routing, theme, dependency injection
    flavor/            # build-flavor and environment configuration
  features/
    transaction/
      views/           # screens and widgets
      viewmodels/      # Bloc/Cubit classes, events, and states
      models/          # feature-specific data classes
      services/        # transaction rules, persistence, and integrations
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
  core/                 # shared theme, utils, errors, routing helpers, design tokens
  platform/             # native channel adapters and device-service interfaces
assets/
  icon/                 # launcher and splash source PNGs
test/
integration_test/
android/
ios/
.github/workflows/
docs/
```

## Team workflow

- Create a feature branch per independently reviewable change.
- Keep commits small and use imperative messages such as `feat: add transaction review sheet`.
- Open pull requests into the default branch; require CI before merge.
- Keep each feature's View, ViewModel, Model, and Service changes together in the same branch.
- Use `git worktree` only when parallel feature work makes it useful, and keep each worktree on its own branch.

## CI/CD

GitHub Actions should run `flutter pub get`, `dart format --set-exit-if-changed lib test`, `flutter analyze`, and `flutter test --coverage` for pushes and pull requests. Add separate build jobs for the `development`, `staging`, and `production` flavors once platform signing and scheme setup are complete. For iOS distribution, Codemagic may build and publish TestFlight artifacts for the `staging` or `production` flavor after the team configures Apple credentials.

## Platform permission notes

- Request notification, microphone, and biometric permissions just before the related feature needs them.
- Android SMS permissions must be justified, optional, and tested on real hardware and current Android versions.
- iOS does not receive a general SMS reading permission; keep that automation isolated to Android.
