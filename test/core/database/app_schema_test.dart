import 'package:finecho/core/database/schema/app_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSchema', () {
    test('creates every table and index in a dependency-safe order', () {
      const statements = AppSchema.statements;
      const tableOrder = <String>[
        'accounts',
        'categories',
        'transactions',
        'budgets',
        'speech_drafts',
        'sms_messages',
        'sms_parsing_rules',
        'notification_schedules',
        'app_settings',
        'security_state',
      ];

      expect(statements.length, greaterThanOrEqualTo(21));
      expect(
        statements.take(tableOrder.length).map(_tableFromCreate),
        tableOrder,
      );
      expect(statements.skip(tableOrder.length).every(_isIndex), isTrue);
    });

    test('creates foreign keys and indexes for ingestible records', () {
      expect(
        AppSchema.statements.join('\n'),
        contains('FOREIGN KEY(account_id)\n    REFERENCES accounts(id)'),
      );
      expect(
        AppSchema.statements.join('\n'),
        contains('CREATE UNIQUE INDEX idx_sms_messages_fingerprint'),
      );
    });
  });
}

String _tableFromCreate(String statement) {
  final match = RegExp(r'^CREATE TABLE (\w+)').firstMatch(statement);
  return match?.group(1) ?? '';
}

bool _isIndex(String statement) =>
    statement.startsWith('CREATE INDEX') ||
    statement.startsWith('CREATE UNIQUE INDEX');
