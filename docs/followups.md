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
