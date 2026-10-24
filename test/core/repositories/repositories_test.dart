// Test fixtures intentionally repeat constructor defaults for readability.
// ignore_for_file: avoid_redundant_argument_values

import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/models/budget.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/models/category_total.dart';
import 'package:finecho/core/models/notification_schedule.dart';
import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/core/models/sms_message.dart';
import 'package:finecho/core/models/sms_parsing_rule.dart';
import 'package:finecho/core/models/speech_draft.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/core/repositories/implementations/sqflite_account_repository.dart';
import 'package:finecho/core/repositories/implementations/sqflite_analytics_repository.dart';
import 'package:finecho/core/repositories/implementations/sqflite_budget_repository.dart';
import 'package:finecho/core/repositories/implementations/sqflite_category_repository.dart';
import 'package:finecho/core/repositories/implementations/sqflite_notification_repository.dart';
import 'package:finecho/core/repositories/implementations/sqflite_security_repository.dart';
import 'package:finecho/core/repositories/implementations/sqflite_settings_repository.dart';
import 'package:finecho/core/repositories/implementations/sqflite_sms_ingestion_repository.dart';
import 'package:finecho/core/repositories/implementations/sqflite_speech_repository.dart';
import 'package:finecho/core/repositories/implementations/sqflite_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

import 'test_database.dart';

