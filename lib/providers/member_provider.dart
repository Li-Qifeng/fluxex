import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/member.dart';
import '../models/topic.dart';
import 'api_client.dart';

final memberDetailProvider = FutureProvider.family<Member, String>((ref, username) async {
  final api = V2exApiClient();
  final data = await api.getMemberInfo(username);
  return Member.fromJson(data);
});

final memberTopicsProvider = FutureProvider.family<List<Topic>, String>((ref, username) async {
  final api = V2exApiClient();
  final data = await api.getUserTopics(username);
  return data.map((e) => Topic.fromJson(e as Map<String, dynamic>)).toList();
});
