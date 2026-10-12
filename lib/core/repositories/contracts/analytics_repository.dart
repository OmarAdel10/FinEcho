import 'package:finecho/core/models/analytics_summary.dart';

/// Reads derived FinEcho analytics from persisted transactions.
abstract interface class AnalyticsRepository {
  /// Returns analytics for the half-open UTC range [startUtc] to [endUtc].
  ///
  /// Transfers are excluded. Uncategorized expenses are returned with a `null`
  /// category id and name rather than a synthetic `'uncategorized'` key.
  Future<AnalyticsSummary> summaryForRange({
    required DateTime startUtc,
    required DateTime endUtc,
  });
}
