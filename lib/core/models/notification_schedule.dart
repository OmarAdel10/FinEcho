import 'package:flutter/foundation.dart';

/// How often a notification schedule repeats.
enum NotificationRepeatInterval {
  /// A one-time notification.
  none,

  /// A notification that repeats every day.
  daily,

  /// A notification that repeats every week.
  weekly,

  /// A notification that repeats every month.
  monthly,

  /// A notification that repeats every year.
  yearly,
}

/// A persisted instruction for showing a local notification.
@immutable
class NotificationSchedule {
  /// Creates an immutable notification schedule.
  const new({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.repeatInterval,
    required this.payload,
    required this.enabled,
  });

  /// Creates a schedule from a SQLite row map.
  ///
  /// The repository implementation decodes `payload` from JSON before calling
  /// this factory.
  factory fromMap(Map<String, Object?> map) {
    return NotificationSchedule(
      id: map['id']! as String,
      title: map['title']! as String,
      body: map['body']! as String,
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(
        map['scheduled_time']! as int,
        isUtc: true,
      ),
      repeatInterval: NotificationRepeatInterval.values.byName(
        map['repeat_interval']! as String,
      ),
      payload: map['payload']! as Map<String, Object?>,
      enabled: map['enabled']! as int == 1,
    );
  }

  /// The stable local identifier for the schedule.
  final String id;

  /// The notification title shown to the user.
  final String title;

  /// The notification body shown to the user.
  final String body;

  /// The UTC time at which the next notification is due.
  final DateTime scheduledTime;

  /// The recurrence rule for this schedule.
  final NotificationRepeatInterval repeatInterval;

  /// The versioned routing data carried by the notification.
  final Map<String, Object?> payload;

  /// Whether the scheduler should process this schedule.
  final bool enabled;

  /// Returns a copy with non-null fields replaced by the supplied values.
  NotificationSchedule copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? scheduledTime,
    NotificationRepeatInterval? repeatInterval,
    Map<String, Object?>? payload,
    bool? enabled,
  }) {
    return NotificationSchedule(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      payload: payload ?? this.payload,
      enabled: enabled ?? this.enabled,
    );
  }

  /// Converts the schedule to a SQLite field map.
  ///
  /// The repository implementation serializes [payload] to JSON TEXT.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'body': body,
      'scheduled_time': scheduledTime.toUtc().millisecondsSinceEpoch,
      'repeat_interval': repeatInterval.name,
      'payload': payload,
      'enabled': enabled ? 1 : 0,
    };
  }

  /// Whether [other] is a schedule with the same field values.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationSchedule &&
            id == other.id &&
            title == other.title &&
            body == other.body &&
            scheduledTime == other.scheduledTime &&
            repeatInterval == other.repeatInterval &&
            mapEquals(payload, other.payload) &&
            enabled == other.enabled;
  }

  /// A hash code derived from every schedule field.
  @override
  int get hashCode => Object.hash(
    id,
    title,
    body,
    scheduledTime,
    repeatInterval,
    enabled,
    Object.hashAllUnordered(
      payload.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
  );
}
