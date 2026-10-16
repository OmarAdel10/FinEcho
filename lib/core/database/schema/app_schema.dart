/// The SQLCipher schema used by FinEcho's local database.
abstract final class AppSchema {
  /// The current schema version.
  static const int version = 2;

  static const String _createAccounts =
      'CREATE TABLE accounts (\n'
      '  id TEXT PRIMARY KEY,\n'
      '  name TEXT NOT NULL,\n'
      '  type TEXT NOT NULL,\n'
      '  currency TEXT NOT NULL,\n'
      '  balance_minor_units INTEGER NOT NULL,\n'
      '  archived INTEGER NOT NULL DEFAULT 0,\n'
      '  masked_identifier TEXT,\n'
      '  linked_account_id TEXT,\n'
      '  credit_limit_minor_units INTEGER,\n'
      '  outstanding_balance_minor_units INTEGER,\n'
      '  FOREIGN KEY(linked_account_id)\n'
      '    REFERENCES accounts(id) ON DELETE SET NULL\n'
      ')';

  static const String _createCategories =
      'CREATE TABLE categories (\n'
      '  id TEXT PRIMARY KEY,\n'
      '  parent_id TEXT,\n'
      '  name TEXT NOT NULL,\n'
      '  icon_key TEXT NOT NULL,\n'
      '  color_hex TEXT NOT NULL,\n'
      '  FOREIGN KEY(parent_id)\n'
      '    REFERENCES categories(id) ON DELETE CASCADE\n'
      ')';

  static const String _createTransactions =
      'CREATE TABLE transactions (\n'
      '  id TEXT PRIMARY KEY,\n'
      '  account_id TEXT NOT NULL,\n'
      '  category_id TEXT,\n'
      '  amount_minor_units INTEGER NOT NULL,\n'
      '  timestamp INTEGER NOT NULL,\n'
      '  type TEXT NOT NULL,\n'
      '  source TEXT NOT NULL,\n'
      '  raw_text TEXT,\n'
      '  FOREIGN KEY(account_id)\n'
      '    REFERENCES accounts(id) ON DELETE CASCADE,\n'
      '  FOREIGN KEY(category_id)\n'
      '    REFERENCES categories(id) ON DELETE SET NULL\n'
      ')';

  static const String _createBudgets =
      'CREATE TABLE budgets (\n'
      '  id TEXT PRIMARY KEY,\n'
      '  category_id TEXT NOT NULL,\n'
      '  allocated_amount_minor_units INTEGER NOT NULL,\n'
      '  period TEXT NOT NULL,\n'
      '  start_date INTEGER NOT NULL,\n'
      '  FOREIGN KEY(category_id)\n'
      '    REFERENCES categories(id) ON DELETE CASCADE\n'
      ')';

  static const String _createSpeechDrafts =
      'CREATE TABLE speech_drafts (\n'
      '  id TEXT PRIMARY KEY,\n'
      '  transcript TEXT NOT NULL,\n'
      '  parsed_amount_minor_units INTEGER,\n'
      '  parsed_payee TEXT,\n'
      '  parsed_category_id TEXT,\n'
      '  confidence REAL,\n'
      '  status TEXT NOT NULL,\n'
      '  created_at INTEGER NOT NULL,\n'
      '  updated_at INTEGER NOT NULL\n'
      ')';

  static const String _createSmsMessages =
      'CREATE TABLE sms_messages (\n'
      '  id TEXT PRIMARY KEY,\n'
      '  sender TEXT NOT NULL,\n'
      '  received_at INTEGER NOT NULL,\n'
      '  fingerprint TEXT NOT NULL,\n'
      '  account_id TEXT,\n'
      '  parsed_payload TEXT,\n'
      '  status TEXT NOT NULL,\n'
      '  FOREIGN KEY(account_id)\n'
      '    REFERENCES accounts(id) ON DELETE SET NULL\n'
      ')';

