import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/member_provider.dart';
import '../widgets/topic_card.dart';

class MemberDetailScreen extends ConsumerWidget {
  final String username;

  const MemberDetailScreen({super.key, required this.username});

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(memberDetailProvider(username));
    final topicsAsync = ref.watch(memberTopicsProvider(username));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Center(
                  child: memberAsync.when(
                    data: (member) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(member.avatarLarge),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          member.username,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                        if (member.tagline != null && member.tagline!.isNotEmpty)
                          Text(
                            member.tagline!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Icon(Icons.error, size: 48),
                  ),
                ),
              ),
            ),
          ),
          memberAsync.when(
            data: (member) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (member.bio != null && member.bio!.isNotEmpty) ...[
                      Text(
                        member.bio!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip(context, Icons.calendar_today, '加入于 ${_formatTime(member.created)}'),
                        if (member.location != null && member.location!.isNotEmpty)
                          _buildInfoChip(context, Icons.location_on, member.location!),
                        if (member.website != null && member.website!.isNotEmpty)
                          _buildInfoChip(context, Icons.language, member.website!),
                      ],
                    ),
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
            loading: () => const SliverToBoxAdapter(child: SizedBox()),
            error: (_, __) => const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('用户加载失败'))),
            ),
          ),
          topicsAsync.when(
            data: (topics) {
              if (topics.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('暂无话题')),
                  ),
                );
              }
              return SliverList.builder(
                itemCount: topics.length,
                itemBuilder: (context, index) => TopicCard(topic: topics[index]),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text('话题加载失败: $err')),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
