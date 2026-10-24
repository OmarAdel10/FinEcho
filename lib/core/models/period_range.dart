import 'package:finecho/core/models/analytics_period.dart';

/// Returns the UTC range of the local-calendar [period] containing [nowUtc].
///
/// The returned record holds the inclusive start and exclusive end in UTC.
/// Boundaries are computed on the wall clock of [localUtcOffset], so a month
/// always starts at local midnight even when that midnight falls on a
/// different UTC day.
(DateTime, DateTime) periodRange(
  AnalyticsPeriod period,
  DateTime nowUtc,
  Duration localUtcOffset,
) {
  final nowLocal = nowUtc.add(localUtcOffset);
  switch (period) {
    case AnalyticsPeriod.week:
      final start = _startOfWeek(nowLocal);
      return (
        start.subtract(localUtcOffset),
        start.add(const Duration(days: 7)).subtract(localUtcOffset),
      );
    case AnalyticsPeriod.month:
      return (
        DateTime.utc(nowLocal.year, nowLocal.month).subtract(localUtcOffset),
        DateTime.utc(
          nowLocal.year,
          nowLocal.month + 1,
        ).subtract(localUtcOffset),
      );
    case AnalyticsPeriod.year:
      return (
        DateTime.utc(nowLocal.year).subtract(localUtcOffset),
        DateTime.utc(nowLocal.year + 1).subtract(localUtcOffset),
      );
  }
}

/// Returns the UTC range of the local-calendar [period] before the one
/// containing [nowUtc].
///
/// The previous period abuts the current one, so its end equals the current
/// period's start.
(DateTime, DateTime) previousPeriodRange(
  AnalyticsPeriod period,
  DateTime nowUtc,
  Duration localUtcOffset,
) {
  final current = periodRange(period, nowUtc, localUtcOffset);
  switch (period) {
    case AnalyticsPeriod.week:
      return (current.$1.subtract(const Duration(days: 7)), current.$1);
    case AnalyticsPeriod.month:
      final localStart = current.$1.add(localUtcOffset);
      return (
        DateTime.utc(
          localStart.year,
          localStart.month - 1,
        ).subtract(localUtcOffset),
        current.$1,
      );
    case AnalyticsPeriod.year:
      final localStart = current.$1.add(localUtcOffset);
      return (
        DateTime.utc(localStart.year - 1).subtract(localUtcOffset),
        current.$1,
      );
  }
}

DateTime _startOfWeek(DateTime nowLocal) {
  final date = DateTime.utc(nowLocal.year, nowLocal.month, nowLocal.day);
  return date.subtract(Duration(days: date.weekday - DateTime.monday));
}
