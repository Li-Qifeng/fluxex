import 'package:html/parser.dart' show parse;
import 'api_client.dart';
import 'package:dio/dio.dart';

class NotificationService {
  final Dio _dio = ApiClient().dio;

  Future<int> fetchUnreadCount() async {
    try {
      final res = await _dio.get('https://www.v2ex.com/notifications');
      final html = res.data as String;
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