  static const String _createSmsParsingRules =
      'CREATE TABLE sms_parsing_rules (\n'
      '  id TEXT PRIMARY KEY,\n'
      '  account_id TEXT NOT NULL,\n'
      '  sender_pattern TEXT NOT NULL,\n'
      '  amount_pattern TEXT NOT NULL,\n'
      '  payee_pattern TEXT NOT NULL,\n'
      '  enabled INTEGER NOT NULL,\n'
      '  FOREIGN KEY(account_id)\n'
      '    REFERENCES accounts(id) ON DELETE CASCADE\n'
      ')';

  static const String _createNotificationSchedules =
      'CREATE TABLE notification_schedules (\n'
      '  id TEXT PRIMARY KEY,\n'
      '  title TEXT NOT NULL,\n'
      '  body TEXT NOT NULL,\n'
      '  scheduled_time INTEGER NOT NULL,\n'
      '  repeat_interval TEXT NOT NULL,\n'
      '  payload TEXT NOT NULL,\n'
      '  enabled INTEGER NOT NULL\n'
      ')';

  static const String _createAppSettings =
      'CREATE TABLE app_settings (\n'
      '  key TEXT PRIMARY KEY,\n'
      '  value TEXT NOT NULL,\n'
      '  updated_at INTEGER NOT NULL\n'
      ')';

  static const String _createSecurityState =
      'CREATE TABLE security_state (\n'
      '  id INTEGER PRIMARY KEY CHECK (id = 0),\n'
      '  app_lock_enabled INTEGER NOT NULL,\n'
      '  pin_configured INTEGER NOT NULL,\n'
      '  failed_unlock_attempts INTEGER NOT NULL,\n'
      '  locked_until INTEGER,\n'
      '  secure_key_ready INTEGER NOT NULL,\n'
      '  updated_at INTEGER NOT NULL\n'
      ')';

  static const String _indexAccountsLinkedAccount =
      'CREATE INDEX idx_accounts_linked_account_id '
      'ON accounts(linked_account_id)';

  static const String _indexCategoriesParent =
      'CREATE INDEX idx_categories_parent_id ON categories(parent_id)';

  static const String _indexTransactionsAccount =
      'CREATE INDEX idx_transactions_account_id '
      'ON transactions(account_id)';

  static const String _indexTransactionsCategory =
      'CREATE INDEX idx_transactions_category_id '
      'ON transactions(category_id)';

  static const String _indexTransactionsTimestamp =
      'CREATE INDEX idx_transactions_timestamp '
      'ON transactions(timestamp)';

  static const String _indexBudgetsCategory =
      'CREATE INDEX idx_budgets_category_id ON budgets(category_id)';

  static const String _indexSpeechDraftsStatus =
      'CREATE INDEX idx_speech_drafts_status ON speech_drafts(status)';

  static const String _indexSmsMessagesReceived =
      'CREATE INDEX idx_sms_messages_received_at '
      'ON sms_messages(received_at)';

  static const String _indexSmsParsingRulesAccount =
      'CREATE INDEX idx_sms_parsing_rules_account_id '
      'ON sms_parsing_rules(account_id)';

  static const String _indexNotificationSchedulesTime =
      'CREATE INDEX idx_notification_schedules_scheduled_time '
      'ON notification_schedules(scheduled_time)';

  static const String _uniqueIndexSmsMessagesFingerprint =
      'CREATE UNIQUE INDEX idx_sms_messages_fingerprint '
      'ON sms_messages(fingerprint)';

  /// Ordered statements that create version 1 tables and indexes.
  static const List<String> statements = <String>[
    _createAccounts,
    _createCategories,
    _createTransactions,
    _createBudgets,
    _createSpeechDrafts,
    _createSmsMessages,
    _createSmsParsingRules,
    _createNotificationSchedules,
    _createAppSettings,
    _createSecurityState,
    _indexAccountsLinkedAccount,
    _indexCategoriesParent,
    _indexTransactionsAccount,
    _indexTransactionsCategory,
    _indexTransactionsTimestamp,
    _indexBudgetsCategory,
    _indexSpeechDraftsStatus,
    _indexSmsMessagesReceived,
    _indexSmsParsingRulesAccount,
    _indexNotificationSchedulesTime,
    _uniqueIndexSmsMessagesFingerprint,
  ];
}
