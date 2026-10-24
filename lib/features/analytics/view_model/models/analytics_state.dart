import 'package:finecho/core/models/analytics_period.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_dashboard.dart';
import 'package:flutter/foundation.dart';

/// The lifecycle of the analytics ViewModel.
enum AnalyticsStatus {
  /// The dashboard is being derived from local history.
  loading,

  /// The dashboard is ready to render.
  ready,

  /// The last load failed.
  failure,
}

/// Immutable state rendered by the statistics screen.
@immutable
class AnalyticsState {
  /// Creates an immutable analytics state.
  const new({
    this.status = AnalyticsStatus.loading,
    this.period = AnalyticsPeriod.month,
    this.dashboard,
    this.errorMessage,
  });

  /// The current ViewModel lifecycle status.
  final AnalyticsStatus status;

  /// The selected analytics period.
  final AnalyticsPeriod period;

  /// The loaded dashboard, when available.
  final AnalyticsDashboard? dashboard;

  /// A user-facing error, when present.
  final String? errorMessage;

  /// Returns a copy with the given fields replaced.
  ///
  /// The loaded [dashboard] is carried over so refreshes and failed reloads
  /// keep showing the last good data. Pass `clearErrorMessage: true` to drop
  /// a stale error.
  AnalyticsState copyWith({
    AnalyticsStatus? status,
    AnalyticsPeriod? period,
    AnalyticsDashboard? dashboard,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AnalyticsState(
      status: status ?? this.status,
      period: period ?? this.period,
      dashboard: dashboard ?? this.dashboard,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
