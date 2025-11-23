import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/notification_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notifications.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_name TEXT NOT NULL,
        app_name TEXT NOT NULL,
        title TEXT NOT NULL,
        text TEXT NOT NULL,
        sub_text TEXT,
        big_text TEXT,
        timestamp INTEGER NOT NULL,
        key TEXT
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_timestamp ON notifications(timestamp DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_package_name ON notifications(package_name)
    ''');
  }

  Future<int> insertNotification(NotificationModel notification) async {
    final db = await database;
    return await db.insert('notifications', notification.toDatabase());
  }

  Future<List<NotificationModel>> getNotifications({
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;
    final maps = await db.query(
      'notifications',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => NotificationModel.fromDatabase(map)).toList();
  }

  Future<List<NotificationModel>> getNotificationsByPackage(
    String packageName, {
    int limit = 100,
  }) async {
    final db = await database;
    final maps = await db.query(
      'notifications',
      where: 'package_name = ?',
      whereArgs: [packageName],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => NotificationModel.fromDatabase(map)).toList();
  }

  Future<int> getNotificationCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM notifications');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, String>>> getDistinctApps() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT package_name, app_name
      FROM notifications
      ORDER BY app_name
    ''');

    return result.map((row) => {
      'packageName': row['package_name'] as String,
      'appName': row['app_name'] as String,
    }).toList();
  }

  Future<int> deleteNotification(int id) async {
    final db = await database;
    return await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteOldNotifications(int daysToKeep) async {
    final db = await database;
    final cutoffTime = DateTime.now().millisecondsSinceEpoch - (daysToKeep * 24 * 60 * 60 * 1000);
    return await db.delete(
      'notifications',
      where: 'timestamp < ?',
      whereArgs: [cutoffTime],
    );
  }

  Future<int> clearAllNotifications() async {
    final db = await database;
    return await db.delete('notifications');
  }

  Future<int> deleteNotificationsByPackages(List<String> packageNames) async {
    if (packageNames.isEmpty) return 0;

    final db = await database;
    final placeholders = List.filled(packageNames.length, '?').join(',');
    return await db.delete(
      'notifications',
      where: 'package_name IN ($placeholders)',
      whereArgs: packageNames,
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
