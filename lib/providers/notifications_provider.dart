import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart';
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

  final cells = document.querySelectorAll('#notifications .cell, .notification_item');
  return cells.map(_parseNotificationCell).whereType<NotificationItem>().toList();
});

NotificationItem? _parseNotificationCell(Element cell) {
  final link = cell.querySelector('a[href*="/t/"], a[href*="/member/"]');
  final avatar = cell.querySelector('img.avatar, img[src*="avatar"]');
  final text = cell.text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .join(' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  if (text.isEmpty) return null;

  return NotificationItem(
    text: text,
    href: _normalizePath(link?.attributes['href']),
    avatarUrl: _normalizeUrl(avatar?.attributes['src']),
    unread: cell.classes.contains('unread') || cell.classes.contains('notification_unread'),
  );
}

String? _normalizePath(String? href) {
  if (href == null || href.isEmpty) return null;
  final uri = Uri.tryParse(href);
  if (uri == null) return null;
  if (uri.hasScheme) return uri.toString();
  return href.startsWith('/') ? href : '/$href';
}

String? _normalizeUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('//')) return 'https:$url';
  if (url.startsWith('/')) return 'https://www.v2ex.com$url';
  return url;
}
