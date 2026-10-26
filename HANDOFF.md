# FinEcho — Handoff for Opencode Implementation

**Generated:** 2026-10-19T17:48:00Z
**Project:** `/mnt/ALL/Flutter Projects/FinEcho`
**Branch:** `development` (clean working tree)
**HEAD:** `7c50b22` — `✨ feat(budget): list, create/edit, and delete with Cubit state management (#9)`

## 📋 Project Overview

**App:** FinEcho — offline-first personal-finance Flutter app
**Package:** `finecho` (pubspec.yaml)
**Architecture:** MVVM/BLoC with `flutter_bloc ^9.1.1`, `bloc ^9.0.0`, `get_it ^9.3.0`
**Routing:** `go_router ^18.0.2`
**Database:** `sqflite_sqlcipher ^3.4.1` (encrypted SQLite)
**DI:** GetIt service locator (`lib/app/di/service_locator.dart`)
**State:** Cubit/ViewModel pattern (NOT clean architecture layer names)
**Android SMS scraping:** Android-only (iOS has no general SMS inbox API)

## ✅ Already Implemented & Merged to `development`

All of the following are in `development` HEAD (`7c50b22`). Do **NOT** re-implement.

| PR | Feature                                                     | Commit      | Status        |
| -- | ----------------------------------------------------------- | ----------- | ------------- |
| #1 | Core infrastructure + CI/CD foundation                      | `ef485cc` | Merged        |
| #2 | Phase 1 core infrastructure (DI, routing, SQLCipher, repos) | `8089e5a` | Merged        |
| #4 | Onboarding — first-run and security setup                  | `43fccdf` | Merged        |
| #5 | Security — PIN app lock and unlock flow                    | `d49d641` | Merged        |
| #6 | Transaction — manual entry, home ledger, transaction mgmt  | `f780154` | Merged        |
| #7 | CI/CD workflows — coverage upload, tag-based releases      | `4d6028a` | Merged        |
| #8 | Account — archived field, schema v2 migration              | `ad93ad5` | Merged        |
| #9 | Budget — list, create/edit, delete with Cubit              | `7c50b22` | Merged (HEAD) |

### What exists in `lib/`

**Core (shared):**

- `lib/app/bootstrap/app_bootstrap.dart` — App bootstrap
- `lib/app/bootstrap/fin_echo_app.dart` — FinEchoApp widget
- `lib/app/di/service_locator.dart` — GetIt DI registration
- `lib/app/environment/environment.dart` — Environment config (dev/staging/prod)
- `lib/app/router/app_router.dart` — GoRouter configuration
- `lib/app/router/screens/placeholder_screen.dart` — Placeholder for unimplemented routes
- `lib/app/theme/fin_echo_theme.dart` — Light/dark themes
- `lib/core/database/app_database.dart` — SQLCipher database
- `lib/core/database/migrations/app_migrations.dart` — Schema migrations
- `lib/core/database/schema/app_schema.dart` — Database schema
- `lib/core/repositories/contracts/*.dart` — 10 repository contracts (Account, Transaction, Budget, Category, Analytics, Speech, SMS, Notification, Settings, Security)
- `lib/core/repositories/implementations/*.dart` — SQLite + in-memory implementations
- `lib/core/models/*.dart` — Data models (Account, Transaction, Budget, Category, AnalyticsSummary, etc.)

**Implemented features:**

- `lib/features/budget/` — Cubit, service, state, screens, widgets, tests
- `lib/features/onboarding/` — Welcome, onboarding, security setup screens
- `lib/features/security/` — PIN lock, security gate, cubit
- `lib/features/transactions/` — Transaction screen, cubit, service, widgets
- `lib/features/account/` — Account feature (in dependencies)

### What exists in `test/`

Tests exist for: budget, onboarding, security, transactions, core repositories, core database, core models, DI service locator, app router (budget/security/transactions), widget_test.

## ⏳ What Remains (Per IMPLEMENTATION_PLAN.md)

### Phase 2 — Remaining Features (one branch per feature, PR-gated)

**Feature order (MANDATORY per plan):**

