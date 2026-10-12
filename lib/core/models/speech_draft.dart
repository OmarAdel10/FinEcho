import 'package:flutter/foundation.dart';

/// The review state of a draft created from speech input.
enum SpeechDraftStatus {
  /// The draft is awaiting user review.
  pending,

  /// The user accepted the draft and it was converted.
  confirmed,

  /// The user rejected the draft.
  discarded,
}

/// A reviewable draft produced from a speech transaction entry.
@immutable
class SpeechDraft {
  /// Creates an immutable speech draft snapshot.
  const new({
    required this.id,
    required this.transcript,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.parsedAmountMinorUnits,
    this.parsedPayee,
    this.parsedCategoryId,
    this.confidence,
  });

  /// Creates a speech draft from a SQLite row map.
  factory fromMap(Map<String, Object?> map) {
    return SpeechDraft(
      id: map['id']! as String,
      transcript: map['transcript']! as String,
      parsedAmountMinorUnits: map['parsed_amount_minor_units'] as int?,
      parsedPayee: map['parsed_payee'] as String?,
      parsedCategoryId: map['parsed_category_id'] as String?,
      confidence: map['confidence'] as double?,
      status: SpeechDraftStatus.values.byName(map['status']! as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at']! as int,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updated_at']! as int,
        isUtc: true,
      ),
    );
  }

  /// The stable local identifier for the speech draft.
  final String id;

  /// The raw transcript supplied by the speech recognizer.
  final String transcript;

  /// The parsed amount in the transaction currency's minor units.
  final int? parsedAmountMinorUnits;

  /// The payee extracted from the transcript.
  final String? parsedPayee;

  /// The category proposed for the transaction.
  final String? parsedCategoryId;

  /// The recognizer or parser confidence, from `0.0` through `1.0`.
  final double? confidence;

  /// The current review state of the draft.
  final SpeechDraftStatus status;

  /// The UTC timestamp at which the draft was created.
  final DateTime createdAt;

  /// The UTC timestamp at which the draft was last changed.
  final DateTime updatedAt;

  /// Returns a copy with non-null fields replaced by the supplied values.
  SpeechDraft copyWith({
    String? id,
    String? transcript,
    int? parsedAmountMinorUnits,
    String? parsedPayee,
    String? parsedCategoryId,
    double? confidence,
    SpeechDraftStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SpeechDraft(
      id: id ?? this.id,
      transcript: transcript ?? this.transcript,
      parsedAmountMinorUnits:
          parsedAmountMinorUnits ?? this.parsedAmountMinorUnits,
      parsedPayee: parsedPayee ?? this.parsedPayee,
      parsedCategoryId: parsedCategoryId ?? this.parsedCategoryId,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts the speech draft to a map for SQLite persistence.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'transcript': transcript,
      'parsed_amount_minor_units': parsedAmountMinorUnits,
      'parsed_payee': parsedPayee,
      'parsed_category_id': parsedCategoryId,
      'confidence': confidence,
      'status': status.name,
      'created_at': createdAt.toUtc().millisecondsSinceEpoch,
      'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
    };
  }

  /// Whether [other] is a speech draft with the same field values.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SpeechDraft &&
            id == other.id &&
            transcript == other.transcript &&
            parsedAmountMinorUnits == other.parsedAmountMinorUnits &&
            parsedPayee == other.parsedPayee &&
            parsedCategoryId == other.parsedCategoryId &&
            confidence == other.confidence &&
            status == other.status &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt;
  }

  /// A hash code derived from every speech draft field.
  @override
  int get hashCode => Object.hash(
    id,
    transcript,
    parsedAmountMinorUnits,
    parsedPayee,
    parsedCategoryId,
    confidence,
    status,
    createdAt,
    updatedAt,
  );
}
