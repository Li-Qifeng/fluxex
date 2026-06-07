import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/topic.dart';
import 'api_client.dart';

enum TopicTab { hot, latest }

final topicTabProvider = StateProvider<TopicTab>((ref) => TopicTab.hot);

final hotTopicsProvider = FutureProvider<List<Topic>>((ref) async {
  final api = V2exApiClient();
  final data = await api.getHotTopics();
  return data.map((e) => Topic.fromJson(e as Map<String, dynamic>)).toList();
});

final latestTopicsProvider = FutureProvider<List<Topic>>((ref) async {
  final api = V2exApiClient();
  final data = await api.getLatestTopics();
  return data.map((e) => Topic.fromJson(e as Map<String, dynamic>)).toList();
});
