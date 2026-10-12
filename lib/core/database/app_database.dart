import 'package:finecho/core/database/migrations/app_migrations.dart';
import 'package:finecho/core/database/schema/app_schema.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Opens and owns FinEcho's encrypted SQLite database connection.
class AppDatabase {
  /// Creates a lazy connection holder for the database at [path].
  new({required this.path, required this.password});

  /// The file path used when the database is opened.
  final String path;

  /// The SQLCipher password used to encrypt and decrypt the database.
  final String password;

  Database? _database;

  /// Opens or returns the already-open SQLCipher database.
  Future<Database> open() async {
    final existingDatabase = _database;
    if (existingDatabase != null) {
      return existingDatabase;
    }

    final database = await openDatabase(
      path,
      password: password,
      version: AppSchema.version,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
    _database = database;
    return database;
  }

  /// Closes the database if it has been opened.
  Future<void> close() async {
    final database = _database;
    _database = null;
    await database?.close();
  }

  Future<void> _onConfigure(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database database, int version) async {
    for (final statement in AppSchema.statements) {
      await database.execute(statement);
    }
  }

  Future<void> _onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    await AppMigrations.migrate(
      database: database,
      fromVersion: oldVersion,
      toVersion: newVersion,
    );
  }

  Future<void> _onOpen(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
  }
}
