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
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(unreadCountProvider.notifier).refresh();
    });
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
    final async = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: () {
              ref.invalidate(notificationsProvider);
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
            itemCount: items.length,
            itemBuilder: (context, index) {
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
                onPressed: () => ref.invalidate(notificationsProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
