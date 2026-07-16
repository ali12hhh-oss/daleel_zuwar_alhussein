import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class FatwaCacheService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fatwas_cache.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE fatwas ('
          'id INTEGER PRIMARY KEY AUTOINCREMENT,'
          'title TEXT NOT NULL,'
          'link TEXT NOT NULL,'
          'description TEXT,'
          'pub_date TEXT NOT NULL,'
          'scholar_id TEXT NOT NULL,'
          'cached_at TEXT NOT NULL'
          ')',
        );
      },
    );
  }

  /// حفظ الاستفتاءات
  static Future<void> saveFatwas(List<FatwaItem> fatwas) async {
    final db = await database;
    final batch = db.batch();

    for (final fatwa in fatwas) {
      batch.insert('fatwas', {
        'title': fatwa.title,
        'link': fatwa.link,
        'description': fatwa.description,
        'pub_date': fatwa.pubDate.toIso8601String(),
        'scholar_id': fatwa.scholarId,
        'cached_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /// جلب الاستفتاءات المحفوظة
  static Future<List<FatwaItem>> getCachedFatwas(String scholarId) async {
    final db = await database;
    final maps = await db.query(
      'fatwas',
      where: 'scholar_id = ?',
      whereArgs: [scholarId],
      orderBy: 'pub_date DESC',
    );

    return maps.map((map) => FatwaItem(
      title: map['title'] as String,
      link: map['link'] as String,
      description: map['description'] as String? ?? '',
      pubDate: DateTime.parse(map['pub_date'] as String),
      scholarId: map['scholar_id'] as String,
    )).toList();
  }

  /// التحقق من وجود بيانات محفوظة
  static Future<bool> hasCachedData(String scholarId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM fatwas WHERE scholar_id = ?',
      [scholarId],
    ));
    return (count ?? 0) > 0;
  }

  /// حذف الاستفتاءات القديمة (اكثر من 30 يوم)
  static Future<void> clearOldFatwas() async {
    final db = await database;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    await db.delete(
      'fatwas',
      where: 'cached_at < ?',
      whereArgs: [thirtyDaysAgo.toIso8601String()],
    );
  }
}
