import 'dart:convert';

import 'package:finecho/core/models/notification_schedule.dart';
import 'package:finecho/core/repositories/contracts/notification_repository.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart' show Database;

/// A SQLCipher-backed notification repository implementation.
class SqfliteNotificationRepository implements NotificationRepository {
  /// Creates a repository backed by the supplied SQLite database.
  const new(this._database);

  final Database _database;

  @override
  Future<List<NotificationSchedule>> list() async {
    final rows = await _database.query(
      'notification_schedules',
      orderBy: 'scheduled_time ASC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<NotificationSchedule?> get(String id) async {
    final rows = await _database.query(
      'notification_schedules',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  @override
  Future<void> create(NotificationSchedule schedule) async {
    await _database.insert('notification_schedules', _toRow(schedule));
  }

  @override
  Future<void> update(NotificationSchedule schedule) async {
    await _database.update(
      'notification_schedules',
      _toRow(schedule),
      where: 'id = ?',
      whereArgs: <Object?>[schedule.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await _database.delete(
      'notification_schedules',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  @override
  Future<List<NotificationSchedule>> listScheduledBetween(
    DateTime start,
    DateTime end,
  ) async {
    final startTime = start.toUtc();
    final endTime = end.toUtc();
    if (startTime.isAfter(endTime)) {
      throw ArgumentError.value(end, 'end', 'Must not precede start.');
    }

    final rows = await _database.query(
      'notification_schedules',
      where: 'scheduled_time >= ? AND scheduled_time <= ?',
      whereArgs: <Object?>[
        startTime.millisecondsSinceEpoch,
        endTime.millisecondsSinceEpoch,
      ],
      orderBy: 'scheduled_time ASC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> setEnabled(String id, {required bool enabled}) async {
    await _database.update(
      'notification_schedules',
      <String, Object?>{'enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  NotificationSchedule _fromRow(Map<String, Object?> row) {
    final dynamic decodedPayload = jsonDecode(row['payload']! as String);
    if (decodedPayload is! Map<String, Object?>) {
      throw const FormatException('Notification payload must be an object.');
    }

    return NotificationSchedule.fromMap(<String, Object?>{
      ...row,
      'payload': decodedPayload,
    });
  }

  Map<String, Object?> _toRow(NotificationSchedule schedule) {
    return <String, Object?>{
      ...schedule.toMap(),
      'payload': jsonEncode(schedule.payload),
    };
  }
}
