import 'package:finecho/core/database/migrations/app_migrations.dart';
import 'package:finecho/core/database/schema/app_schema.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Opens FinEcho's encrypted local database on demand.
///
/// The database is opened lazily so nothing touches secure storage or the
/// file system before the first query. The password is resolved through
/// [passwordProvider] when the database is opened, because reading the key
/// from secure storage must not happen while the application starts.
///
/// The schema is delegated to [AppSchema] and the upgrades to [AppMigrations],
/// so the opener never carries its own copy of the table definitions.
class DatabaseOpener {
  /// Creates an opener that resolves the database password lazily.
  new({required this.passwordProvider, this.fileName = 'finecho.db'});

  /// Resolves the password that encrypts the database.
  final Future<String> Function() passwordProvider;

  /// The database file name inside the databases directory.
  final String fileName;

  Database? _database;

  /// Opens the database, creating it on first use.
  ///
  /// The connection is kept open, so repeated calls reuse the same database.
  Future<Database> open() async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final directory = await getDatabasesPath();
    final path = join(directory, fileName);
    final password = await passwordProvider();

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

  /// Creates the latest shared schema on [database].
  ///
  /// Used as the SQLCipher `onCreate` hook. Tests also call it directly to
  /// build a schema-shaped database without the encrypted platform channel.
  Future<void> createSchema(DatabaseExecutor database) async {
    for (final statement in AppSchema.statements) {
      await database.execute(statement);
    }
  }

  /// Moves [database] from [fromVersion] to [toVersion] on the shared
  /// migration ladder.
  ///
  /// Used as the SQLCipher `onUpgrade` hook. Tests also call it directly to
  /// exercise upgrades without the encrypted platform channel.
  Future<void> upgradeSchema(
    DatabaseExecutor database, {
    required int fromVersion,
    required int toVersion,
  }) async {
    await AppMigrations.migrate(
      database: database,
      fromVersion: fromVersion,
      toVersion: toVersion,
    );
  }

  Future<void> _onConfigure(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database database, int version) async {
    await createSchema(database);
  }

  Future<void> _onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    await upgradeSchema(
      database,
      fromVersion: oldVersion,
      toVersion: newVersion,
    );
  }

  Future<void> _onOpen(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
  }
}
