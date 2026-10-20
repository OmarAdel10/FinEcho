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
- FINECHO-29 version the secure-storage security JSON codec.
- FINECHO-30 harden PIN lockout and verifier derivation.
- FINECHO-31 verify `FLAG_SECURE` on a device.
- FINECHO-32 erase persisted financial data or require a device credential for
  recovery reset once the SQLCipher database is wired.
- FINECHO-33 tighten the remaining security test clarity gaps: derive the
  lockout window from a fixed clock, assert the secure-storage payload guards
  separately from the JSON parse errors, and cover `main()` directly.
- FINECHO-15 clear cached analytics state on lock.

## Security hardening

Fixed:

- Persisted lock state is loaded before routing: configured users start at the
  lock screen, and onboarding/security setup redirect to the protected area.
  This closes the cold-start gap in FINECHO-25.
- Secure-storage read and decode failures show a recovery screen with retry and
  an explicitly destructive `Erase app data` action instead of an infinite
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
- Android secure storage uses encrypted shared preferences; cloud backup and
  Android 12+ device-to-device transfer exclude app data through
  `dataExtractionRules`, with `allowBackup=false` and
  `fullBackupContent=false` for older versions.
- The security gate relocks on `AppLifecycleState.paused`; an in-flight PIN
  verification cannot complete an unlock after the app is paused, and the PIN
  field clears on relock.
- Android applies `FLAG_SECURE` app-wide so screens are excluded from
  screenshots and recent-app previews.
- The shared PIN hasher uses a constant-time verifier comparison.
- Secure repositories, hasher, lifecycle relock, recovery flow, startup
  routing, bootstrap, and DI paths are covered by tests.

The recovery `Erase app data` action is intentionally unauthenticated because
the stored verifier may be unreadable; it exists only to clear local data and
restore access. When persisted financial data lands, the action must also erase
that data or require a device credential (FINECHO-32).
