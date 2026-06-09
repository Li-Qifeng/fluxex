import 'package:dio/dio.dart';
import 'api_client.dart';
import 'auth_service.dart';

class TopicService {
  final Dio _dio = ApiClient().dio;
  final AuthService _auth = AuthService();

  Future<List<dynamic>> getHot() async {
    final res = await _dio.get('/api/topics/hot.json');
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> getLatest() async {
    final res = await _dio.get('/api/topics/latest.json');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getDetail(int id) async {
    final res = await _dio.get('/api/topics/show.json', queryParameters: {'id': id});
    final list = res.data as List;
    if (list.isEmpty) throw Exception('Topic not found');
    return list.first as Map<String, dynamic>;
  }

  Future<List<dynamic>> getByNode(String nodeName, {int page = 1}) async {
    final res = await _dio.get('/api/topics/show.json', queryParameters: {
      'node_name': nodeName,
      'page': page,
    });
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> getByUser(String username) async {
    final res = await _dio.get('/api/topics/show.json', queryParameters: {'username': username});
    return res.data as List<dynamic>;
  }

  Future<void> create(String nodeName, String title, String content) async {
    final once = await _auth.fetchOnce('/new/\$nodeName');
    final res = await _dio.post(
      'https://www.v2ex.com/new/\$nodeName',
      data: FormData.fromMap({'title': title, 'content': content, 'once': once}),
      options: Options(
        headers: {'Referer': 'https://www.v2ex.com/new/\$nodeName'},
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    if (res.statusCode != 200) throw Exception('发帖失败: \${res.statusCode}');
  }
}
