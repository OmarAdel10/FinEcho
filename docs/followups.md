# Follow-ups

## Budget persistence

- Wire `SqfliteBudgetRepository` into application DI when encrypted database
  bootstrap is implemented.
- Remove the temporary budget in-memory repository registration at that point
  so budgets and categories share one persisted source of truth.

## Budget identity and currency

- Use a collision-resistant identifier generator instead of the timestamp-based
  budget ID fallback.
- Add currency-aware display metadata instead of the current USD-only budget
  amount formatting.

## Analytics persistence

- Wire `SqfliteAnalyticsRepository` into application DI when the encrypted
  database bootstrap lands, replacing the temporary in-memory registration.

## Analytics presentation

- Extract the minor-unit amount formatter duplicated across the transactions,
  budget, and analytics widget files.
- Improve the category ring palette: colors repeat beyond three categories and
  the soft stone slice has low contrast on light surfaces.
- Verify the in-memory analytics category tie-break matches the SQLite BINARY
  collation for non-ASCII category identifiers.

## Analytics review round 2

Deferred during the round-two review; tracked in Plane:

- Support multiple currencies in analytics aggregation (FINECHO-8).
- Make budget warning thresholds configurable (FINECHO-9).
- Add period totals to the home dashboard (FINECHO-10).
- Protect financial screens with FLAG_SECURE and lock on pause (FINECHO-11);
  resolved in the security hardening branch.
- Add a navigation shell entry for statistics (FINECHO-12).
- Identify recurring charges by payee instead of an amount bucket (FINECHO-13).
- Push analytics aggregation into repository queries (FINECHO-14).
- Clear analytics state when the app locks (FINECHO-15).
- Add analytics screenshots to the README (FINECHO-16).
- Extract the shared minor-unit currency formatter (FINECHO-5).
- Use largest-remainder rounding for category legend percentages (FINECHO-18).
- Cover the remaining analytics boundary branches with tests (FINECHO-19).
- Add an income breakdown by category to analytics (FINECHO-20).

## Analytics review round 3

Fixed:

- Anchor-based budget windows now keep clamped months contiguous, so spending
  around an anchor day of 29-31 is never orphaned.
- Added a Statistics action to the transactions app bar so the screen is
  reachable without a deep link.
- Skipped the previous-period query when a period has just started, avoiding an
  empty range rejected by the SQLite repository.
- Account share semantics now announce share of total instead of share of the
  largest row; bar lengths still scale to the largest row.
- The dashboard reloads on every mount so aggregates reflect transactions
  recorded elsewhere.
- Documented the UTC calendar policy in the analytics service.
- Reset a queued period when the current period is re-selected, asserted
  non-negative month offsets, and limited failure logging to debug builds.

Deferred; tracked in Plane:

- Convert analytics calendar boundaries from UTC to device-local (FINECHO-22).
- Add ring painter output and golden tests (FINECHO-21).
- Distinguish zero previous spend from no comparison (FINECHO-23).
- The round-two items FINECHO-8, FINECHO-9, and FINECHO-20 remain open;
  model-equality isolation is covered by FINECHO-19.

## Analytics review round 4

The three-round fix cap was reached; the coverage review passed with no untested
changed units. A final approved batch fixed:

- First-day forecast now clamps its elapsed denominator to one day, so a small
  fraction cannot project an absurd month total (FINECHO-24).
- Lapsed recurring charges are no longer listed once the current month has no
  occurrence.
- A zero-allocation budget with spending now reports a full used ratio.
- The category ring announces every slice name and amount.
- The DI test captures one clock reading before seeding its transaction.
- Budget warning and exceeded states now render distinctly, with visible labels
  and level-aware semantics (FINECHO-26).
- The statistics controls stay visible while a period switch is loading, with
  an inline spinner instead of a blank screen (FINECHO-26).
- Added a 320 dp / 1.5x text-scale layout test and aligned the screen fixture
  totals with its seeded transactions (FINECHO-26).

Deferred; tracked in Plane:

- FINECHO-27 guard PIN setup against a relock race.
- FINECHO-28 move the lifecycle observer to app scope.
- FINECHO-30 harden the PIN lockout window; the verifier derivation part is
  done (PBKDF2-HMAC-SHA256 with a format version).
- FINECHO-31 verify `FLAG_SECURE` on a device.
- FINECHO-32 erase persisted financial data or require a device credential for
  recovery reset once the SQLCipher database is wired.
- FINECHO-33 tighten the remaining security test clarity gaps: derive the
  lockout window from a fixed clock and assert the secure-storage payload
  guards separately from the JSON parse errors.
- FINECHO-34 either implement biometric unlock or remove the promise from the
  security setup screen, `docs/PRD.md`, and `docs/USER_FLOW.md`; the switch is
  live in the UI but no biometric package is wired.
- FINECHO-36 render a continue action when onboarding resumes at the security
  setup step; the page is currently blank with a no-op primary button.
- FINECHO-38 derive the PIN verifier off the platform isolate; the current
  derivation blocks the UI thread for roughly 300 ms per attempt.
- FINECHO-39 render a splash while the startup security state loads; the
  native launch screen is shown for up to the load timeout.
