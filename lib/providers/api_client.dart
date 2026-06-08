import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;

class V2exApiClient {
  static final V2exApiClient _instance = V2exApiClient._internal();
  factory V2exApiClient() => _instance;

  late final Dio _dio;
  final CookieJar _cookieJar = CookieJar();

  V2exApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://www.v2ex.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent': 'V2exClient/0.1.0 (Flutter; Linux; Like Fluxdo)',
        'Accept': 'application/json',
      },
    ));
    _dio.interceptors.add(CookieManager(_cookieJar));
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(responseBody: true));
    }
  }

  Dio get dio => _dio;

  Future<List<dynamic>> getHotTopics() async {
    final response = await _dio.get('/api/topics/hot.json');
    if (response.data is List) {
      return response.data as List<dynamic>;
    }
    throw Exception('Invalid response format');
  }

  Future<List<dynamic>> getLatestTopics() async {
    final response = await _dio.get('/api/topics/latest.json');
    if (response.data is List) {
      return response.data as List<dynamic>;
    }
    throw Exception('Invalid response format');
  }

  Future<Map<String, dynamic>> getTopicDetail(int id) async {
    final response = await _dio.get('/api/topics/show.json', queryParameters: {'id': id});
    if (response.data is List && (response.data as List).isNotEmpty) {
      return (response.data as List).first as Map<String, dynamic>;
    }
    throw Exception('Topic not found');
  }

  Future<List<dynamic>> getTopicReplies(int topicId) async {
    final response = await _dio.get('/api/replies/show.json', queryParameters: {'topic_id': topicId});
    if (response.data is List) {
      return response.data as List<dynamic>;
    }
    throw Exception('Invalid response format');
  }

  Future<Map<String, dynamic>> getNodeInfo(String name) async {
    final response = await _dio.get('/api/nodes/show.json', queryParameters: {'name': name});
    if (response.data is Map) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception('Invalid response format');
  }

  Future<Map<String, dynamic>> getMemberInfo(String username) async {
    final response = await _dio.get('/api/members/show.json', queryParameters: {'username': username});
    if (response.data is Map) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception('Invalid response format');
  }

  Future<Map<String, dynamic>> getNodeInfoByName(String name) async {
    final response = await _dio.get('/api/nodes/show.json', queryParameters: {'name': name});
    if (response.data is Map) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception('Invalid response format');
  }

  Future<List<dynamic>> getNodeTopics(String nodeName) async {
    final response = await _dio.get('/api/topics/show.json', queryParameters: {'node_name': nodeName});
    if (response.data is List) {
      return response.data as List<dynamic>;
    }
    throw Exception('Invalid response format');
  }

  Future<List<dynamic>> getAllNodes() async {
    final response = await _dio.get('/api/nodes/all.json');
    if (response.data is List) {
      return response.data as List<dynamic>;
    }
    throw Exception('Invalid response format');
  }

  Future<List<dynamic>> getUserTopics(String username) async {
    final response = await _dio.get('/api/topics/show.json', queryParameters: {'username': username});
    if (response.data is List) {
      return response.data as List<dynamic>;
    }
    throw Exception('Invalid response format');
  }

  // ---------- 网页表单操作（需要 once token） ----------

  Future<String> _fetchOnce(String urlPath) async {
    final response = await _dio.get('https://www.v2ex.com$urlPath');
    final html = response.data as String;
    // 尝试提取 var once = "12345";
    final regex = RegExp(r'var once = "(\d+)"');
    final match = regex.firstMatch(html);
    if (match != null) return match.group(1)!;
    // fallback: 从表单解析
    final doc = parse(html);
    final input = doc.querySelector('input[name="once"]');
    if (input != null) {
      final val = input.attributes['value'];
      if (val != null && val.isNotEmpty) return val;
    }
    throw Exception('无法获取 once token');
  }

  Future<void> replyTopic(int topicId, String content) async {
    final once = await _fetchOnce('/t/$topicId');
    final response = await _dio.post(
      'https://www.v2ex.com/t/$topicId/reply',
      data: FormData.fromMap({
        'content': content,
        'once': once,
      }),
      options: Options(
        headers: {
          'Referer': 'https://www.v2ex.com/t/$topicId',
        },
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('回帖失败: ${response.statusCode}');
    }
  }

  Future<void> createTopic(String nodeName, String title, String content) async {
    final once = await _fetchOnce('/new/$nodeName');
    final response = await _dio.post(
      'https://www.v2ex.com/new/$nodeName',
      data: FormData.fromMap({
        'title': title,
        'content': content,
        'once': once,
      }),
      options: Options(
        headers: {
          'Referer': 'https://www.v2ex.com/new/$nodeName',
        },
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('发帖失败: ${response.statusCode}');
    }
  }

  Future<int> fetchUnreadNotificationCount() async {
    try {
      final response = await _dio.get('https://www.v2ex.com/notifications');
      final html = response.data as String;
      final doc = parse(html);
      final items = doc.querySelectorAll('.notification_item');
      int unread = 0;
      for (final item in items) {
        if (item.classes.contains('unread')) unread++;
      }
      return unread;
    } catch (_) {
      return 0;
    }
  }
}
