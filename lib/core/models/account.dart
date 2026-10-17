import 'package:flutter/foundation.dart';

/// The kind of financial account represented by an [Account].
enum AccountType {
  /// Money held as cash.
  cash,

  /// A debit card attached to a funding source.
  debitCard,

  /// A revolving credit account.
  creditCard,

  /// A prepaid or Mezza stored-value card.
  prepaidMezza,

  /// Money held at a bank.
  bank,

  /// Money held in a digital wallet.
  wallet,

  /// Money set aside in a savings account.
  savings,

  /// An account type that does not match another built-in type.
  other,
}

/// An account that can hold money or credit in FinEcho.
@immutable
class Account {
  /// Creates an immutable account snapshot.
  const new({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.balanceMinorUnits,
    this.archived = false,
    this.maskedIdentifier,
    this.linkedAccountId,
    this.creditLimitMinorUnits,
    this.outstandingBalanceMinorUnits,
  });

  /// Creates an account from a SQLite row map.
  factory fromMap(Map<String, Object?> map) {
    return Account(
      id: map['id']! as String,
      name: map['name']! as String,
      type: AccountType.values.byName(map['type']! as String),
      currency: map['currency']! as String,
      balanceMinorUnits: map['balance_minor_units']! as int,
      archived: (map['archived']! as int) == 1,
      maskedIdentifier: map['masked_identifier'] as String?,
      linkedAccountId: map['linked_account_id'] as String?,
      creditLimitMinorUnits: map['credit_limit_minor_units'] as int?,
      outstandingBalanceMinorUnits:
          map['outstanding_balance_minor_units'] as int?,
    );
  }

  /// The stable local identifier for the account.
  final String id;

  /// The display name supplied by the user or data source.
  final String name;

  /// The kind of account.
  final AccountType type;

  /// The ISO currency code used for this account's amounts.
  final String currency;

  /// The current balance in the account currency's minor units.
  final int balanceMinorUnits;

  /// Whether the account is archived and excluded from active workflows.
  final bool archived;

  /// A safe, partial identifier such as the last four card digits.
  final String? maskedIdentifier;

  /// The identifier of another account linked to this account.
  final String? linkedAccountId;

  /// The credit limit in minor units for credit accounts.
  final int? creditLimitMinorUnits;

  /// The amount still owed in minor units for credit accounts.
  final int? outstandingBalanceMinorUnits;

  /// Returns a copy with non-null fields replaced by the supplied values.
  Account copyWith({
    String? id,
    AccountType? type,
    String? name,
    String? currency,
    int? balanceMinorUnits,
    bool? archived,
    String? maskedIdentifier,
    String? linkedAccountId,
    int? creditLimitMinorUnits,
    int? outstandingBalanceMinorUnits,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      balanceMinorUnits: balanceMinorUnits ?? this.balanceMinorUnits,
      archived: archived ?? this.archived,
      maskedIdentifier: maskedIdentifier ?? this.maskedIdentifier,
      linkedAccountId: linkedAccountId ?? this.linkedAccountId,
      creditLimitMinorUnits:
          creditLimitMinorUnits ?? this.creditLimitMinorUnits,
      outstandingBalanceMinorUnits:
          outstandingBalanceMinorUnits ?? this.outstandingBalanceMinorUnits,
    );
  }

  /// Converts the account to a map for SQLite persistence.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'type': type.name,
      'currency': currency,
      'balance_minor_units': balanceMinorUnits,
      'archived': archived ? 1 : 0,
      'masked_identifier': maskedIdentifier,
      'linked_account_id': linkedAccountId,
      'credit_limit_minor_units': creditLimitMinorUnits,
      'outstanding_balance_minor_units': outstandingBalanceMinorUnits,
    };
  }

  /// Whether [other] is an account with the same field values.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Account &&
            id == other.id &&
            name == other.name &&
            type == other.type &&
            currency == other.currency &&
            balanceMinorUnits == other.balanceMinorUnits &&
            archived == other.archived &&
            maskedIdentifier == other.maskedIdentifier &&
            linkedAccountId == other.linkedAccountId &&
            creditLimitMinorUnits == other.creditLimitMinorUnits &&
            outstandingBalanceMinorUnits == other.outstandingBalanceMinorUnits;
  }

  /// A hash code derived from every account field.
  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    currency,
    balanceMinorUnits,
    archived,
    maskedIdentifier,
    linkedAccountId,
    creditLimitMinorUnits,
    outstandingBalanceMinorUnits,
  );
}
