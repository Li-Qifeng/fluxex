import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/notification_provider.dart';
import '../providers/notifications_provider.dart';
import '../widgets/cached_avatar.dart';
import '../widgets/notification_list_shimmer.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      ref.read(unreadCountProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      final notifier = ref.read(paginatedNotificationsProvider.notifier);
      notifier.loadMore();
    }
  }

  Future<void> _openAndRefresh(String href) async {
    final uri = Uri.parse(
      href.startsWith('http') ? href : 'https://www.v2ex.com$href',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    // 延迟 3s 刷新未读数，给用户回 App 的时间
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      ref.read(unreadCountProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(paginatedNotificationsProvider);
    final notifier = ref.watch(paginatedNotificationsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: () {
              ref.invalidate(paginatedNotificationsProvider);
              ref.read(unreadCountProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: async.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无通知'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse('https://www.v2ex.com/notifications');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('在网页中查看'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            controller: _scrollController,
            itemCount: items.length + (notifier.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= items.length) {
                // Bottom loading indicator
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final item = items[index];
              return ListTile(
                leading: item.avatarUrl != null
                    ? CachedAvatar(
                        imageUrl: item.avatarUrl,
                        radius: 20,
                        fallbackText: item.text.isNotEmpty ? item.text[0] : '?',
                      )
                    : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(
                  item.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: item.unread
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                onTap: () {
                  final href = item.href;
                  if (href != null) {
                    _openAndRefresh(href);
                  }
                },
              );
            },
          );
        },
        loading: () => const NotificationListShimmer(count: 6),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text('通知加载失败: $err'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  final uri = Uri.parse('https://www.v2ex.com/notifications');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_browser),
                label: const Text('在网页中查看'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(paginatedNotificationsProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
