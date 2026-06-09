import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;
import 'api_client.dart';

/// 认证/表单辅助服务
class AuthService {
  final Dio _dio = ApiClient().dio;

  /// 从指定页面提取 V2EX 的 once token（CSRF 防护）
  Future<String> fetchOnce(String urlPath) async {
    final response = await _dio.get('https://www.v2ex.com$urlPath');
    final html = response.data as String;
    final regex = RegExp(r'var once = "(\d+)"');
    final match = regex.firstMatch(html);
    if (match != null) return match.group(1)!;
    final doc = parse(html);
    final input = doc.querySelector('input[name="once"]');
    if (input != null) {
      final val = input.attributes['value'];
      if (val != null && val.isNotEmpty) return val;
    }
    throw Exception('无法获取 once token');
  }
}
