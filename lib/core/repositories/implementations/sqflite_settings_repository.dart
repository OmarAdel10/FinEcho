import 'package:finecho/core/models/app_setting.dart';
import 'package:finecho/core/repositories/contracts/settings_repository.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart'
    show ConflictAlgorithm, Database;

/// A SQLCipher-backed settings repository implementation.
class SqfliteSettingsRepository implements SettingsRepository {
  /// Creates a repository backed by the supplied SQLite database.
  const new(this._database);

  final Database _database;

  @override
  Future<AppSetting?> get(String key) async {
    final rows = await _database.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: <Object?>[key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return AppSetting.fromMap(rows.first);
  }

  @override
  Future<void> set(String key, String value) async {
    await _database.insert('app_settings', <String, Object?>{
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<AppSetting>> list() async {
    final rows = await _database.query('app_settings', orderBy: 'key ASC');
    return rows.map(AppSetting.fromMap).toList();
  }

  @override
  Future<void> delete(String key) async {
    await _database.delete(
      'app_settings',
      where: 'key = ?',
      whereArgs: <Object?>[key],
    );
  }
}
