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
      version: 4,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            ALTER TABLE browse_history ADD COLUMN last_floor INTEGER DEFAULT 0
          ''');
          await db.execute('''
            ALTER TABLE browse_history ADD COLUMN scroll_offset INTEGER DEFAULT 0
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE node_follows (
              node_name TEXT PRIMARY KEY,
              node_title TEXT NOT NULL,
              followed_at INTEGER NOT NULL
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE drafts (
              draft_id TEXT PRIMARY KEY,
              type TEXT NOT NULL,
              title TEXT,
              content TEXT NOT NULL,
              extra TEXT,
              saved_at INTEGER NOT NULL
            )
          ''');
        }
      },
    );
  }

  static Future<void> _createTables(Database db) async {
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
        viewed_at INTEGER NOT NULL,
        last_floor INTEGER DEFAULT 0,
        scroll_offset INTEGER DEFAULT 0
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
    await db.execute('''
      CREATE TABLE node_follows (
        node_name TEXT PRIMARY KEY,
        node_title TEXT NOT NULL,
        followed_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE drafts (
        draft_id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT,
        content TEXT NOT NULL,
        extra TEXT,
        saved_at INTEGER NOT NULL
      )
    ''');
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
  static Future<void> addBrowseHistory(int topicId, String title, {int lastFloor = 0, int scrollOffset = 0}) async {
    final db = await database;
    if (title.isEmpty) {
      final rows = await db.query('browse_history',
        where: 'topic_id = ?', whereArgs: [topicId], limit: 1);
      if (rows.isNotEmpty) {
        title = (rows.first['title'] as String?) ?? '';
      }
    }
    await db.insert('browse_history', {
      'topic_id': topicId,
      'title': title,
      'viewed_at': DateTime.now().millisecondsSinceEpoch,
      'last_floor': lastFloor,
      'scroll_offset': scrollOffset,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getBrowseHistoryEntry(int topicId) async {
    final db = await database;
    final rows = await db.query('browse_history',
      where: 'topic_id = ?',
      whereArgs: [topicId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
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

  // ========== Node Follows ==========
  static Future<void> followNode(String nodeName, String nodeTitle) async {
    final db = await database;
    await db.insert('node_follows', {
      'node_name': nodeName,
      'node_title': nodeTitle,
      'followed_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> unfollowNode(String nodeName) async {
    final db = await database;
    await db.delete('node_follows', where: 'node_name = ?', whereArgs: [nodeName]);
  }

  static Future<bool> isNodeFollowed(String nodeName) async {
    final db = await database;
    final rows = await db.query('node_follows', where: 'node_name = ?', whereArgs: [nodeName]);
    return rows.isNotEmpty;
  }

  static Future<List<Map<String, dynamic>>> getFollowedNodes() async {
    final db = await database;
    return db.query('node_follows', orderBy: 'followed_at DESC');
  }

  // ========== Drafts ==========
  static Future<void> saveDraft({
    required String draftId,
    required String type,
    String? title,
    required String content,
    String? extra,
  }) async {
    final db = await database;
    await db.insert('drafts', {
      'draft_id': draftId,
      'type': type,
      'title': title,
      'content': content,
      'extra': extra,
      'saved_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getDraft(String draftId) async {
    final db = await database;
    final rows = await db.query('drafts',
      where: 'draft_id = ?',
      whereArgs: [draftId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  static Future<void> deleteDraft(String draftId) async {
    final db = await database;
    await db.delete('drafts', where: 'draft_id = ?', whereArgs: [draftId]);
  }

  // ========== Read Tracking ==========
  static Future<bool> isTopicRead(int topicId) async {
    final db = await database;
    final rows = await db.query('browse_history',
      where: 'topic_id = ?',
      whereArgs: [topicId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
