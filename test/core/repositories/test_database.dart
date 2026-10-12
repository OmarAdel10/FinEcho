import 'package:finecho/core/database/schema/app_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Creates an isolated in-memory FinEcho database for repository tests.
Future<Database> createTestDatabase() {
  sqfliteFfiInit();

  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: AppSchema.version,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, _) async {
        for (final statement in AppSchema.statements) {
          await database.execute(statement);
        }
      },
    ),
  );
}
