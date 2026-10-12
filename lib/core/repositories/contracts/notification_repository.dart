import 'package:finecho/core/models/notification_schedule.dart';

/// Persists and reads FinEcho local notification schedules.
abstract interface class NotificationRepository {
  /// Returns all notification schedules.
  Future<List<NotificationSchedule>> list();

  /// Returns the schedule with [id], or `null` when it does not exist.
  Future<NotificationSchedule?> get(String id);

  /// Inserts [schedule].
  Future<void> create(NotificationSchedule schedule);

  /// Replaces the stored schedule that has the same id as [schedule].
  Future<void> update(NotificationSchedule schedule);

  /// Deletes the schedule with [id].
  Future<void> delete(String id);

  /// Returns enabled and disabled schedules due in the inclusive UTC range.
  ///
  /// The range is ordered from the earliest to the latest scheduled time.
  Future<List<NotificationSchedule>> listScheduledBetween(
    DateTime start,
    DateTime end,
  );

  /// Enables or disables the schedule with [id] without replacing its payload.
  Future<void> setEnabled(String id, {required bool enabled});
}
