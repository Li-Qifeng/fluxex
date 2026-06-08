import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// 缓存话题表，用于存储热门/最新话题的 JSON 数据
class CachedTopics extends Table {
  /// 话题 ID，主键
  IntColumn get topicId => integer()();

  /// 话题原始 JSON 文本
  TextColumn get topicJson => text()();

  /// 缓存更新时间
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {topicId};
}

/// 浏览历史表，记录用户查看过的话题
class BrowseHistories extends Table {
  /// 自增主键
  IntColumn get id => integer().autoIncrement()();

  /// 话题 ID
  IntColumn get topicId => integer()();

  /// 查看时间
  DateTimeColumn get viewedAt => dateTime()();
}

/// 收藏表，记录用户收藏的话题及备注
class Bookmarks extends Table {
  /// 话题 ID，主键
  IntColumn get topicId => integer()();

  /// 收藏时间
  DateTimeColumn get bookmarkedAt => dateTime()();

  /// 可选备注
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {topicId};
}

@DriftDatabase(tables: [CachedTopics, BrowseHistories, Bookmarks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  /// 打开本地 SQLite 数据库连接
  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'fluxex.db'));
      return NativeDatabase(file);
    });
  }

  // ==================== 缓存话题操作 ====================

  /// 缓存或更新话题 JSON
  Future<void> cacheTopic(int topicId, Map<String, dynamic> json) async {
    await into(cachedTopics).insertOnConflictUpdate(
      CachedTopicsCompanion(
        topicId: Value(topicId),
        topicJson: Value(jsonEncode(json)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 根据话题 ID 获取缓存的话题
  Future<CachedTopic?> getCachedTopic(int topicId) async {
    return await (select(cachedTopics)
          ..where((t) => t.topicId.equals(topicId)))
        .getSingleOrNull();
  }

  /// 获取全部缓存话题，按更新时间倒序
  Stream<List<CachedTopic>> watchCachedTopics() {
    return (select(cachedTopics)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  /// 删除指定缓存话题
  Future<void> deleteCachedTopic(int topicId) async {
    await (delete(cachedTopics)..where((t) => t.topicId.equals(topicId))).go();
  }

  // ==================== 浏览历史操作 ====================

  /// 记录一次浏览
  Future<void> recordBrowseHistory(int topicId) async {
    await into(browseHistories).insert(
      BrowseHistoriesCompanion(
        topicId: Value(topicId),
        viewedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 获取最近浏览历史，默认最多 100 条
  Stream<List<BrowseHistory>> watchBrowseHistory({int limit = 100}) {
    return (select(browseHistories)
          ..orderBy([(t) => OrderingTerm.desc(t.viewedAt)])
          ..limit(limit))
        .watch();
  }

  /// 删除单条浏览记录
  Future<void> deleteBrowseHistory(int id) async {
    await (delete(browseHistories)..where((t) => t.id.equals(id))).go();
  }

  /// 清空浏览历史
  Future<void> clearBrowseHistory() async {
    await delete(browseHistories).go();
  }

  // ==================== 收藏操作 ====================

  /// 添加或更新收藏
  Future<void> addBookmark(int topicId, {String? note}) async {
    await into(bookmarks).insertOnConflictUpdate(
      BookmarksCompanion(
        topicId: Value(topicId),
        bookmarkedAt: Value(DateTime.now()),
        note: Value(note),
      ),
    );
  }

  /// 移除收藏
  Future<void> removeBookmark(int topicId) async {
    await (delete(bookmarks)..where((t) => t.topicId.equals(topicId))).go();
  }

  /// 监听全部收藏，按收藏时间倒序
  Stream<List<Bookmark>> watchBookmarks() {
    return (select(bookmarks)
          ..orderBy([(t) => OrderingTerm.desc(t.bookmarkedAt)]))
        .watch();
  }

  /// 监听某个话题是否已被收藏
  Stream<bool> isBookmarked(int topicId) {
    final query = select(bookmarks)
      ..where((t) => t.topicId.equals(topicId));
    return query.watchSingleOrNull().map((row) => row != null);
  }

  /// 根据话题 ID 获取收藏
  Future<Bookmark?> getBookmark(int topicId) async {
    return await (select(bookmarks)
          ..where((t) => t.topicId.equals(topicId)))
        .getSingleOrNull();
  }
}
