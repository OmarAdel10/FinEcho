import 'package:finecho/core/database/database_opener.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('DatabaseOpener schema', () {
    test(
      'creates the shared schema with the columns the models read',
      () async {
        sqfliteFfiInit();
        final opener = DatabaseOpener(passwordProvider: () async => 'test');
        final database = await databaseFactoryFfi.openDatabase(
          inMemoryDatabasePath,
        );
        addTearDown(database.close);

        await opener.createSchema(database);

        final transactionsColumns = await _columnNames(
          database,
          'transactions',
        );
        expect(
          transactionsColumns,
          containsAll(<String>[
            'id',
            'account_id',
            'category_id',
            'amount_minor_units',
            'timestamp',
            'type',
            'source',
            'raw_text',
            'payee',
          ]),
        );

        final parsingRulesColumns = await _columnNames(
          database,
          'sms_parsing_rules',
        );
        expect(
          parsingRulesColumns,
          containsAll(<String>[
            'sender_pattern',
            'amount_pattern',
            'payee_pattern',
          ]),
        );

        final budgetsColumns = await _columnNames(database, 'budgets');
        expect(
          budgetsColumns,
          containsAll(<String>[
            'allocated_amount_minor_units',
            'period',
            'start_date',
            'warning_share',
            'currency',
          ]),
        );
      },
    );

    test('upgrades through the shared migration ladder', () async {
      sqfliteFfiInit();
      final opener = DatabaseOpener(passwordProvider: () async => 'test');
      final database = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
      );
      addTearDown(database.close);
      await database.execute('''
        CREATE TABLE budgets (
          id TEXT PRIMARY KEY,
          category_id TEXT NOT NULL,
          allocated_amount_minor_units INTEGER NOT NULL,
          period TEXT NOT NULL,
          start_date INTEGER NOT NULL,
          warning_share REAL
        )
      ''');

      await opener.upgradeSchema(database, fromVersion: 6, toVersion: 7);

      final budgetsColumns = await _columnNames(database, 'budgets');
      expect(budgetsColumns, contains('currency'));
    });
  });
}

Future<List<String>> _columnNames(Database database, String table) async {
  final rows = await database.rawQuery('PRAGMA table_info($table)');
  return rows.map((row) => row['name']! as String).toList();
}
