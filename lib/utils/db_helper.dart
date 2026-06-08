import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fluxex.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_topics (
            id INTEGER PRIMARY KEY,
            json TEXT NOT NULL,
            tab TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE browse_history (
            topic_id INTEGER PRIMARY KEY,
            title TEXT,
            viewed_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE bookmarks (
            topic_id INTEGER PRIMARY KEY,
            title TEXT,
            note TEXT,
            bookmarked_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // ========== Cached Topics ==========
  static Future<void> cacheTopics(String tab, List<Map<String, dynamic>> topics) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('cached_topics', where: 'tab = ?', whereArgs: [tab]);
    for (final t in topics) {
      batch.insert('cached_topics', {
        'id': t['id'],
        'json': jsonEncode(t),
        'tab': tab,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getCachedTopics(String tab) async {
    final db = await database;
    final rows = await db.query('cached_topics',
      where: 'tab = ?',
      whereArgs: [tab],
      orderBy: 'id DESC',
    );
    return rows.map((r) => jsonDecode(r['json'] as String) as Map<String, dynamic>).toList();
  }

  // ========== Browse History ==========
  static Future<void> addBrowseHistory(int topicId, String title) async {
    final db = await database;
    await db.insert('browse_history', {
      'topic_id': topicId,
      'title': title,
      'viewed_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getBrowseHistory({int limit = 50}) async {
    final db = await database;
    return db.query('browse_history', orderBy: 'viewed_at DESC', limit: limit);
  }

  // ========== Bookmarks ==========
  static Future<void> addBookmark(int topicId, String title, {String? note}) async {
    final db = await database;
    await db.insert('bookmarks', {
      'topic_id': topicId,
      'title': title,
      'note': note ?? '',
      'bookmarked_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> removeBookmark(int topicId) async {
    final db = await database;
    await db.delete('bookmarks', where: 'topic_id = ?', whereArgs: [topicId]);
  }

  static Future<bool> isBookmarked(int topicId) async {
    final db = await database;
    final rows = await db.query('bookmarks', where: 'topic_id = ?', whereArgs: [topicId]);
    return rows.isNotEmpty;
  }

  static Future<List<Map<String, dynamic>>> getBookmarks() async {
    final db = await database;
    return db.query('bookmarks', orderBy: 'bookmarked_at DESC');
  }
}
