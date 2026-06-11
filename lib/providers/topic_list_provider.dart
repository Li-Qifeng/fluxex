import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/topic.dart';
import '../models/topic_list_result.dart';
import '../utils/db_helper.dart';
import 'api_client.dart';

enum TopicTab { hot, latest, followed }

final topicTabProvider = StateProvider<TopicTab>((ref) => TopicTab.hot);

final hotTopicsProvider = FutureProvider<TopicListResult>((ref) async {
  try {
    final api = V2exApiClient();
    final data = await api.getHotTopics();
    final topics = data.map((e) => Topic.fromJson(e as Map<String, dynamic>)).toList();
    await DbHelper.cacheTopics('hot', data.cast<Map<String, dynamic>>());
    return TopicListResult(topics, filter: 'hot');
  } catch (e) {
    final cached = await DbHelper.getCachedTopics('hot');
    if (cached.isNotEmpty) {
      final topics = cached.map((e) => Topic.fromJson(e)).toList();
      return TopicListResult(topics, fromCache: true, error: e, filter: 'hot');
    }
    return TopicListResult([], fromCache: false, error: e, filter: 'hot');
  }
});

final latestTopicsProvider = FutureProvider<TopicListResult>((ref) async {
  try {
    final api = V2exApiClient();
    final data = await api.getLatestTopics();
    final topics = data.map((e) => Topic.fromJson(e as Map<String, dynamic>)).toList();
    await DbHelper.cacheTopics('latest', data.cast<Map<String, dynamic>>());
    return TopicListResult(topics, filter: 'latest');
  } catch (e) {
    final cached = await DbHelper.getCachedTopics('latest');
    if (cached.isNotEmpty) {
      final topics = cached.map((e) => Topic.fromJson(e)).toList();
      return TopicListResult(topics, fromCache: true, error: e, filter: 'latest');
    }
    return TopicListResult([], fromCache: false, error: e, filter: 'latest');
  }
});

final followedTopicsProvider = FutureProvider<TopicListResult>((ref) async {
  try {
    final followed = await DbHelper.getFollowedNodes();
    if (followed.isEmpty) {
      return TopicListResult([], filter: 'followed');
    }
    final api = V2exApiClient();
    final allTopics = <Topic>[];
    for (final node in followed) {
      try {
        final nodeName = node['node_name'] as String;
        final data = await api.getNodeTopics(nodeName);
        final topics = data.map((e) => Topic.fromJson(e as Map<String, dynamic>)).toList();
        allTopics.addAll(topics);
      } catch (_) {
        // 单个节点失败不阻塞其他节点
      }
    }
    // 去重（按 topic id）并排序（按 lastTouched 倒序）
    final unique = <int, Topic>{};
    for (final t in allTopics) {
      unique[t.id] = t;
    }
    final sorted = unique.values.toList()
      ..sort((a, b) => b.lastTouched.compareTo(a.lastTouched));
    return TopicListResult(sorted.take(50).toList(), filter: 'followed');
  } catch (e) {
    return TopicListResult([], fromCache: false, error: e, filter: 'followed');
  }
});
