import 'package:flutter/foundation.dart';

/// The processing state of an ingested Android SMS.
enum SmsMessageStatus {
  /// The SMS is stored but has not been parsed.
  received,

  /// The SMS was successfully parsed into transaction data.
  parsed,

  /// No enabled rule or account mapping could process the SMS.
  unmatched,

  /// An applicable rule attempted parsing but did not produce valid data.
  failed,
}

/// An Android SMS event considered for transaction ingestion.
@immutable
class SmsMessage {
  /// Creates an immutable SMS message snapshot.
  const new({
    required this.id,
    required this.sender,
    required this.receivedAt,
    required this.fingerprint,
    required this.status,
    this.accountId,
    this.parsedPayload,
  });

  /// Creates an SMS message from a SQLite row map.
  ///
  /// [parsedPayload] is expected to already be a logical map. The repository
  /// implementation owns conversion to and from its TEXT representation.
  factory fromMap(Map<String, Object?> map) {
    return SmsMessage(
      id: map['id']! as String,
      sender: map['sender']! as String,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(
        map['received_at']! as int,
        isUtc: true,
      ),
      fingerprint: map['fingerprint']! as String,
      accountId: map['account_id'] as String?,
      parsedPayload: map['parsed_payload'] as Map<String, Object?>?,
      status: SmsMessageStatus.values.byName(map['status']! as String),
    );
  }

  /// The stable local identifier for the SMS message.
  final String id;

  /// The SMS sender identifier, such as a shortened bank sender code.
  final String sender;

  /// The UTC timestamp at which the SMS was received.
  final DateTime receivedAt;

  /// The deterministic identifier used to suppress duplicate SMS events.
  final String fingerprint;

  /// The identifier of the linked account, when one is known.
  final String? accountId;

  /// The parsed, non-sensitive transaction fields produced by a rule.
  final Map<String, Object?>? parsedPayload;

  /// The current ingestion state of the SMS.
  final SmsMessageStatus status;

  /// Returns a copy with non-null fields replaced by the supplied values.
  SmsMessage copyWith({
    String? id,
    String? sender,
    DateTime? receivedAt,
    String? fingerprint,
    String? accountId,
    Map<String, Object?>? parsedPayload,
    SmsMessageStatus? status,
  }) {
    return SmsMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      receivedAt: receivedAt ?? this.receivedAt,
      fingerprint: fingerprint ?? this.fingerprint,
      accountId: accountId ?? this.accountId,
      parsedPayload: parsedPayload ?? this.parsedPayload,
      status: status ?? this.status,
    );
  }

  /// Converts the SMS message to a logical map for SQLite persistence.
  ///
  /// The implementation serializes [parsedPayload] before inserting the row.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'sender': sender,
      'received_at': receivedAt.toUtc().millisecondsSinceEpoch,
      'fingerprint': fingerprint,
      'account_id': accountId,
      'parsed_payload': parsedPayload,
      'status': status.name,
    };
  }

  /// Whether [other] is an SMS message with the same field values.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SmsMessage &&
            id == other.id &&
            sender == other.sender &&
            receivedAt == other.receivedAt &&
            fingerprint == other.fingerprint &&
            accountId == other.accountId &&
            _mapEquals(parsedPayload, other.parsedPayload) &&
            status == other.status;
  }

  /// A hash code derived from every SMS message field.
  @override
  int get hashCode => Object.hash(
    id,
    sender,
    receivedAt,
    fingerprint,
    accountId,
    Object.hashAll(parsedPayload?.entries ?? const Iterable.empty()),
    status,
  );

  static bool _mapEquals(
    Map<String, Object?>? left,
    Map<String, Object?>? right,
  ) {
    if (identical(left, right)) {
      return true;
    }
    if (left == null || right == null || left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}
