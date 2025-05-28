import 'package:sqflite/sqflite.dart';

/// Defines the database schema and handles migrations
class AppDatabase {
  // Database information
  static const String databaseName = 'focus_block.db';
  static const int databaseVersion = 1;

  // Table names
  static const String tableUsers = 'users';
  static const String tableBlockedApps = 'blocked_apps';
  static const String tableSchedules = 'schedules';
  static const String tableScheduleDays = 'schedule_days';
  static const String tableScheduleApps = 'schedule_apps';
  static const String tableQuickBlocks = 'quick_blocks';
  static const String tableQuickBlockApps = 'quick_block_apps';
  static const String tableUsageLogs = 'usage_logs';

  /// Create all tables in the database
  static Future<void> createTables(Database db) async {
    // Users table
    await db.execute('''
      CREATE TABLE $tableUsers (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        full_name TEXT NOT NULL,
        mobile TEXT,
        profile_image_path TEXT,
        auth_provider INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        notification_preferences TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        modified_at INTEGER NOT NULL,
        subscription_tier TEXT NOT NULL DEFAULT 'free',
        subscription_expiry_date INTEGER
      )
    ''');

    // Blocked Apps table
    await db.execute('''
      CREATE TABLE $tableBlockedApps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        app_package TEXT NOT NULL,
        app_name TEXT NOT NULL,
        app_icon_path TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE,
        UNIQUE(user_id, app_package)
      )
    ''');

    // Schedules table
    await db.execute('''
      CREATE TABLE $tableSchedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        end_date INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE
      )
    ''');

    // Schedule days table (many-to-many relationship)
    await db.execute('''
      CREATE TABLE $tableScheduleDays (
        schedule_id INTEGER NOT NULL,
        day INTEGER NOT NULL, 
        PRIMARY KEY (schedule_id, day),
        FOREIGN KEY (schedule_id) REFERENCES $tableSchedules (id) ON DELETE CASCADE
      )
    ''');

    // Schedule apps table (many-to-many relationship)
    await db.execute('''
      CREATE TABLE $tableScheduleApps (
        schedule_id INTEGER NOT NULL,
        app_package TEXT NOT NULL,
        PRIMARY KEY (schedule_id, app_package),
        FOREIGN KEY (schedule_id) REFERENCES $tableSchedules (id) ON DELETE CASCADE
      )
    ''');

    // Quick blocks table
    await db.execute('''
      CREATE TABLE $tableQuickBlocks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE
      )
    ''');

    // Quick block apps table (many-to-many relationship)
    await db.execute('''
      CREATE TABLE $tableQuickBlockApps (
        quick_block_id INTEGER NOT NULL,
        app_package TEXT NOT NULL,
        PRIMARY KEY (quick_block_id, app_package),
        FOREIGN KEY (quick_block_id) REFERENCES $tableQuickBlocks (id) ON DELETE CASCADE
      )
    ''');

    // Usage logs table
    await db.execute('''
      CREATE TABLE $tableUsageLogs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        app_package TEXT NOT NULL,
        block_type TEXT NOT NULL,
        block_id INTEGER NOT NULL,
        attempt_time INTEGER NOT NULL,
        block_successful INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for frequent queries
    await db.execute(
        'CREATE INDEX idx_blocked_apps_user_id ON $tableBlockedApps (user_id)');
    await db.execute(
        'CREATE INDEX idx_schedules_user_id ON $tableSchedules (user_id)');
    await db.execute(
        'CREATE INDEX idx_quick_blocks_user_id ON $tableQuickBlocks (user_id)');
    await db.execute(
        'CREATE INDEX idx_usage_logs_user_id ON $tableUsageLogs (user_id)');
    await db.execute(
        'CREATE INDEX idx_usage_logs_app_package ON $tableUsageLogs (app_package)');
  }

  /// Upgrade database from oldVersion to newVersion
  static Future<void> upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    // Handle incremental upgrades
    if (oldVersion < 2 && newVersion >= 2) {
      // Example: Add a new column to users table
      // await db.execute('ALTER TABLE $tableUsers ADD COLUMN new_column TEXT');
    }

    if (oldVersion < 3 && newVersion >= 3) {
      // Future upgrade would go here
    }
  }

  /// Downgrade database from oldVersion to newVersion (used in development)
  static Future<void> downgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    // For simplicity, we recreate all tables
    await dropTables(db);
    await createTables(db);
  }

  /// Drop all tables from the database
  static Future<void> dropTables(Database db) async {
    // Drop tables in order to respect foreign key constraints
    await db.execute('DROP TABLE IF EXISTS $tableUsageLogs');
    await db.execute('DROP TABLE IF EXISTS $tableQuickBlockApps');
    await db.execute('DROP TABLE IF EXISTS $tableQuickBlocks');
    await db.execute('DROP TABLE IF EXISTS $tableScheduleApps');
    await db.execute('DROP TABLE IF EXISTS $tableScheduleDays');
    await db.execute('DROP TABLE IF EXISTS $tableSchedules');
    await db.execute('DROP TABLE IF EXISTS $tableBlockedApps');
    await db.execute('DROP TABLE IF EXISTS $tableUsers');
  }

  /// Get the SQL creation statement for a table (for debugging purposes)
  static Future<String?> getTableCreationSql(
      Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT sql FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );

    if (result.isNotEmpty) {
      return result.first['sql'] as String?;
    }

    return null;
  }

  /// Get a list of all tables in the database
  static Future<List<String>> getAllTables(Database db) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
    );

    return result.map((row) => row['name'] as String).toList();
  }

  /// Check if database structure is valid (for debugging and testing)
  static Future<bool> validateDatabaseStructure(Database db) async {
    final expectedTables = [
      tableUsers,
      tableBlockedApps,
      tableSchedules,
      tableScheduleDays,
      tableScheduleApps,
      tableQuickBlocks,
      tableQuickBlockApps,
      tableUsageLogs,
    ];

    final actualTables = await getAllTables(db);

    // Check if all expected tables exist
    for (var table in expectedTables) {
      if (!actualTables.contains(table)) {
        print('Missing table: $table');
        return false;
      }
    }

    // Additional validation could be done here, like checking columns

    return true;
  }
}
