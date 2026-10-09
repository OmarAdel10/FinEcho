# FinEcho Google Stitch Design Prompt

Design a complete Flutter mobile app called **FinEcho**, an offline-first personal finance tracker. The experience should feel calm, precise, private, and exceptionally easy to use. Follow the supplied Cohere-inspired design direction: editorial white space, deep green-black product areas, soft mineral surfaces, rounded media cards, tight display typography, and restrained UI chrome. Do not reproduce a website; adapt the visual language for touch-first mobile finance.

## Visual system

- Canvas: `#FFFFFF`; ink: `#212121`; near-black: `#17171C`; deep green: `#003C33`; dark navy: `#071829`; soft stone: `#EEECE7`; pale green: `#EDFCE9`; blue: `#1863DC`; coral: `#FF7759`; dividers: `#D9D9DD`.
- Use a display font resembling Space Grotesk/CohereText for large headlines, Inter/system sans for UI copy, and a mono face for balances, dates, card digits, and technical labels.
- Use 8pt spacing. Cards have 16px or 22px radii. Primary CTAs use a 32px pill radius. Keep shadows nearly absent; use surface contrast and thin rules instead.
- Include clear 44px minimum touch targets, visible focus states, semantic chart labels, and high contrast.

## Brand and icon assets

- App icon source: `assets/icon/app_icon_dark_1024.png`.
- Android adaptive layers: `assets/icon/adaptive_background_1024.png` and `assets/icon/adaptive_foreground_1024.png`.
- Android 13+ themed icon layer: `assets/icon/monochrome_1024.png`.
- Native splash mark: `assets/icon/splash_mark_1024.png`.
- Keep the receipt-strip “F” mark, coral coin dot, deep-green/navy palette, and white splash canvas consistent across marketing, launcher, and in-app visuals.

## Required mobile screens

1. **Animated splash**: white canvas, centered FinEcho geometric echo/ledger mark, gentle pulse, mono label `FINECHO // PRIVATE ON DEVICE`.
2. **Onboarding 1 - Privacy**: `01/03` marker, headline `Your money stays with you`, sparse line illustration, next CTA.
3. **Onboarding 2 - Voice**: `02/03`, a deep-green card showing a waveform and local transcription, headline `Say it. We log it locally.`
4. **Onboarding 3 - Automation**: `03/03`, SMS text transforming into a categorized ledger row, explain that Android SMS automation is optional.
5. **Lock/profile setup**: biometric enablement, six-digit PIN fallback, no clutter.
6. **Home**: greeting and settings icon; soft-stone net-worth card; income/expense metrics; deep-green hold-to-speak action; recent transactions as thin-rule rows with coral category tags and mono amounts; bottom navigation.
7. **Add/review transaction**: form or bottom sheet with amount, category, account, date, note, confidence badge, and a single unmistakable confirm action.
8. **Accounts**: dark-navy linked card cards with masked digits and parsing status; soft-stone cash/wallet cards; sender-pattern linking sheet.
9. **Statistics**: spending/income/patterns segmented control; readable bar and ring charts; recurring-payment and forecast panels; budget status with coral used only for warning states.
10. **Settings/profile**: grouped sections for security, Android automation, notifications, offline speech engine, exports, and data management. Show permission status plainly.

## Environment indicator

- Render `DEVELOPMENT` and `STAGING` as a compact mono badge in the global app chrome; omit the badge for `production`.
- Keep it high contrast, 8pt-aligned, and never overlapping balances, CTAs, or chart labels.
- Use the same badge treatment in light and dark surfaces so the active flavor remains obvious without interrupting the finance task.

## Interaction direction

The home screen is the primary daily task surface. Make manual entry, voice entry, and reviewing automated drafts fast. Use plain-language permission explanations. Present uncertainty with confidence labels and allow a quick correction. Never let a chart, animation, or dark panel obscure a financial amount or a required action. Produce phone-sized screen references with connected navigation states for light and dark accent surfaces.

Design each screen as an MVVM View: keep visual states explicit and straightforward to bind to a BLoC/Cubit ViewModel, while leaving persistence and platform behavior to feature Services.
