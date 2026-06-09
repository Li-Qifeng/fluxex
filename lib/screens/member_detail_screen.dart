import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/member_provider.dart';
import '../widgets/cached_avatar.dart';
import '../widgets/member_detail_skeleton.dart';
import '../widgets/state_widgets.dart';
import '../widgets/topic_card.dart';
import '../widgets/topic_card_shimmer.dart';

class MemberDetailScreen extends ConsumerWidget {
  final String username;

  const MemberDetailScreen({super.key, required this.username});

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(memberDetailProvider(username));
    final topicsAsync = ref.watch(memberTopicsProvider(username));

    return Scaffold(
      body: memberAsync.when(
        data: (member) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Hero(
                            tag: 'member-avatar-${member.username}',
                            child: CachedAvatar(
                              imageUrl: member.avatarLarge,
                              radius: 44,
                              fallbackText: member.username,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            member.username,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                          if (member.tagline != null && member.tagline!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                member.tagline!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 统计卡片
                      topicsAsync.when(
                        data: (topics) => _buildStatsCard(context, topics.length, member),
                        loading: () => _buildStatsCard(context, 0, member),
                        error: (_, __) => _buildStatsCard(context, 0, member),
                      ),
                      const SizedBox(height: 16),
                      // Bio
                      if (member.bio != null && member.bio!.isNotEmpty) ...[
                        Text(
                          '关于',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          member.bio!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // 社交链接
                      _buildSocialLinks(context, member),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        '最近话题',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              topicsAsync.when(
                data: (topics) {
                  if (topics.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: EmptyState(message: '暂无话题'),
                    );
                  }
                  return SliverList.builder(
                    itemCount: topics.length,
                    itemBuilder: (context, index) => TopicCard(topic: topics[index]),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: TopicListShimmer(count: 4),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: ErrorState(
                    message: '话题加载失败: $err',
                    onRetry: () => ref.invalidate(memberTopicsProvider(username)),
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          );
        },
        loading: () => const MemberDetailSkeleton(),
        error: (err, _) => Scaffold(
          appBar: AppBar(title: const Text('用户详情')),
          body: ErrorState(
            message: '用户加载失败: $err',
            onRetry: () => ref.invalidate(memberDetailProvider(username)),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, int topicCount, dynamic member) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _statItem(context, '$topicCount', '话题'),
            ),
            Container(width: 1, height: 30, color: cs.outlineVariant.withOpacity(0.3)),
            Expanded(
              child: _statItem(context, _formatTime(member.created), '加入于'),
            ),
            if (member.location != null && member.location!.isNotEmpty) ...[
              Container(width: 1, height: 30, color: cs.outlineVariant.withOpacity(0.3)),
              Expanded(
                child: _statItem(context, member.location!, '位置'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLinks(BuildContext context, dynamic member) {
    final items = <Widget>[];
    if (member.website != null && member.website!.isNotEmpty) {
      items.add(_socialChip(context, Icons.language, '网站', () => _openUrl(member.website)));
    }
    if (member.github != null && member.github!.isNotEmpty) {
      items.add(_socialChip(context, Icons.code, 'GitHub', () => _openUrl('https://github.com/${member.github}')));
    }
    if (member.twitter != null && member.twitter!.isNotEmpty) {
      items.add(_socialChip(context, Icons.alternate_email, 'Twitter', () => _openUrl('https://twitter.com/${member.twitter}')));
    }
    if (member.psn != null && member.psn!.isNotEmpty) {
      items.add(_socialChip(context, Icons.videogame_asset, 'PSN', null));
    }
    if (member.btc != null && member.btc!.isNotEmpty) {
      items.add(_socialChip(context, Icons.currency_bitcoin, 'BTC', null));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '链接',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: items,
        ),
      ],
    );
  }

  Widget _socialChip(BuildContext context, IconData icon, String label, VoidCallback? onTap) {
    final cs = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(icon, size: 16, color: cs.primary),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: cs.primaryContainer.withOpacity(0.3),
      side: BorderSide.none,
    );
  }
}
