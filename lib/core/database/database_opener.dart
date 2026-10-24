import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Opens FinEcho's encrypted local database on demand.
///
/// The database is opened lazily so nothing touches secure storage or the
/// file system before the first query. The password is resolved through
/// [passwordProvider] when the database is opened, because reading the key
/// from secure storage must not happen while the application starts.
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
      version: 7,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
    _database = database;
    return database;
  }

  Future<void> _onConfigure(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database database, int version) async {
    await database.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        currency TEXT NOT NULL,
        balance INTEGER NOT NULL DEFAULT 0,
        linked_account_id INTEGER,
        archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        parent_id INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        category_id INTEGER,
        amount INTEGER NOT NULL,
        type TEXT NOT NULL,
        note TEXT,
        payee TEXT,
        timestamp INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id),
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
    await database.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        period_start INTEGER NOT NULL,
        period_end INTEGER NOT NULL,
        warning_share REAL,
        currency TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
    await database.execute('''
      CREATE TABLE speech_drafts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        raw_text TEXT NOT NULL,
        parsed_json TEXT,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE sms_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fingerprint TEXT NOT NULL,
        sender TEXT NOT NULL,
        body TEXT NOT NULL,
        received_at INTEGER NOT NULL,
        parsed_transaction_id INTEGER,
        created_at INTEGER NOT NULL,
        UNIQUE (fingerprint)
      )
    ''');
    await database.execute('''
      CREATE TABLE sms_parsing_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        pattern TEXT NOT NULL,
        category_id INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id),
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
    await database.execute('''
      CREATE TABLE notification_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        schedule_type TEXT NOT NULL,
        cron_expression TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE security_state (
        id INTEGER PRIMARY KEY CHECK (id = 0),
        app_lock_enabled INTEGER NOT NULL,
        pin_configured INTEGER NOT NULL,
        failed_unlock_attempts INTEGER NOT NULL,
        locked_until INTEGER,
        secure_key_ready INTEGER NOT NULL,
        biometrics_enabled INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE onboarding (
        id INTEGER PRIMARY KEY CHECK (id = 0),
        current_step TEXT NOT NULL,
        is_completed INTEGER NOT NULL,
        biometrics_enabled INTEGER NOT NULL,
        sms_automation_enabled INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await database.execute(
      'CREATE INDEX idx_accounts_linked_account'
      ' ON accounts (linked_account_id)',
    );
    await database.execute(
      'CREATE INDEX idx_categories_parent ON categories (parent_id)',
    );
    await database.execute(
      'CREATE INDEX idx_transactions_account ON transactions (account_id)',
    );
    await database.execute(
      'CREATE INDEX idx_transactions_category ON transactions (category_id)',
    );
    await database.execute(
      'CREATE INDEX idx_transactions_timestamp ON transactions (timestamp)',
    );
    await database.execute(
      'CREATE INDEX idx_budgets_category ON budgets (category_id)',
    );
    await database.execute(
      'CREATE INDEX idx_speech_drafts_status ON speech_drafts (status)',
    );
    await database.execute(
      'CREATE INDEX idx_sms_messages_received ON sms_messages (received_at)',
    );
    await database.execute(
      'CREATE INDEX idx_sms_parsing_rules_account'
      ' ON sms_parsing_rules (account_id)',
    );
    await database.execute(
      'CREATE INDEX idx_notification_schedules_time'
      ' ON notification_schedules (cron_expression)',
    );
    await database.execute(
      'CREATE UNIQUE INDEX idx_sms_messages_fingerprint'
      ' ON sms_messages (fingerprint)',
    );
  }

  Future<void> _onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await database.execute(
        'ALTER TABLE accounts ADD COLUMN archived INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await database.execute('''
        CREATE TABLE onboarding (
          id INTEGER PRIMARY KEY CHECK (id = 0),
          current_step TEXT NOT NULL,
          is_completed INTEGER NOT NULL,
          biometrics_enabled INTEGER NOT NULL,
          sms_automation_enabled INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await database.execute(
        'ALTER TABLE security_state '
        'ADD COLUMN biometrics_enabled INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 5) {
      await database.execute('ALTER TABLE transactions ADD COLUMN payee TEXT');
    }
    if (oldVersion < 6) {
      await database.execute(
        'ALTER TABLE budgets ADD COLUMN warning_share REAL',
      );
    }
    if (oldVersion < 7) {
      await database.execute('ALTER TABLE budgets ADD COLUMN currency TEXT');
    }
  }

  Future<void> _onOpen(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
  }
}
