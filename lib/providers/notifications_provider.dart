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

class PaginatedNotificationsNotifier extends AsyncNotifier<List<NotificationItem>> {
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<NotificationItem>> build() async {
    _page = 1;
    _hasMore = true;
    return _fetchPage(1);
  }

  Future<List<NotificationItem>> _fetchPage(int page) async {
    final api = V2exApiClient();
    final response = await api.dio.get('https://www.v2ex.com/notifications?p=$page');
    final html = response.data as String;
    final document = parse(html);

    final cells = document.querySelectorAll('#notifications .cell, .notification_item');
    final items = cells
        .map(_parseNotificationCell)
        .whereType<NotificationItem>()
        .toList();

    if (items.isEmpty || items.length < 20) {
      _hasMore = false;
    }

    return items;
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    // Trigger rebuild to show bottom loading indicator
    state = AsyncValue.data(state.valueOrNull ?? []);

    try {
      _page++;
      final newItems = await _fetchPage(_page);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([...current, ...newItems]);
    } catch (e, stack) {
      _page--; // rollback
      state = AsyncValue.error(e, stack);
    } finally {
      _isLoadingMore = false;
    }
  }
}

final paginatedNotificationsProvider =
    AsyncNotifierProvider<PaginatedNotificationsNotifier, List<NotificationItem>>(
  PaginatedNotificationsNotifier.new,
);

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
