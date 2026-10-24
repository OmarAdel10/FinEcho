import 'package:finecho/core/database/migrations/app_migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// SQL tolerates the leading spaces; the split strings stay readable.
// ignore_for_file: missing_whitespace_between_adjacent_strings

const String _version1AccountsTable =
    'CREATE TABLE accounts ('
    ' id TEXT PRIMARY KEY,'
    ' name TEXT NOT NULL,'
    ' type TEXT NOT NULL,'
    ' currency TEXT NOT NULL,'
    ' balance_minor_units INTEGER NOT NULL,'
    ' masked_identifier TEXT,'
    ' linked_account_id TEXT,'
    ' credit_limit_minor_units INTEGER,'
    ' outstanding_balance_minor_units INTEGER,'
    ' FOREIGN KEY(linked_account_id) REFERENCES accounts(id)'
    ')';

const String _version5BudgetsTable =
    'CREATE TABLE budgets ('
    ' id TEXT PRIMARY KEY,'
    ' category_id TEXT NOT NULL,'
    ' allocated_amount_minor_units INTEGER NOT NULL,'
    ' period TEXT NOT NULL,'
    ' start_date INTEGER NOT NULL'
    ')';

void main() {
  test('migrates a version 1 database to the archived column', () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1),
    );
    addTearDown(database.close);
    await database.execute(_version1AccountsTable);
    await database.insert('accounts', <String, Object?>{
      'id': 'account-1',
      'name': 'Cash',
      'type': 'cash',
      'currency': 'EGP',
      'balance_minor_units': 5000,
    });

    await AppMigrations.migrate(
      database: database,
      fromVersion: 1,
      toVersion: 2,
    );

    final rows = await database.query('accounts');
    expect(rows.single['archived'], 0);
    await database.insert('accounts', <String, Object?>{
      'id': 'account-2',
      'name': 'Bank',
      'type': 'bank',
      'currency': 'EGP',
      'balance_minor_units': 100,
      'archived': 1,
    });
    final archivedRows = await database.query(
      'accounts',
      where: 'archived = 1',
    );
    expect(archivedRows.single['id'], 'account-2');
  });

  test('rejects an unsupported upgrade path', () async {
    final database = await _openTestDatabase();
    addTearDown(database.close);
    await expectLater(
      AppMigrations.migrate(fromVersion: 1, toVersion: 99, database: database),
      throwsArgumentError,
    );
  });

  test('migrates a version 5 database to the warning share column', () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 5),
    );
    addTearDown(database.close);
    await database.execute(_version5BudgetsTable);
    await database.insert('budgets', <String, Object?>{
      'id': 'budget-1',
      'category_id': 'category-1',
      'allocated_amount_minor_units': 10000,
      'period': 'monthly',
      'start_date': 1761993600000,
    });

    await AppMigrations.migrate(
      database: database,
      fromVersion: 5,
      toVersion: 6,
    );

    final rows = await database.query('budgets');
    expect(rows.single['warning_share'], isNull);

    await database.update(
      'budgets',
      <String, Object?>{'warning_share': 0.9},
      where: 'id = ?',
      whereArgs: <Object>['budget-1'],
    );
    final updatedRows = await database.query('budgets');
    expect(updatedRows.single['warning_share'], 0.9);
  });
}

Future<Database> _openTestDatabase() {
  sqfliteFfiInit();
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(version: 1),
  );
}
