import 'package:flutter/foundation.dart';

/// Income and expense totals for one account within an analytics range.
@immutable
class AccountTotal {
  /// Creates an immutable account total snapshot.
  const new({
    required this.accountId,
    required this.name,
    required this.incomeMinorUnits,
    required this.expenseMinorUnits,
  });

  /// The stable local identifier of the account.
  final String accountId;

  /// The display name of the account.
  final String name;

  /// Total income in the account currency's minor units.
  final int incomeMinorUnits;

  /// Total expenses in the account currency's minor units.
  final int expenseMinorUnits;

  /// Whether [other] is an account total with the same field values.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AccountTotal &&
            accountId == other.accountId &&
            name == other.name &&
            incomeMinorUnits == other.incomeMinorUnits &&
            expenseMinorUnits == other.expenseMinorUnits;
  }

  /// A hash code derived from every account total field.
  @override
  int get hashCode =>
      Object.hash(accountId, name, incomeMinorUnits, expenseMinorUnits);
}
