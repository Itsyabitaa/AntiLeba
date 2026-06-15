import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:anti_leba/features/tracking/domain/location_point.dart';

class LocationLocalDataSource {
  LocationLocalDataSource(this._openDb);

  final Future<Database> Function() _openDb;

  Future<int> insert(LocationPoint point) async {
    final db = await _openDb();
    return db.insert('pending_locations', point.toDbMap());
  }

  Future<List<LocationPoint>> getUnsynced({int limit = 100}) async {
    final db = await _openDb();
    final rows = await db.query(
      'pending_locations',
      where: 'synced = ?',
      whereArgs: <Object>[0],
      orderBy: 'recorded_at ASC',
      limit: limit,
    );
    return rows.map(LocationPoint.fromDbMap).toList();
  }

  Future<int> countUnsynced() async {
    final db = await _openDb();
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM pending_locations WHERE synced = 0',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> markSynced(List<int> localIds) async {
    if (localIds.isEmpty) return;
    final db = await _openDb();
    final placeholders = List.filled(localIds.length, '?').join(',');
    await db.delete(
      'pending_locations',
      where: 'id IN ($placeholders)',
      whereArgs: localIds,
    );
  }
}

class AppDatabase {
  AppDatabase._();

  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final basePath = await getDatabasesPath();
    final path = join(basePath, 'anti_leba.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            device_id TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            accuracy REAL,
            altitude REAL,
            speed REAL,
            heading REAL,
            recorded_at TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_pending_unsynced ON pending_locations(synced, recorded_at)',
        );
      },
    );
    return _db!;
  }
}
