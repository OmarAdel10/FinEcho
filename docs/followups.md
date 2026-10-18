# Follow-ups

## Budget persistence

- Wire `SqfliteBudgetRepository` into application DI when encrypted database
  bootstrap is implemented.
- Remove the temporary budget in-memory repository registration at that point
  so budgets and categories share one persisted source of truth.
