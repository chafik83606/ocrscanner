import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/scan_model.dart';
import '../utils/app_constants.dart';

/// Service de persistance locale des scans (SQLite via sqflite).
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${AppConstants.tableName} (
            id           TEXT PRIMARY KEY,
            imagePath    TEXT NOT NULL,
            extractedText TEXT NOT NULL,
            language     TEXT NOT NULL,
            createdAt    TEXT NOT NULL,
            title        TEXT
          )
        ''');
      },
    );
  }

  // ─── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> insertScan(ScanModel scan) async {
    final db = await database;
    await db.insert(
      AppConstants.tableName,
      scan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ScanModel>> getAllScans() async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableName,
      orderBy: 'createdAt DESC',
    );
    return rows.map(ScanModel.fromMap).toList();
  }

  Future<List<ScanModel>> searchScans(String query) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableName,
      where: 'extractedText LIKE ? OR title LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return rows.map(ScanModel.fromMap).toList();
  }

  Future<void> deleteScan(String id) async {
    final db = await database;
    await db.delete(AppConstants.tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateScan(ScanModel scan) async {
    final db = await database;
    await db.update(
      AppConstants.tableName,
      scan.toMap(),
      where: 'id = ?',
      whereArgs: [scan.id],
    );
  }
}
