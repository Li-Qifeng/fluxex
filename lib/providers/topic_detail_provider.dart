import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/topic.dart';
import '../models/reply.dart';
import 'api_client.dart';

final topicDetailProvider = FutureProvider.family<Topic, int>((ref, id) async {
  final api = V2exApiClient();
  final data = await api.getTopicDetail(id);
  return Topic.fromJson(data);
});

final topicRepliesProvider = FutureProvider.family<List<Reply>, int>((ref, id) async {
  final api = V2exApiClient();
  final data = await api.getTopicReplies(id);
  return data.map((e) => Reply.fromJson(e as Map<String, dynamic>)).toList();
});
