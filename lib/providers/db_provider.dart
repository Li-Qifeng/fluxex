import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';

/// 全局 AppDatabase 实例提供者
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// 根据话题 ID 获取缓存的话题
final cachedTopicProvider = FutureProvider.family<CachedTopic?, int>(
  (ref, topicId) async {
    final db = ref.watch(appDatabaseProvider);
    return db.getCachedTopic(topicId);
  },
);

/// 监听全部缓存话题
final cachedTopicsStreamProvider = StreamProvider<List<CachedTopic>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchCachedTopics();
});

/// 监听最近浏览历史（默认 100 条）
final browseHistoryProvider = StreamProvider<List<BrowseHistory>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchBrowseHistory(limit: 100);
});

/// 监听全部收藏，按收藏时间倒序
final bookmarksProvider = StreamProvider<List<Bookmark>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchBookmarks();
});

/// 监听某个话题是否已被收藏
final isBookmarkedProvider = StreamProvider.family<bool, int>(
  (ref, topicId) {
    final db = ref.watch(appDatabaseProvider);
    return db.isBookmarked(topicId);
  },
);
