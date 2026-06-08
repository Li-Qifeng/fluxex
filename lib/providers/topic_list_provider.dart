import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/topic.dart';
import '../models/topic_list_result.dart';
import '../utils/db_helper.dart';
import 'api_client.dart';

enum TopicTab { hot, latest }

final topicTabProvider = StateProvider<TopicTab>((ref) => TopicTab.hot);

final hotTopicsProvider = FutureProvider<TopicListResult>((ref) async {
  try {
    final api = V2exApiClient();
    final data = await api.getHotTopics();
    final topics = data.map((e) => Topic.fromJson(e as Map<String, dynamic>)).toList();
    await DbHelper.cacheTopics('hot', data.cast<Map<String, dynamic>>());
    return TopicListResult(topics);
  } catch (e) {
    final cached = await DbHelper.getCachedTopics('hot');
    if (cached.isNotEmpty) {
      final topics = cached.map((e) => Topic.fromJson(e)).toList();
      return TopicListResult(topics, fromCache: true, error: e);
    }
    return TopicListResult([], fromCache: false, error: e);
  }
});

final latestTopicsProvider = FutureProvider<TopicListResult>((ref) async {
  try {
    final api = V2exApiClient();
    final data = await api.getLatestTopics();
    final topics = data.map((e) => Topic.fromJson(e as Map<String, dynamic>)).toList();
    await DbHelper.cacheTopics('latest', data.cast<Map<String, dynamic>>());
    return TopicListResult(topics);
  } catch (e) {
    final cached = await DbHelper.getCachedTopics('latest');
    if (cached.isNotEmpty) {
      final topics = cached.map((e) => Topic.fromJson(e)).toList();
      return TopicListResult(topics, fromCache: true, error: e);
    }
    return TopicListResult([], fromCache: false, error: e);
  }
});
