import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'api_client.dart';

class UploadService {
  final Dio _dio = ApiClient().dio;

  Future<String> uploadImage({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
  }) async {
    final res = await _dio.post(
      'https://www.v2ex.com/i/upload',
      queryParameters: {'qqfile': filename},
      data: bytes,
      options: Options(
        contentType: mimeType ?? 'application/octet-stream',
        headers: {
          'Referer': 'https://www.v2ex.com/new',
          'X-Requested-With': 'XMLHttpRequest',
        },
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    if (res.statusCode == 403) throw Exception('图片上传需要登录 V2EX');
    if (res.statusCode == null || res.statusCode! >= 300) {
      throw Exception('图片上传失败: \${res.statusCode}');
    }

    final data = res.data;
    if (data is Map) {
      for (final key in ['url', 'image', 'src', 'link', 'path']) {
        final value = data[key];
        if (value is String && value.isNotEmpty) {
          return value.startsWith('http') ? value : 'https://www.v2ex.com\$value';
        }
      }
    }
    if (data is String) {
      final url = RegExp(r'https?://[^\s"]+').firstMatch(data)?.group(0);
      if (url != null) return url;
      final v2exPath = RegExp(r'/(?:i|static)/[^\s"]+').firstMatch(data)?.group(0);
      if (v2exPath != null) return 'https://www.v2ex.com\$v2exPath';
    }
    throw Exception('图片上传响应无法解析');
  }
}
