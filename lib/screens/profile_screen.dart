import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/update_provider.dart';
import '../utils/app_toast.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _cookieController = TextEditingController();
  bool _showInput = false;

  @override
  void dispose() {
    _cookieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final updateInfo = ref.watch(updateInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('账号'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    auth.isLoggedIn ? Icons.check_circle : Icons.account_circle,
                    size: 64,
                    color: auth.isLoggedIn
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auth.isLoggedIn ? '已登录' : '未登录',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (auth.username != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      auth.username!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!auth.isLoggedIn) ...[
            FilledButton.icon(
              onPressed: () async {
                final result = await context.push('/login');
                if (result == true) setState(() {});
              },
              icon: const Icon(Icons.login),
              label: const Text('登录'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() => _showInput = !_showInput),
              icon: const Icon(Icons.cookie),
              label: const Text('手动输入 A2 Cookie'),
            ),
            if (_showInput) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _cookieController,
                decoration: InputDecoration(
                  hintText: '粘贴 A2 Cookie 值...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () {
                      final value = _cookieController.text.trim();
                      if (value.isNotEmpty) {
                        ref.read(authProvider.notifier).setA2Cookie(value);
                        AppToast.success(context, 'Cookie 已保存');
                        setState(() => _showInput = false);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '提示：登录 v2ex 后，在浏览器开发者工具中查找名为 A2 的 Cookie，复制其值粘贴到此处。',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ] else ...[
            FilledButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout),
              label: const Text('退出登录'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: const Text('书签'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/bookmarks'),
          ),
          ListTile(
            leading: const Icon(Icons.star_border),
            title: const Text('已关注节点'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/followed-nodes'),
          ),
          ListTile(
            leading: unreadCount > 0
                ? Badge(
                    label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
                    child: const Icon(Icons.notifications_none),
                  )
                : const Icon(Icons.notifications_none),
            title: const Text('通知中心'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/notifications'),
          ),
          const Divider(),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('设置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings'),
          ),
          _UpdateTile(updateInfo: updateInfo),
        ],
      ),
    );
  }
}

class _UpdateTile extends ConsumerWidget {
  final AsyncValue<UpdateInfo> updateInfo;

  const _UpdateTile({required this.updateInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return updateInfo.when(
      data: (info) => ListTile(
        leading: Icon(
          info.hasUpdate ? Icons.system_update_alt : Icons.info_outline,
          color: info.hasUpdate ? Theme.of(context).colorScheme.primary : null,
        ),
        title: Text(info.hasUpdate ? '发现新版本 ${info.latestVersion}' : '已是最新版本'),
        subtitle: Text('当前版本 ${info.currentVersion}'),
        trailing: info.hasUpdate
            ? FilledButton(
                onPressed: () => _openRelease(info.releaseUrl),
                child: const Text('更新'),
              )
            : IconButton(
                tooltip: '重新检查',
                onPressed: () => ref.invalidate(updateInfoProvider),
                icon: const Icon(Icons.refresh),
              ),
      ),
      loading: () => const ListTile(
        leading: Icon(Icons.info_outline),
        title: Text('检查更新中...'),
        subtitle: LinearProgressIndicator(),
      ),
      error: (_, __) => ListTile(
        leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
        title: const Text('更新检查失败'),
        subtitle: const Text('点击重试'),
        onTap: () => ref.invalidate(updateInfoProvider),
      ),
    );
  }

  Future<void> _openRelease(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
