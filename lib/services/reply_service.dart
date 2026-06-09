import 'package:dio/dio.dart';
import 'api_client.dart';
import 'auth_service.dart';

class ReplyService {
  final Dio _dio = ApiClient().dio;
  final AuthService _auth = AuthService();

  Future<List<dynamic>> getByTopic(int topicId) async {
    final res = await _dio.get('/api/replies/show.json', queryParameters: {'topic_id': topicId});
    return res.data as List<dynamic>;
  }

  Future<void> reply(int topicId, String content) async {
    final once = await _auth.fetchOnce('/t/\$topicId');
    final res = await _dio.post(
      'https://www.v2ex.com/t/\$topicId/reply',
      data: FormData.fromMap({'content': content, 'once': once}),
      options: Options(
        headers: {'Referer': 'https://www.v2ex.com/t/\$topicId'},
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    if (res.statusCode != 200) throw Exception('回帖失败: \${res.statusCode}');
  }
}
