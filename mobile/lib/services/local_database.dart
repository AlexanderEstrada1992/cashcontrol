import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static const _databaseName = 'cashcontrol.db';
  static const _databaseVersion = 3;
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final databasesPath = await getDatabasesPath();
    _database = await openDatabase(
      p.join(databasesPath, _databaseName),
      version: _databaseVersion,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE expenses ADD COLUMN last_synced_at TEXT',
          );
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE expenses ADD COLUMN receipt_photo_path TEXT');
          await db.execute('ALTER TABLE expenses ADD COLUMN latitude REAL');
          await db.execute('ALTER TABLE expenses ADD COLUMN longitude REAL');
        }
      },
    );
    return _database!;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE expenses (
        local_id TEXT PRIMARY KEY,
        server_id INTEGER,
        client_operation_id TEXT NOT NULL UNIQUE,
        user_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        expense_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        last_synced_at TEXT,
        receipt_photo_path TEXT,
        latitude REAL,
        longitude REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE pending_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_operation_id TEXT NOT NULL UNIQUE,
        operation_type TEXT NOT NULL,
        entity TEXT NOT NULL,
        payload TEXT NOT NULL,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        next_attempt_at TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        user_id TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> clearUserData(String userId) async {
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.delete('expenses', where: 'user_id = ?', whereArgs: [userId]);
      await transaction.delete('pending_operations', where: 'user_id = ?', whereArgs: [userId]);
      await transaction.delete('app_metadata', where: "key = 'last_sync_$userId'");
    });
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}