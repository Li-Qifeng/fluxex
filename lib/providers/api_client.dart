import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../services/services.dart';

/// 向后兼容的 API 客户端 Facade
/// 
/// 新代码建议直接使用对应 Service：
///   final topics = await TopicService().getHot();
///   final replies = await ReplyService().getByTopic(id);
/// 
/// 此类将逐渐废弃，所有能力已迁移到 lib/services/。
@Deprecated('直接使用 TopicService/ReplyService/NodeService 等')
class V2exApiClient {
  static final V2exApiClient _instance = V2exApiClient._internal();
  factory V2exApiClient() => _instance;

  final _topic = TopicService();
  final _reply = ReplyService();
  final _node = NodeService();
  final _member = MemberService();
  final _upload = UploadService();
  final _notification = NotificationService();

  V2exApiClient._internal();

  /// 获取底层 Dio 实例（调试用）
  dynamic get dio => ApiClient().dio;

  // ===== Topic =====
  Future<List<dynamic>> getHotTopics() => _topic.getHot();
  Future<List<dynamic>> getLatestTopics() => _topic.getLatest();
  Future<Map<String, dynamic>> getTopicDetail(int id) => _topic.getDetail(id);
  Future<List<dynamic>> getNodeTopics(String nodeName, {int page = 1}) =>
      _topic.getByNode(nodeName, page: page);
  Future<List<dynamic>> getUserTopics(String username) => _topic.getByUser(username);
  Future<void> createTopic(String nodeName, String title, String content) =>
      _topic.create(nodeName, title, content);

  // ===== Reply =====
  Future<List<dynamic>> getTopicReplies(int topicId) => _reply.getByTopic(topicId);
  Future<void> replyTopic(int topicId, String content) => _reply.reply(topicId, content);

  // ===== Node =====
  Future<Map<String, dynamic>> getNodeInfo(String name) => _node.getInfo(name);
  Future<Map<String, dynamic>> getNodeInfoByName(String name) => _node.getInfo(name);
  Future<List<dynamic>> getAllNodes() => _node.getAll();

  // ===== Member =====
  Future<Map<String, dynamic>> getMemberInfo(String username) => _member.getInfo(username);

  // ===== Upload =====
  Future<String> uploadImage({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
  }) => _upload.uploadImage(bytes: bytes, filename: filename, mimeType: mimeType);

  // ===== Notification =====
  Future<int> fetchUnreadNotificationCount() => _notification.fetchUnreadCount();

  // ===== Auth (once token) =====
  Future<String> _fetchOnce(String urlPath) => AuthService().fetchOnce(urlPath);
}
