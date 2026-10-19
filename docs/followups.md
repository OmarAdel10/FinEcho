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
- Protect financial screens with FLAG_SECURE and lock on pause (FINECHO-11).
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
