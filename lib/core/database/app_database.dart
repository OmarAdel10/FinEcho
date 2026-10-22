import 'package:finecho/core/database/database_opener.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Opens and owns FinEcho's encrypted SQLite database connection.
class AppDatabase {
  /// Creates a lazy connection holder for the database opened by [opener].
  AppDatabase({required this.opener});

  /// The opener that opens the encrypted database.
  final DatabaseOpener opener;

  Database? _database;

  /// Opens or returns the already-open SQLCipher database.
  Future<Database> open() async {
    final existingDatabase = _database;
    if (existingDatabase != null) {
      return existingDatabase;
    }

    final database = await opener.open();
    _database = database;
    return database;
  }

  /// Closes the database if it has been opened.
  Future<void> close() async {
    final database = _database;
    _database = null;
    await database?.close();
  }
}
