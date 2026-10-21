# FinEcho User Flow

## Navigation map

```text
Splash -> Welcome -> Onboarding (first run) -> Lock/Profile Setup -> Home
Splash -> Lock -> Home
Home <-> Accounts | Statistics | Settings
Home -> Voice Review -> Confirm Transaction -> Home
Home -> Add Transaction -> Confirm Transaction -> Home
Notification -> Lock (if needed) -> Accounts Card Link or Budget Detail
```

## Onboarding and access

1. User opens FinEcho.
2. The native animated splash initializes local services without blocking the animation unnecessarily and uses `assets/icon/splash_mark_1024.png` as its native mark.
3. First-time users see the welcome screen, then three onboarding pages, then create a local profile and set a six-digit app-lock PIN. Device biometrics are planned and are not implemented yet (FINECHO-34).
4. Returning users unlock with the app-lock PIN.
5. On failure, the user receives a clear retry path; no financial data is displayed before unlock.

## Environment indicator flow

1. Startup resolves the active flavor—`development`, `staging`, or `production`—and an app-level ViewModel exposes immutable `EnvironmentState`.
2. Development and staging builds render a persistent badge in the global app chrome.
3. Tapping the badge opens a concise explanation of that environment’s data and diagnostics.
4. Production renders no badge.

## Manual and voice transaction entry

1. From Home, the user taps add or long-presses the voice action.
2. Manual entry opens a structured transaction sheet. Voice entry opens a recording state and performs local transcription.
3. FinEcho extracts amount, payee, category, and account into an editable draft.
4. The user confirms, edits, saves as uncategorized, or cancels.
5. A confirmed transaction updates the relevant account, budget, recent list, and statistics.

## Android SMS and card linking

1. In Settings or Accounts, the user learns why SMS access is requested and may grant or decline it.
2. A locally received supported SMS is scraped against enabled sender rules.
3. If its card digits map to an account, the app creates a reviewable transaction according to the user preference.
4. If no mapping exists, a local notification opens an account-linking sheet with masked digits and sender details.
5. Permission denial preserves manual entry and shows instructions for enabling automation later.

## Budget alert flow

1. A categorized transaction changes current-period category spending.
2. When a threshold is crossed, FinEcho creates one throttled local notification.
3. Tapping it opens the category budget detail after unlock.
4. The user can change the amount, snooze alerts, review transactions, or keep the plan unchanged.

## UI and motion flow

1. The app shell uses animated navigation transitions that are short, consistent, and interruptible.
2. Primary buttons use a small press-scale animation and remain at least 44px by 44px.
3. Dialogs and bottom sheets use simple fade-and-scale open/close transitions.
4. The voice feature opens a live waveform overlay, then transitions into a thinking/analyzing dialog until the editable draft is ready.
5. Search controls expand from an icon into a text field with a compact “exploding” transition.
6. Confirmations, permission changes, and automation toggles use dismissible top snackbars.
7. All motion respects reduced-motion settings and never hides a balance, amount, or required action.

## Exception principles

- Explain permission denials in the feature context; never dead-end the user.
- Keep low-confidence automation visibly distinct from confirmed data.
- If parsing, STT, or database access fails, preserve the draft and offer manual completion.
- Ensure notification deep links validate their payloads and degrade to Home if the target no longer exists.
- Map each flow to one feature ViewModel so screen behavior and state transitions remain testable and consistent with the MVVM/BLoC architecture.
