import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/waste_category.dart';
import '../models/disposal_point.dart';
import 'seed_data.dart';
import 'disposal_points_seed.dart';

// Points awarded per category when a user marks an item as disposed.
const Map<String, int> ecoPointsPerCategory = {
  'Electronics': 50,
  'Batteries': 20,
  'Clothing': 30,
  'Plastic': 15,
};

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'wastewise.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        icon TEXT NOT NULL,
        disposal_type TEXT NOT NULL,
        guidance_text TEXT NOT NULL,
        warning_text TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE disposal_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        categories_accepted TEXT NOT NULL,
        source TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE eco_points_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_name TEXT NOT NULL,
        points_earned INTEGER NOT NULL,
        disposed_at TEXT NOT NULL
      )
    ''');

    await _seedData(db);
  }

  // Runs once, right after the tables are created.
  Future<void> _seedData(Database db) async {
    final batch = db.batch();
    for (final c in wasteCategories) {
      batch.insert('categories', c.toMap());
    }
    for (final p in disposalPoints) {
      batch.insert('disposal_points', p.toMap());
    }
    await batch.commit(noResult: true);
  }

  // ---------- Reads ----------

  Future<List<WasteCategory>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories');
    return rows.map(WasteCategory.fromMap).toList();
  }

  /// All points, or only those accepting [category] (e.g. "Electronics").
  Future<List<DisposalPoint>> getDisposalPoints({String? category}) async {
    final db = await database;
    final rows = await db.query('disposal_points');
    final points = rows.map(DisposalPoint.fromMap).toList();
    if (category == null) return points;
    return points.where((p) => p.categoriesAccepted.contains(category)).toList();
  }

  // ---------- Eco Points ----------

  /// Logs a disposal and returns the points earned.
  Future<int> addEcoPoints(String categoryName) async {
    final db = await database;
    final points = ecoPointsPerCategory[categoryName] ?? 10;
    await db.insert('eco_points_log', {
      'category_name': categoryName,
      'points_earned': points,
      'disposed_at': DateTime.now().toIso8601String(),
    });
    return points;
  }

  Future<int> getTotalEcoPoints() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(points_earned), 0) AS total FROM eco_points_log',
    );
    return (result.first['total'] as num).toInt();
  }

  /// Newest first, for a "recent activity" list.
  Future<List<Map<String, dynamic>>> getEcoPointsLog() async {
    final db = await database;
    return db.query('eco_points_log', orderBy: 'disposed_at DESC');
  }
}