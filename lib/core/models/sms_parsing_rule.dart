import 'package:flutter/foundation.dart';

/// A configurable rule used to extract transaction data from Android SMS.
@immutable
class SmsParsingRule {
  /// Creates an immutable SMS parsing rule snapshot.
  const new({
    required this.id,
    required this.accountId,
    required this.senderPattern,
    required this.amountPattern,
    required this.payeePattern,
    required this.enabled,
  });

  /// Creates an SMS parsing rule from a SQLite row map.
  factory fromMap(Map<String, Object?> map) {
    return SmsParsingRule(
      id: map['id']! as String,
      accountId: map['account_id']! as String,
      senderPattern: map['sender_pattern']! as String,
      amountPattern: map['amount_pattern']! as String,
      payeePattern: map['payee_pattern']! as String,
      enabled: (map['enabled']! as int) != 0,
    );
  }

  /// The stable local identifier for the parsing rule.
  final String id;

  /// The identifier of the account associated with parsed transactions.
  final String accountId;

  /// The pattern used to recognize the SMS sender.
  final String senderPattern;

  /// The pattern used to extract the transaction amount.
  final String amountPattern;

  /// The pattern used to extract the transaction payee.
  final String payeePattern;

  /// Whether the rule is eligible for new SMS ingestion.
  final bool enabled;

  /// Returns a copy with non-null fields replaced by the supplied values.
  SmsParsingRule copyWith({
    String? id,
    String? accountId,
    String? senderPattern,
    String? amountPattern,
    String? payeePattern,
    bool? enabled,
  }) {
    return SmsParsingRule(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      senderPattern: senderPattern ?? this.senderPattern,
      amountPattern: amountPattern ?? this.amountPattern,
      payeePattern: payeePattern ?? this.payeePattern,
      enabled: enabled ?? this.enabled,
    );
  }

  /// Converts the parsing rule to a map for SQLite persistence.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'account_id': accountId,
      'sender_pattern': senderPattern,
      'amount_pattern': amountPattern,
      'payee_pattern': payeePattern,
      'enabled': enabled ? 1 : 0,
    };
  }

  /// Whether [other] is an SMS parsing rule with the same field values.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SmsParsingRule &&
            id == other.id &&
            accountId == other.accountId &&
            senderPattern == other.senderPattern &&
            amountPattern == other.amountPattern &&
            payeePattern == other.payeePattern &&
            enabled == other.enabled;
  }

  /// A hash code derived from every parsing rule field.
  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    senderPattern,
    amountPattern,
    payeePattern,
    enabled,
  );
}
