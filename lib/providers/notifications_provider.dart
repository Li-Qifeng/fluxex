import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' show parse;
import 'api_client.dart';

class NotificationItem {
  final String text;
  final String? href;
  final String? avatarUrl;
  final bool unread;

  NotificationItem({
    required this.text,
    this.href,
    this.avatarUrl,
    required this.unread,
  });
}

final notificationsProvider = FutureProvider<List<NotificationItem>>((ref) async {
  final api = V2exApiClient();
  final response = await api.dio.get('https://www.v2ex.com/notifications');
  final html = response.data as String;
  final document = parse(html);

  final items = <NotificationItem>[];
  // v2ex 通知页每个通知通常是 .cell 容器
  final cells = document.querySelectorAll('#notifications .cell');
  for (final cell in cells) {
    final link = cell.querySelector('a[href*="/t/"]');
    final avatar = cell.querySelector('img.avatar');
    final textNodes = cell.text.split('\n').where((s) => s.trim().isNotEmpty).toList();
    final text = textNodes.isNotEmpty ? textNodes.first.trim() : '';
    if (text.isEmpty) continue;
    items.add(NotificationItem(
      text: text,
      href: link?.attributes['href'],
      avatarUrl: avatar?.attributes['src'],
      unread: cell.classes.contains('unread'),
    ));
  }
  return items;
});
