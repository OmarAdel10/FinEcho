/// Raw per-account income and expense totals for a UTC range.
///
/// Account names are joined by the caller; the repository only reports
/// persisted activity keyed by account id.
class AnalyticsAccountTotal {
  /// Creates per-account activity totals.
  const new({
    required this.accountId,
    required this.incomeMinorUnits,
    required this.expenseMinorUnits,
  });

  /// The account the activity belongs to.
  final String accountId;

  /// Summed income minor units for the range; transfers are excluded.
  final int incomeMinorUnits;

  /// Summed expense minor units for the range; transfers are excluded.
  final int expenseMinorUnits;
}
