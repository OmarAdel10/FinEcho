import 'package:flutter/foundation.dart';

/// Whether a transaction increases, decreases, or moves money.
enum TransactionType {
  /// Money spent from an account.
  expense,

  /// Money received by an account.
  income,

  /// Money moved between accounts.
  transfer,
}

/// Where a transaction originated.
enum TransactionSource {
  /// A transaction entered directly by the user.
  manual,

  /// A transaction parsed from an Android SMS notification.
  sms,

  /// A transaction imported from an external data source.
  import,
}

/// A money movement recorded against an account.
@immutable
class Transaction {
  /// Creates an immutable transaction snapshot.
  const new({
    required this.id,
    required this.accountId,
    required this.amountMinorUnits,
    required this.timestamp,
    required this.type,
    required this.source,
    this.categoryId,
    this.rawText,
    this.payee,
  });

  /// Creates a transaction from a SQLite row map.
  factory fromMap(Map<String, Object?> map) {
    return Transaction(
      id: map['id']! as String,
      accountId: map['account_id']! as String,
      categoryId: map['category_id'] as String?,
      amountMinorUnits: map['amount_minor_units']! as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp']! as int,
        isUtc: true,
      ),
      type: TransactionType.values.byName(map['type']! as String),
      source: TransactionSource.values.byName(map['source']! as String),
      rawText: map['raw_text'] as String?,
      payee: map['payee'] as String?,
    );
  }

  /// The stable local identifier for the transaction.
  final String id;

  /// The identifier of the account affected by this transaction.
  final String accountId;

  /// The identifier of the optional spending or income category.
  final String? categoryId;

  /// The transaction amount in the account currency's minor units.
  final int amountMinorUnits;

  /// The UTC timestamp at which the transaction occurred.
  final DateTime timestamp;

  /// The direction or purpose of the transaction.
  final TransactionType type;

  /// The origin of the transaction.
  final TransactionSource source;

  /// The original message text for automatically captured transactions.
  final String? rawText;

  /// The counterparty of the transaction, such as a merchant.
  final String? payee;

  /// Returns a copy with non-null fields replaced by the supplied values.
  Transaction copyWith({
    String? id,
    String? accountId,
    String? categoryId,
    int? amountMinorUnits,
    DateTime? timestamp,
    TransactionType? type,
    TransactionSource? source,
    String? rawText,
    String? payee,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      source: source ?? this.source,
      rawText: rawText ?? this.rawText,
      payee: payee ?? this.payee,
    );
  }

  /// Converts the transaction to a map for SQLite persistence.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'account_id': accountId,
      'category_id': categoryId,
      'amount_minor_units': amountMinorUnits,
      'timestamp': timestamp.toUtc().millisecondsSinceEpoch,
      'type': type.name,
      'source': source.name,
      'raw_text': rawText,
      'payee': payee,
    };
  }

  /// Whether [other] is a transaction with the same field values.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Transaction &&
            id == other.id &&
            accountId == other.accountId &&
            categoryId == other.categoryId &&
            amountMinorUnits == other.amountMinorUnits &&
            timestamp == other.timestamp &&
            type == other.type &&
            source == other.source &&
            rawText == other.rawText &&
            payee == other.payee;
  }

  /// A hash code derived from every transaction field.
  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    categoryId,
    amountMinorUnits,
    timestamp,
    type,
    source,
    rawText,
    payee,
  );
}
