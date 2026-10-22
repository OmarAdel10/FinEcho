import 'package:finecho/core/database/schema/app_schema.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart';

/// Applies ordered schema upgrades for an opened FinEcho database.
abstract final class AppMigrations {
  /// Ordered statements for each target schema version.
  ///
  /// The key is the version that the statements move the database from.
  static const Map<int, List<String>> _upgradeStatements = <int, List<String>>{
    1: <String>[
      'ALTER TABLE accounts ADD COLUMN archived INTEGER NOT NULL DEFAULT 0',
    ],
    2: <String>[
      'CREATE TABLE onboarding (\n',
      '  id INTEGER PRIMARY KEY CHECK (id = 0),\n',
      '  current_step TEXT NOT NULL,\n',
      '  is_completed INTEGER NOT NULL,\n',
      '  biometrics_enabled INTEGER NOT NULL,\n',
      '  sms_automation_enabled INTEGER NOT NULL,\n',
      '  updated_at INTEGER NOT NULL\n',
      ')',
    ],
  };

  /// Moves a database from [fromVersion] through [toVersion].
  ///
  /// Version 1 is created by [AppSchema]; later versions upgrade in place.
  static Future<void> migrate({
    required DatabaseExecutor database,
    required int fromVersion,
    required int toVersion,
  }) async {
    if (fromVersion < 0) {
      throw ArgumentError.value(fromVersion, 'fromVersion', 'Must be >= 0.');
    }
    if (toVersion > AppSchema.version) {
      throw ArgumentError.value(toVersion, 'toVersion', 'Is unsupported.');
    }
    if (fromVersion >= toVersion) {
      return;
    }

    for (var version = fromVersion; version < toVersion; version++) {
      final statements = _upgradeStatements[version];
      if (statements == null) {
        throw UnsupportedError(
          'No migration path from schema version $version to '
          '${version + 1}.',
        );
      }

      for (final statement in statements) {
        await database.execute(statement);
      }
    }
  }
}
