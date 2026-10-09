# FinEcho Performance Guidelines

## Rendering

- Scope rebuilds with immutable BLoC/Cubit state and selective `BlocBuilder` or `BlocSelector` usage.
- Keep ViewModels free of widget imports and expensive work; delegate I/O and computation to feature services.
- Target smooth 60 FPS interaction; profile on representative lower-end Android devices.
- Avoid synchronous database, parsing, model-loading, or export work on the UI isolate.
- Paginate transaction lists and use lazy list widgets.

## Background work

- Run speech inference, historical SMS parsing, large exports, and statistical recomputation in feature services outside the main UI isolate.
- Transfer compact data objects between isolates; do not repeatedly serialize large message batches.
- Initialize the speech model lazily and dispose or release it when memory pressure requires it.
- Benchmark transcription latency, peak RAM, and battery impact on supported devices before selecting a model.

## Database

- Use parameterized statements, foreign keys, migrations, and indexes for transaction timestamp, account ID, and category ID.
- Enable WAL only after validating the chosen encrypted SQLite library supports it correctly.
- Batch imports in explicit transactions and make processing restart-safe.
- Query aggregates by date range and cache only invalidatable summaries.

## Notifications and automation

- Deduplicate parsed messages and throttle notification bursts to one useful summary or alert per batch.
- Keep notification payloads small and free of sensitive raw message content.
- Measure end-to-end parse-to-notification latency on physical devices.

## Verification metrics

| Area | Measure | Target direction |
|---|---|---|
| UI | frame timing during scroll and navigation | no sustained jank |
| Database | common dashboard and transaction queries | indexed and responsive at 10,000 records |
| STT | end-of-speech to editable draft | fast enough for conversational entry |
| Memory | idle and active STT peak RAM | stays within target-device budget |
| SMS import | messages processed per batch and duplicate rate | bounded, correct, restart-safe |
| Battery | background automation impact | minimal and user-controllable |

Use Flutter DevTools, Android Studio profiler, integration tests, and repeatable device test scripts to establish actual numeric baselines before release.

## Flavor measurement policy

- Use the `development` flavor for correctness checks and DevTools smoke inspection only.
- Use the `staging` flavor in `profile` or `release` mode for repeatable baselines and regression tracking.
- Use the `production` release flavor for target-device acceptance.
- Never report debug-mode frame timing or memory as the release baseline.
