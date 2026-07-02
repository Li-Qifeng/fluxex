import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/current_member_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/update_provider.dart';
import '../utils/app_toast.dart';
import '../utils/db_helper.dart';
import '../widgets/cached_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _cookieController = TextEditingController();
  bool _showInput = false;
  int _bookmarkCount = 0;
  int _followedNodeCount = 0;
  int _historyCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final bookmarks = await DbHelper.getBookmarks();
    final followed = await DbHelper.getFollowedNodes();
    final db = await DbHelper.database;
    final history = await db.query('browse_history');
    if (mounted) {
      setState(() {
        _bookmarkCount = bookmarks.length;
        _followedNodeCount = followed.length;
        _historyCount = history.length;
      });
    }
  }

  Future<void> _showBrowseHistory(BuildContext ctx) async {
    final history = await DbHelper.getBrowseHistory(limit: 30);
    if (!ctx.mounted) return;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Theme.of(ctx).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetCtx).size.height * 0.55,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(sheetCtx).colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '浏览历史',
                      style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final db = await DbHelper.database;
                        await db.delete('browse_history');
                        if (ctx.mounted) {
                          Navigator.pop(sheetCtx);
                          setState(() => _historyCount = 0);
                        }
                      },
                      child: const Text('清空'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: history.isEmpty
                    ? const Center(child: Text('暂无浏览记录'))
                    : ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (_, index) {
                          final entry = history[index];
                          final title = (entry['title'] as String?) ?? '无标题';
                          final floor = (entry['last_floor'] as int?) ?? 0;
                          final viewedAt = DateTime.fromMillisecondsSinceEpoch(
                            entry['viewed_at'] as int,
                          );
                          final timeStr = '${viewedAt.month}/${viewedAt.day} ${viewedAt.hour.toString().padLeft(2, '0')}:${viewedAt.minute.toString().padLeft(2, '0')}';
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.history, size: 20),
                            title: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              floor > 0 ? '第 $floor 楼 · $timeStr' : timeStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(sheetCtx).colorScheme.outline,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              context.push('/topic/${entry['topic_id']}');
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          _ProfileHeaderCard(auth: auth),
          const SizedBox(height: 16),
          if (!auth.isLoggedIn) ...[
            FilledButton.icon(
              onPressed: () async {
                final result = await context.push('/login');
                if (result == true) {
                  ref.invalidate(currentMemberProvider);
                  setState(() {});
                }
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
          // 统计概览
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  count: _historyCount,
                  label: '浏览',
                  onTap: () => _showBrowseHistory(context),
                ),
              ),
              Expanded(
                child: _StatItem(
                  count: _bookmarkCount,
                  label: '书签',
                  onTap: () => context.push('/bookmarks'),
                ),
              ),
              Expanded(
                child: _StatItem(
                  count: _followedNodeCount,
                  label: '关注',
                  onTap: () => context.push('/followed-nodes'),
                ),
              ),
              Expanded(
                child: _StatItem(
                  count: unreadCount,
                  label: '通知',
                  onTap: () => context.push('/notifications'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: const Text('书签'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_bookmarkCount > 0)
                  Text('$_bookmarkCount', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => context.push('/bookmarks'),
          ),
          ListTile(
            leading: const Icon(Icons.star_border),
            title: const Text('已关注节点'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_followedNodeCount > 0)
                  Text('$_followedNodeCount', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => context.push('/followed-nodes'),
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: const Text('稍后阅读'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/read-later'),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('已关注成员'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/followed-members'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('草稿箱'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/drafts'),
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

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback? onTap;

  const _StatItem({required this.count, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: cs.outline,
              ),
            ),
          ],
        ),
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

class _ProfileHeaderCard extends ConsumerWidget {
  final AuthState auth;

  const _ProfileHeaderCard({required this.auth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final memberAsync = ref.watch(currentMemberProvider);

    if (!auth.isLoggedIn) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.account_circle,
                size: 64,
                color: cs.primary,
              ),
              const SizedBox(height: 12),
              Text(
                '未登录',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: auth.username != null
            ? () => context.push('/member/${auth.username}')
            : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: memberAsync.when(
            data: (member) {
              final hasPro = member?.pro != null;
              return Column(
                children: [
                  CachedAvatar(
                    imageUrl: member?.avatarLarge,
                    radius: 44,
                    fallbackText: auth.username,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          auth.username ?? '用户',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasPro) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Pro',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (member?.tagline != null && member!.tagline!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      member.tagline!,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (member?.bio != null && member!.bio!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      member.bio!,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.outline,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (member?.location != null && member!.location!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: cs.outline),
                        const SizedBox(width: 4),
                        Text(
                          member.location!,
                          style: TextStyle(fontSize: 12, color: cs.outline),
                        ),
                      ],
                    ),
                  ],
                  if (member != null) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => context.push('/member/${auth.username}'),
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text('查看主页'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                    ),
                  ],
                ],
              );
            },
            loading: () => const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (err, __) => Column(
              children: [
                CachedAvatar(
                  imageUrl: null,
                  radius: 44,
                  fallbackText: auth.username,
                ),
                const SizedBox(height: 14),
                Text(
                  auth.username ?? '用户',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '已登录',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  '信息加载失败: $err',
                  style: TextStyle(fontSize: 11, color: cs.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => ref.invalidate(currentMemberProvider),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
