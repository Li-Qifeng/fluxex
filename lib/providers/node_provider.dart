import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/node.dart';
import '../models/topic.dart';
import 'api_client.dart';

final allNodesProvider = FutureProvider<List<Node>>((ref) async {
  final api = V2exApiClient();
  final data = await api.getAllNodes();
  return data.map((e) => Node.fromJson(e as Map<String, dynamic>)).toList();
});

final nodeDetailProvider = FutureProvider.family<Node, String>((ref, name) async {
  final api = V2exApiClient();
  final data = await api.getNodeInfoByName(name);
  return Node.fromJson(data);
});

final nodeTopicsProvider = FutureProvider.family<List<Topic>, String>((ref, name) async {
  final api = V2exApiClient();
  final data = await api.getNodeTopics(name);
  return data.map((e) => Topic.fromJson(e as Map<String, dynamic>)).toList();
});
