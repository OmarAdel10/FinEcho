/// The SQLCipher schema used by FinEcho's local database.
abstract final class AppSchema {
  /// The current schema version.
  static const int version = 1;

  static const String _createAccounts =
      'CREATE TABLE accounts (\n'
      '  id TEXT PRIMARY KEY,\n'
      '  name TEXT NOT NULL,\n'
      '  type TEXT NOT NULL,\n'
      '  currency TEXT NOT NULL,\n'
      '  balance_minor_units INTEGER NOT NULL,\n'
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

  /// Ordered statements that create version 1 tables and indexes.
  static const List<String> statements = <String>[
    _createAccounts,
    _createCategories,
    _createTransactions,
    _createBudgets,
    _indexAccountsLinkedAccount,
    _indexCategoriesParent,
    _indexTransactionsAccount,
    _indexTransactionsCategory,
    _indexTransactionsTimestamp,
    _indexBudgetsCategory,
  ];
}