void main() {
  late Database database;
  late SqfliteAccountRepository accountRepository;
  late SqfliteCategoryRepository categoryRepository;
  late SqfliteTransactionRepository transactionRepository;
  late SqfliteBudgetRepository budgetRepository;
  late SqfliteSpeechRepository speechRepository;
  late SqfliteSmsIngestionRepository smsRepository;
  late SqfliteNotificationRepository notificationRepository;
  late SqfliteSettingsRepository settingsRepository;
  late SqfliteSecurityRepository securityRepository;
  late SqfliteAnalyticsRepository analyticsRepository;

  setUp(() async {
    database = await createTestDatabase();
    accountRepository = SqfliteAccountRepository(database);
    categoryRepository = SqfliteCategoryRepository(database);
    transactionRepository = SqfliteTransactionRepository(database);
    budgetRepository = SqfliteBudgetRepository(opener: () async => database);
    speechRepository = SqfliteSpeechRepository(database);
    smsRepository = SqfliteSmsIngestionRepository(database);
    notificationRepository = SqfliteNotificationRepository(database);
    settingsRepository = SqfliteSettingsRepository(database);
    securityRepository = SqfliteSecurityRepository(database);
    analyticsRepository = SqfliteAnalyticsRepository(
      opener: () async => database,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('SqfliteAccountRepository', () {
    test('creates, gets by id, and lists accounts', () async {
      final account = await _seedAccount(
        accountRepository,
        'account-1',
        name: 'Account One',
      );

      expect(await accountRepository.get(account.id), account);
      expect(await accountRepository.list(), <Account>[account]);
    });

    test('updates an account', () async {
      final account = await _seedAccount(accountRepository, 'account-1');
      final updated = account.copyWith(
        name: 'Updated Account',
        type: AccountType.creditCard,
        balanceMinorUnits: 2500,
      );

      await accountRepository.update(updated);

      expect(await accountRepository.get(account.id), updated);
    });

    test('deletes an account', () async {
      final account = await _seedAccount(accountRepository, 'account-1');

      await accountRepository.delete(account.id);

      expect(await accountRepository.get(account.id), isNull);
      expect(await accountRepository.list(), isEmpty);
    });
  });

  group('SqfliteCategoryRepository', () {
    test('creates, gets by id, and lists categories', () async {
      final category = await _seedCategory(
        categoryRepository,
        'category-1',
        name: 'Food',
      );

      expect(await categoryRepository.get(category.id), category);
      expect(await categoryRepository.list(), <Category>[category]);
    });

    test('updates a category', () async {
      final category = await _seedCategory(categoryRepository, 'category-1');
      final updated = category.copyWith(name: 'Groceries');

      await categoryRepository.update(updated);

      expect(await categoryRepository.get(category.id), updated);
    });

    test('deletes a category', () async {
      final category = await _seedCategory(categoryRepository, 'category-1');

      await categoryRepository.delete(category.id);

      expect(await categoryRepository.get(category.id), isNull);
      expect(await categoryRepository.list(), isEmpty);
    });
  });

  group('SqfliteTransactionRepository', () {
    test('creates and gets a transaction', () async {
      await _seedAccount(accountRepository, 'account-1');
      final category = await _seedCategory(categoryRepository, 'category-1');
      final timestamp = DateTime.utc(2026, 1, 10);
      final transaction = Transaction(
        id: 'transaction-1',
        accountId: 'account-1',
        categoryId: category.id,
        amountMinorUnits: 1250,
        timestamp: timestamp,
        type: TransactionType.expense,
        source: TransactionSource.manual,
        rawText: 'Lunch',
      );

      await transactionRepository.create(transaction);

      expect(await transactionRepository.get(transaction.id), transaction);
    });

    test('lists transactions from newest to oldest', () async {
      await _seedAccount(accountRepository, 'account-1');
      final older = await _seedTransaction(
        transactionRepository,
        id: 'transaction-old',
        timestamp: DateTime.utc(2026, 1, 1),
      );
      final newer = await _seedTransaction(
        transactionRepository,
        id: 'transaction-new',
        timestamp: DateTime.utc(2026, 1, 2),
      );

      expect(await transactionRepository.list(), <Transaction>[newer, older]);
    });

    test('updates a transaction', () async {
      await _seedAccount(accountRepository, 'account-1');
      final transaction = await _seedTransaction(
        transactionRepository,
        id: 'transaction-1',
      );
      final updated = transaction.copyWith(
        amountMinorUnits: 2500,
        timestamp: DateTime.utc(2026, 1, 3),
        type: TransactionType.income,
        source: TransactionSource.sms,
      );

      await transactionRepository.update(updated);

      expect(await transactionRepository.get(transaction.id), updated);
    });

    test('deletes a transaction', () async {
      await _seedAccount(accountRepository, 'account-1');
      final transaction = await _seedTransaction(
        transactionRepository,
        id: 'transaction-1',
      );

      await transactionRepository.delete(transaction.id);

      expect(await transactionRepository.get(transaction.id), isNull);
      expect(await transactionRepository.list(), isEmpty);
    });
  });

  group('SqfliteBudgetRepository', () {
    test('creates and gets a budget', () async {
      final category = await _seedCategory(categoryRepository, 'category-1');
      final budget = Budget(
        id: 'budget-1',
        categoryId: category.id,
        allocatedAmountMinorUnits: 50000,
        period: BudgetPeriod.monthly,
        startDate: DateTime.utc(2026, 1),
      );

      await budgetRepository.create(budget);

      expect(await budgetRepository.get(budget.id), budget);
    });

    test('updates a budget', () async {
      final category = await _seedCategory(categoryRepository, 'category-1');
      final budget = Budget(
        id: 'budget-1',
        categoryId: category.id,
        allocatedAmountMinorUnits: 50000,
        period: BudgetPeriod.monthly,
        startDate: DateTime.utc(2026, 1),
      );
      await budgetRepository.create(budget);
      final updated = budget.copyWith(
        allocatedAmountMinorUnits: 60000,
        period: BudgetPeriod.weekly,
      );

      await budgetRepository.update(updated);

      expect(await budgetRepository.get(budget.id), updated);
    });

    test('deletes a budget', () async {
      final category = await _seedCategory(categoryRepository, 'category-1');
      final budget = Budget(
        id: 'budget-1',
        categoryId: category.id,
        allocatedAmountMinorUnits: 50000,
        period: BudgetPeriod.monthly,
        startDate: DateTime.utc(2026, 1),
      );
      await budgetRepository.create(budget);

      await budgetRepository.delete(budget.id);

      expect(await budgetRepository.get(budget.id), isNull);
      expect(await budgetRepository.list(), isEmpty);
    });
  });

  group('SqfliteSpeechRepository', () {
    test('creates and gets a speech draft', () async {
      final draft = SpeechDraft(
        id: 'draft-1',
        transcript: 'Coffee for twenty',
        parsedAmountMinorUnits: 2000,
        parsedPayee: 'Coffee Shop',
        confidence: 0.8,
        status: SpeechDraftStatus.pending,
        createdAt: DateTime.utc(2026, 1, 1, 10),
        updatedAt: DateTime.utc(2026, 1, 1, 10),
      );

      await speechRepository.create(draft);

      expect(await speechRepository.get(draft.id), draft);
    });

    test('updates a speech draft', () async {
      final draft = SpeechDraft(
        id: 'draft-1',
        transcript: 'Coffee for twenty',
        status: SpeechDraftStatus.pending,
        createdAt: DateTime.utc(2026, 1, 1, 10),
        updatedAt: DateTime.utc(2026, 1, 1, 10),
      );
      await speechRepository.create(draft);
      final updated = draft.copyWith(
        parsedAmountMinorUnits: 2000,
        status: SpeechDraftStatus.confirmed,
        updatedAt: DateTime.utc(2026, 1, 1, 11),
      );

      await speechRepository.update(updated);

      expect(await speechRepository.get(draft.id), updated);
    });

    test('deletes a speech draft', () async {
      final draft = SpeechDraft(
        id: 'draft-1',
        transcript: 'Coffee for twenty',
        status: SpeechDraftStatus.pending,
        createdAt: DateTime.utc(2026, 1, 1, 10),
        updatedAt: DateTime.utc(2026, 1, 1, 10),
      );
      await speechRepository.create(draft);

      await speechRepository.delete(draft.id);

      expect(await speechRepository.get(draft.id), isNull);
      expect(await speechRepository.list(), isEmpty);
    });
  });

  group('SqfliteSmsIngestionRepository', () {
    test('creates, gets, and looks up messages by fingerprint', () async {
      final account = await _seedAccount(accountRepository, 'account-1');
      final message = SmsMessage(
        id: 'message-1',
        sender: 'TEST',
        receivedAt: DateTime.utc(2026, 1, 1, 12),
        fingerprint: 'fingerprint-1',
        accountId: account.id,
        parsedPayload: const <String, Object?>{
          'amount_minor_units': 1500,
          'payee': 'Store',
        },
        status: SmsMessageStatus.parsed,
      );

      await smsRepository.createMessage(message);

      expect(await smsRepository.getMessage(message.id), message);
      expect(
        await smsRepository.getMessageByFingerprint(message.fingerprint),
        message,
      );
    });

    test('updates a message', () async {
      final message = SmsMessage(
        id: 'message-1',
        sender: 'TEST',
        receivedAt: DateTime.utc(2026, 1, 1, 12),
        fingerprint: 'fingerprint-1',
        status: SmsMessageStatus.received,
      );
      await smsRepository.createMessage(message);
      final updated = message.copyWith(
        status: SmsMessageStatus.unmatched,
        parsedPayload: <String, Object?>{'reason': 'No matching account'},
      );

      await smsRepository.updateMessage(updated);

      expect(await smsRepository.getMessage(message.id), updated);
    });

    test('deletes a message', () async {
      final message = SmsMessage(
        id: 'message-1',
        sender: 'TEST',
        receivedAt: DateTime.utc(2026, 1, 1, 12),
        fingerprint: 'fingerprint-1',
        status: SmsMessageStatus.received,
      );
      await smsRepository.createMessage(message);

      await smsRepository.deleteMessage(message.id);

      expect(await smsRepository.getMessage(message.id), isNull);
      expect(await smsRepository.listMessages(), isEmpty);
    });

    test('creates, gets, and filters parsing rules by account', () async {
      final firstAccount = await _seedAccount(accountRepository, 'account-1');
      final secondAccount = await _seedAccount(accountRepository, 'account-2');
      final firstRule = await _seedParsingRule(
        smsRepository,
        id: 'rule-1',
        accountId: firstAccount.id,
      );
      final secondRule = await _seedParsingRule(
        smsRepository,
        id: 'rule-2',
        accountId: secondAccount.id,
      );

      expect(await smsRepository.getParsingRule(firstRule.id), firstRule);
      expect(
        await smsRepository.listParsingRules(firstAccount.id),
        <SmsParsingRule>[firstRule],
      );
      expect(
        await smsRepository.listParsingRules(secondAccount.id),
        <SmsParsingRule>[secondRule],
      );
    });

    test('updates a parsing rule', () async {
      final account = await _seedAccount(accountRepository, 'account-1');
      final rule = await _seedParsingRule(
        smsRepository,
        id: 'rule-1',
        accountId: account.id,
      );
      final updated = rule.copyWith(senderPattern: 'NEW-TEST', enabled: false);

      await smsRepository.updateParsingRule(updated);

      expect(await smsRepository.getParsingRule(rule.id), updated);
    });

    test('deletes a parsing rule', () async {
      final account = await _seedAccount(accountRepository, 'account-1');
      final rule = await _seedParsingRule(
        smsRepository,
        id: 'rule-1',
        accountId: account.id,
      );

      await smsRepository.deleteParsingRule(rule.id);

      expect(await smsRepository.getParsingRule(rule.id), isNull);
      expect(await smsRepository.listParsingRules(account.id), isEmpty);
    });
  });

  group('SqfliteNotificationRepository', () {
    test('creates and gets a schedule', () async {
      final schedule = _notificationSchedule(
        'schedule-1',
        scheduledTime: DateTime.utc(2026, 1, 1, 9),
      );

      await notificationRepository.create(schedule);

      expect(await notificationRepository.get(schedule.id), schedule);
    });

    test('updates a schedule', () async {
      final schedule = _notificationSchedule(
        'schedule-1',
        scheduledTime: DateTime.utc(2026, 1, 1, 9),
      );
      await notificationRepository.create(schedule);
      final updated = schedule.copyWith(
        title: 'Updated reminder',
        scheduledTime: DateTime.utc(2026, 1, 2, 9),
        repeatInterval: NotificationRepeatInterval.weekly,
      );

      await notificationRepository.update(updated);

      expect(await notificationRepository.get(schedule.id), updated);
    });

    test('deletes a schedule', () async {
      final schedule = _notificationSchedule(
        'schedule-1',
        scheduledTime: DateTime.utc(2026, 1, 1, 9),
      );
      await notificationRepository.create(schedule);

      await notificationRepository.delete(schedule.id);

      expect(await notificationRepository.get(schedule.id), isNull);
      expect(await notificationRepository.list(), isEmpty);
    });

    test('sets enabled without replacing payload', () async {
      final schedule = _notificationSchedule(
        'schedule-1',
        scheduledTime: DateTime.utc(2026, 1, 1, 9),
      );
      await notificationRepository.create(schedule);

      await notificationRepository.setEnabled(schedule.id, enabled: false);

      final stored = await notificationRepository.get(schedule.id);
      expect(stored?.enabled, isFalse);
      expect(stored?.payload, schedule.payload);
    });

    test('returns schedules in an inclusive scheduled-time range', () async {
      final start = DateTime.utc(2026, 1, 2, 9);
      final end = DateTime.utc(2026, 1, 2, 18);
      final before = _notificationSchedule(
        'before',
        scheduledTime: DateTime.utc(2026, 1, 2, 8, 59, 59),
      );
      final first = _notificationSchedule('first', scheduledTime: start);
      final second = _notificationSchedule(
        'second',
        scheduledTime: DateTime.utc(2026, 1, 2, 13),
      );
      final third = _notificationSchedule('third', scheduledTime: end);
      final after = _notificationSchedule(
        'after',
        scheduledTime: DateTime.utc(2026, 1, 2, 18, 0, 1),
      );
      await notificationRepository.create(before);
      await notificationRepository.create(first);
      await notificationRepository.create(second);
      await notificationRepository.create(third);
      await notificationRepository.create(after);

      expect(
        await notificationRepository.listScheduledBetween(start, end),
        <NotificationSchedule>[first, second, third],
      );
    });
  });

  group('SqfliteSettingsRepository', () {
    test('sets and gets a setting', () async {
      await settingsRepository.set('test-key', 'test-value');

      final setting = await settingsRepository.get('test-key');

      expect(setting?.key, 'test-key');
      expect(setting?.value, 'test-value');
      expect(setting?.updatedAt.isUtc, isTrue);
    });

    test('upserts an existing setting', () async {
      await settingsRepository.set('test-key', 'old-value');

      await settingsRepository.set('test-key', 'new-value');

      expect((await settingsRepository.get('test-key'))?.value, 'new-value');
      expect(await settingsRepository.list(), hasLength(1));
    });

    test('lists settings ordered by key', () async {
      await settingsRepository.set('b-key', 'b-value');
      await settingsRepository.set('a-key', 'a-value');

      expect(
        (await settingsRepository.list()).map((setting) => setting.key),
        <String>['a-key', 'b-key'],
      );
    });

    test('deletes a setting', () async {
      await settingsRepository.set('test-key', 'test-value');

      await settingsRepository.delete('test-key');

      expect(await settingsRepository.get('test-key'), isNull);
      expect(await settingsRepository.list(), isEmpty);
    });
  });

  group('SqfliteSecurityRepository', () {
    test('returns null before initialization', () async {
      expect(await securityRepository.get(), isNull);
    });

    test('upserts and gets the singleton state', () async {
      final state = SecurityState(
        appLockEnabled: true,
        pinConfigured: true,
        failedUnlockAttempts: 1,
        lockedUntil: DateTime.utc(2026, 1, 1, 12),
        secureKeyReady: true,
        updatedAt: DateTime.utc(2026, 1, 1, 11),
      );
      await securityRepository.update(state);

      final updated = state.copyWith(
        failedUnlockAttempts: 2,
        lockedUntil: DateTime.utc(2026, 1, 1, 13),
        updatedAt: DateTime.utc(2026, 1, 1, 12),
      );
      await securityRepository.update(updated);

      expect(await securityRepository.get(), updated);
      expect(await database.query('security_state'), hasLength(1));
    });
  });

  group('SqfliteAnalyticsRepository', () {
    test('summarizes a UTC range and excludes transfers', () async {
      await _seedAccount(accountRepository, 'account-1');
      final food = await _seedCategory(
        categoryRepository,
        'category-food',
        name: 'Food',
      );
      final transport = await _seedCategory(
        categoryRepository,
        'category-transport',
        name: 'Transport',
      );
      await _seedTransaction(
        transactionRepository,
        id: 'income-in-range',
        amountMinorUnits: 120000,
        timestamp: DateTime.utc(2026, 1, 10),
        type: TransactionType.income,
      );
      await _seedTransaction(
        transactionRepository,
        id: 'expense-food',
        amountMinorUnits: 40000,
        timestamp: DateTime.utc(2026, 1, 15),
        categoryId: food.id,
      );
      await _seedTransaction(
        transactionRepository,
        id: 'expense-transport',
        amountMinorUnits: 20000,
        timestamp: DateTime.utc(2026, 1, 20),
        categoryId: transport.id,
      );
      await _seedTransaction(
        transactionRepository,
        id: 'expense-uncategorized',
        amountMinorUnits: 5000,
        timestamp: DateTime.utc(2026, 1, 25),
      );
      await _seedTransaction(
        transactionRepository,
        id: 'transfer-in-range',
        amountMinorUnits: 100000,
        timestamp: DateTime.utc(2026, 1, 30),
        type: TransactionType.transfer,
      );
      await _seedTransaction(
        transactionRepository,
        id: 'expense-before-range',
        amountMinorUnits: 10000,
        timestamp: DateTime.utc(2025, 12, 31, 23, 59, 59),
      );
      await _seedTransaction(
        transactionRepository,
        id: 'expense-at-end',
        amountMinorUnits: 10000,
        timestamp: DateTime.utc(2026, 2, 1),
      );

      final summary = await analyticsRepository.summaryForRange(
        startUtc: DateTime.utc(2026, 1, 1),
        endUtc: DateTime.utc(2026, 2, 1),
      );

      expect(summary.startUtc, DateTime.utc(2026, 1, 1));
      expect(summary.endUtc, DateTime.utc(2026, 2, 1));
      expect(summary.totalIncomeMinorUnits, 120000);
      expect(summary.totalExpenseMinorUnits, 65000);
      expect(summary.netAmountMinorUnits, 55000);
      expect(summary.categoryExpenseTotals, <CategoryTotal>[
        CategoryTotal(
          categoryId: food.id,
          name: food.name,
          expenseMinorUnits: 40000,
        ),
        CategoryTotal(
          categoryId: transport.id,
          name: transport.name,
          expenseMinorUnits: 20000,
        ),
        const CategoryTotal(
          categoryId: null,
          name: null,
          expenseMinorUnits: 5000,
        ),
      ]);
    });
  });
}

Future<Account> _seedAccount(
  SqfliteAccountRepository repository,
  String id, {
  String? name,
}) async {
  final account = Account(
    id: id,
    name: name ?? 'Account $id',
    type: AccountType.bank,
    currency: 'EGP',
    balanceMinorUnits: 1000,
  );
  await repository.create(account);
  return account;
}

Future<Category> _seedCategory(
  SqfliteCategoryRepository repository,
  String id, {
  String? name,
}) async {
  final category = Category(
    id: id,
    name: name ?? 'Category $id',
    iconKey: 'icon-$id',
    colorHex: '#22C55E',
  );
  await repository.create(category);
  return category;
}

Future<Transaction> _seedTransaction(
  SqfliteTransactionRepository repository, {
  required String id,
  String accountId = 'account-1',
  String? categoryId,
  int amountMinorUnits = 1250,
  DateTime? timestamp,
  TransactionType type = TransactionType.expense,
  TransactionSource source = TransactionSource.manual,
}) async {
  final transaction = Transaction(
    id: id,
    accountId: accountId,
    categoryId: categoryId,
    amountMinorUnits: amountMinorUnits,
    timestamp: timestamp ?? DateTime.utc(2026, 1, 1),
    type: type,
    source: source,
  );
  await repository.create(transaction);
  return transaction;
}

Future<SmsParsingRule> _seedParsingRule(
  SqfliteSmsIngestionRepository repository, {
  required String id,
  required String accountId,
}) async {
  final rule = SmsParsingRule(
    id: id,
    accountId: accountId,
    senderPattern: 'TEST',
    amountPattern: r'EGP\s+(\d+)',
    payeePattern: r'at\s+(.+)',
    enabled: true,
  );
  await repository.createParsingRule(rule);
  return rule;
}

NotificationSchedule _notificationSchedule(
  String id, {
  required DateTime scheduledTime,
}) {
  return NotificationSchedule(
    id: id,
    title: 'Test reminder',
    body: 'Review your spending',
    scheduledTime: scheduledTime,
    repeatInterval: NotificationRepeatInterval.none,
    payload: const <String, Object?>{'route': 'reminders', 'version': 1},
    enabled: true,
  );
}
