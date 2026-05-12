import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Relational local storage using SQLite (sqflite).
///
/// Persists search queries and their JSON results so the search page
/// works offline and shows a "recent searches" history on startup.
///
/// Note: sqflite is not supported on web — all methods are no-ops when
/// kIsWeb is true so Chrome builds degrade gracefully.
class SearchHistoryDb {
  static Database? _db;
  static const _dbName = 'goatly_search.db';
  static const _version = 1;
  static const _table = 'search_history';

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            query TEXT NOT NULL,
            results TEXT NOT NULL,
            searched_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// INSERT — saves a search query with its serialized results.
  static Future<void> saveSearch(String query, String resultsJson) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert(
      _table,
      {
        'query': query.toLowerCase().trim(),
        'results': resultsJson,
        'searched_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// SELECT — loads the 10 most recent searches.
  static Future<List<Map<String, dynamic>>> getRecentSearches() async {
    if (kIsWeb) return [];
    final db = await database;
    return db.query(_table, orderBy: 'searched_at DESC', limit: 10);
  }

  /// SELECT — finds a previously cached result for the given query.
  static Future<Map<String, dynamic>?> findCachedQuery(String query) async {
    if (kIsWeb) return null;
    final db = await database;
    final rows = await db.query(
      _table,
      where: 'query = ?',
      whereArgs: [query.toLowerCase().trim()],
      orderBy: 'searched_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// DELETE — removes searches older than 7 days.
  static Future<void> pruneOld() async {
    if (kIsWeb) return;
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 7))
        .toIso8601String();
    await db.delete(_table, where: 'searched_at < ?', whereArgs: [cutoff]);
  }
}