- FINECHO-41 persist the onboarding snapshot: the production graph still uses
  the in-memory onboarding repository, so the onboarding progress and the
  security-setup step are lost when the app restarts.
- FINECHO-42 tighten the security test realism gaps: the credential fake still
  compares plaintext, a few assertions compare a value with itself, and the
  lockout test depends on the wall clock.
- FINECHO-43 clean up the security setup screen seams: the setup warning
  duplicates the security error snackbar and the public PIN controller has no
  consumer.
- FINECHO-44 scope the unauthenticated `Erase app lock` action to the state
  where the verifier is genuinely unreadable; a storage fault during PIN
  verification currently offers the same unauthenticated erase.
- FINECHO-15 clear cached analytics state on lock.

## Security hardening

Fixed:

- Persisted lock state is loaded before routing: configured users start at the
  lock screen, and onboarding/security setup redirect to the protected area.
  This closes the cold-start gap in FINECHO-25.
- Secure-storage read and decode failures show a recovery screen with retry and
  an explicitly destructive `Erase app lock` action instead of an infinite
  spinner. Reset attempts clearing the verifier and metadata independently; if
  both fail, the screen directs the user to clear app data in system settings.
  A successful erase returns the app to onboarding so the lock can be set up
  again, and a failed reload asks the user to try again instead of wiping the
  app. Every recovery path that ends without a configured lock, including a
  retry that succeeds against an empty store, routes back to onboarding, so the
  protected area is never left reachable without a way to set the lock up.
- The erase runs in a dedicated `resetting` state, so the progress indicator
  depends on the operation in flight instead of the persisted lock metadata.
- A stored verifier without lock metadata fails closed and repairs the metadata.
  Configured metadata without a readable verifier enters the recovery screen.
  A metadata repair that cannot be persisted still leaves the app locked.
  PIN setup refuses to overwrite an existing verifier and reports when a setup
  rollback also fails.
- Startup security loading is bounded by a timeout, the load-before-router
  composition is covered by a production-graph test, and the bound is
  regression-tested.
- Android secure storage uses the current `flutter_secure_storage` backend,
  pinned to `11.2.0`: the payload is encrypted with AES-GCM and the key is
  wrapped by the Android keystore. The legacy encrypted shared preferences
  path is gone, and the plugin no longer erases the stored values when the
  keystore reports an error, so a keystore failure surfaces on the recovery
  screen instead of silently removing the app lock. This closes FINECHO-37
  and FINECHO-40.
- The persisted security state uses a versioned codec, so a payload written in
  another format is rejected instead of being misread (FINECHO-29).
- A corrupt PIN verifier payload is rejected while decoding, so it reaches the
  recovery screen with a deliberate reset instead of locking the user out of a
  verifier that never matches (FINECHO-35).
- Cloud backup and Android 12+ device-to-device transfer exclude app data
  through `dataExtractionRules`, with `allowBackup=false` and
  `fullBackupContent=false` for older versions.
- The security gate relocks on `AppLifecycleState.paused`; an in-flight PIN
  verification cannot complete an unlock after the app is paused, and the PIN
  field clears on relock.
- Android applies `FLAG_SECURE` app-wide so screens are excluded from
  screenshots and recent-app previews.
- The shared PIN hasher uses a constant-time verifier comparison.
- Secure repositories, hasher, lifecycle relock, recovery flow, startup
  routing, bootstrap, and DI paths are covered by tests.
- The PIN verifier is derived with PBKDF2-HMAC-SHA256 (100,000 iterations) and
  stored with an explicit format version. Verifiers written by the earlier
  single-round format are still verified against the legacy derivation, so
  existing installations keep working. This closes the derivation half of
  FINECHO-30.
- The onboarding snapshot is loaded at startup next to the security state, and
  the onboarding flow advances to the security-setup step before opening the
  security screen, so the PIN can actually be set up and onboarding can be
  completed after it.
- The dependency graph uses platform secure storage by default; the in-memory
  graph is an explicit opt-in for tests, so a new entry point cannot silently
  fall back to a non-persistent lock.
- The entrypoint composes through `buildApp()` and is covered by a startup test
  that mounts the application against a mocked secure-storage channel, so the
  real startup order is executed rather than only described.
- `SecurityService` has a dedicated unit test file covering every load branch,
  both one-sided reset failures, and the lockout bookkeeping.
- A second PIN setup is ignored while one is already in flight, a reload keeps
  an unlocked app unlocked, and a pause during PIN verification no longer
  clears the failed-attempt streak.

The recovery `Erase app lock` action is intentionally unauthenticated because
the stored verifier may be unreadable; it exists only to clear local data and
restore access. When persisted financial data lands, the action must also erase
that data or require a device credential (FINECHO-32).

Moving to the current secure-storage backend changes the store that holds the
verifier, so a device that ran a pre-release build with the encrypted shared
preferences backend cannot read the stored verifier any more. The current
backend does not migrate the old entries, and a missing entry reads as an
empty value rather than an error, so the app asks the store whether it still
holds entries this build cannot read before it reads anything, and treats a
check that cannot run as unreadable as well. When such data is present the app
fails closed into the recovery screen instead of treating the missing values as
a fresh install, and the deliberate `Erase app lock` action clears the lock so
it can be set up again. The state codec still reads a payload written before
the codec was versioned. No released version is affected.