1. ✅ Onboarding (#4) — merged
2. ✅ Security (#5) — merged
3. ✅ Transaction (#6) — merged
4. ✅ Account (#8) — merged
5. ✅ Budget (#9) — merged (HEAD)
6. ⏳ **Analytics** — NEXT
7. ⏳ Speech-to-text
8. ⏳ SMS ingestion
9. ⏳ Notifications
10. ⏳ Settings

### Phase 3 — Cross-Cutting (parallel PRs after settings)

- Localization (English/Arabic, RTL)
- Animations (thinking dots, waveform, border beam, search explode)
- Splash and icons (native splash + adaptive app icons)

### Phase 4 — Shorebird

- Shorebird OTA setup

### Phase 5 — CI/CD Workflows

**Already merged** (#7). Workflows exist in `.github/workflows/`:

- `ci.yml`
- `cd.yml`
- `label.yml`
- Labeler config: `.github/labeler.yml`

## 📝 Feature Specs Available

| Spec                    | Path                                |
| ----------------------- | ----------------------------------- |
| Architecture            | `docs/ARCHITECTURE.md`            |
| Development Environment | `docs/DEVELOPMENT_ENVIRONMENT.md` |
| Design Prompt           | `docs/DESIGN_PROMPT.md`           |
| Performance Guidelines  | `docs/PERFORMANCE_GUIDELINES.md`  |
| PRD                     | `docs/PRd.md`                     |
| User Flow               | `docs/USER_FLOW.md`               |
| Implementation Plan     | `IMPLEMENTATION_PLAN.md`          |
| Follow-ups              | `docs/followups.md`               |

### Key follow-up items (from `docs/followups.md`):

1. **Budget persistence:** Wire `SqfliteBudgetRepository` into application DI when encrypted database bootstrap is implemented. Remove temporary in-memory budget repo registration.
2. **Budget identity and currency:** Use collision-resistant ID generator instead of timestamp-based budget ID fallback. Add currency-aware display metadata.

## 🔄 Implement-Review-Ship Workflow (MANDATORY)

Per the `implement-review-ship` skill, follow this exact cycle for **each** feature:

### Step 1 — Branch from `development`

```bash
git fetch origin
git checkout development
git pull origin development
git checkout -b feature/{kebab-case-name}
```

### Step 2 — Implement

- Follow specs compliance, TDD, scope discipline
- Commit via `emoji-commit` skill (emoji conventional, multiple `-m`, no double quotes)
- **FAST gate before every commit:** `dart format`, `flutter analyze`, no `debugPrint`
- Scope: only current feature's domain

### Step 3 — Review round (fresh, context-free, read-only)

Dispatch BOTH reviewers in parallel, each as a NEW session:

1. `agent: qa-post-implementation` — QA review against `git diff origin/development...HEAD`
2. `agent: general` — `test-coverage-analysis` skill against branch diff

Pass ONLY minimal context: repo path, branch, base ref, one-line task description.

### Step 4 — Gate

ALL three must pass:

- **No bugs:** Zero Critical, Zero High
- **Quality score > 90:** `score = 100 − 25×Critical − 10×High − 5×Medium − 1×Low` (Info = 0). Requires zero Critical/High/Medium AND at most 9 Low. Strictly > 90 — exactly 90 fails.
- **Coverage:** Zero untested changed units.

### Step 5 — Fix loop (if gate fails)

- Parent writes fix plan from review report's Decision Matrix
- Parent implements fixes; commits via emoji-commit + FAST gate
- Dispatch BRAND-NEW reviewers (never reuse)
- Cap: 3 fix rounds. Still failing → STOP, surface reports, human checkpoint.

### Step 6 — Open PR (don't merge)

```bash
gh pr create --base development \
  --title "feat: {feature name} — {summary}" \
  --body "$(cat <<'EOF'
{Comprehensive body with diagrams, flowcharts, test summary}
EOF
)"
```

**Never merge.** Report PR URL and wait for user approval.

### Step 7 — Repeat for next feature

## 📁 Key File Paths (absolute)

- Project root: `/mnt/ALL/Flutter Projects/FinEcho`
- Implementation plan: `/mnt/ALL/Flutter Projects/FinEcho/IMPLEMENTATION_PLAN.md`
- Handoff file: `/mnt/ALL/Flutter Projects/FinEcho/HANDOFF.md`
- DI registration: `/mnt/ALL/Flutter Projects/FinEcho/lib/app/di/service_locator.dart`
- App router: `/mnt/ALL/Flutter Projects/FinEcho/lib/app/router/app_router.dart`
- Theme: `/mnt/ALL/Flutter Projects/FinEcho/lib/app/theme/fin_echo_theme.dart`
- Database: `/mnt/ALL/Flutter Projects/FinEcho/lib/core/database/`
- Repository contracts: `/mnt/ALL/Flutter Projects/FinEcho/lib/core/repositories/contracts/`
- Repository implementations: `/mnt/ALL/Flutter Projects/FinEcho/lib/core/repositories/implementations/`
- Models: `/mnt/ALL/Flutter Projects/FinEcho/lib/core/models/`
- Features: `/mnt/ALL/Flutter Projects/FinEcho/lib/features/`
- Tests: `/mnt/ALL/Flutter Projects/FinEcho/test/`
- GitHub workflows: `/mnt/ALL/Flutter Projects/FinEcho/.github/workflows/`
- Labeler config: `/mnt/ALL/Flutter Projects/FinEcho/.github/labeler.yml`

## 📦 Dependencies (pubspec.yaml)

**Runtime:** bloc ^9.0.0, crypto ^3.0.7, cupertino_icons ^1.0.8, flutter_bloc ^9.1.1, flutter_intl ^0.0.1, get_it ^9.3.0, go_router ^18.0.2, lottie ^3.6.1, material_ui ^1.6.0, pinput ^7.0.0, sqflite_sqlcipher ^3.4.1, another_flutter_splash_screen ^1.2.1

**Dev:** build_runner ^2.16.2, flutter_launcher_icons ^0.14.4, flutter_native_splash ^2.4.8, sqflite_common_ffi ^2.3.6, very_good_analysis ^11.0.0

## 🎯 Naming Conventions

- **App name:** "FinEcho" (never "SiloSpend")
- **Architecture terms:** MVVM, BLoC, Cubit, flutter_bloc (NOT clean architecture layers)
- **Commits:** emoji conventional (e.g., `:sparkles:`, `:bug:`, `:white_check_mark:`, `:memo:`)
- **Branches:** `feature/{kebab-case-name}` (e.g., `feature/analytics`)
- **SMS scraping:** Android-only; iOS has no general SMS inbox API

## 🔑 Repository Contracts (10 total)

All contracts exist in `lib/core/repositories/contracts/`:

1. `account_repository.dart`
2. `analytics_repository.dart`
3. `budget_repository.dart`
4. `category_repository.dart`
5. `notification_repository.dart`
6. `security_repository.dart`
7. `settings_repository.dart`
8. `sms_ingestion_repository.dart`
9. `speech_repository.dart`
10. `transaction_repository.dart`

## 📊 Models Available (for analytics feature)

- `lib/core/models/analytics_summary.dart` — Analytics summary model already exists
- `lib/core/models/category_total.dart` — Category total model already exists
- `lib/core/repositories/contracts/analytics_repository.dart` — Analytics contract already exists
- `lib/core/repositories/implementations/sqflite_analytics_repository.dart` — SQLite analytics impl already exists

## ⚠️ User Constraints / Preferences

- No `/tmp` for output, scratch files, logs, or redirects
- No env vars workarounds
- No sandbox directory workarounds
- Commit style: emoji conventional, multiple `-m` flags, no double quotes
- User opens PRs manually — do NOT use `gh pr create`
- Git and `gh` commands work once `.git` is remounted read-write
- Enforce MVVM with BLoC/Cubit (not clean architecture naming)
- Android-only SMS scraping (not relevant to remaining features)
- Proposal revisions: remove CI/CD talk, remove first course/section and deadline table, four two-week sprints targeting early December, fit one page

## 🏁 Resume-from-here

1. `git checkout development && git pull origin development`
3. `git checkout -b feature/analytics`
4. Implement analytics feature following implement-review-ship workflow
5. Create PR for analytics (don't merge)
6. Wait for user merge, then proceed to speech-to-text, sms-ingestion, notifications, settings
7. Then Phase 3 (parallel PRs), Phase 4 (Shorebird), Phase 6 (verification & delivery)
