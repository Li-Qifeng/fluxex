import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/node_provider.dart';
import '../widgets/topic_card.dart';

class NodeDetailScreen extends ConsumerWidget {
  final String nodeName;

  const NodeDetailScreen({super.key, required this.nodeName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodeAsync = ref.watch(nodeDetailProvider(nodeName));
    final topicsAsync = ref.watch(nodeTopicsProvider(nodeName));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: nodeAsync.when(
                data: (node) => Text(node.title),
                loading: () => const Text('加载中...'),
                error: (_, __) => const Text(''),),
              background: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Center(
                  child: nodeAsync.when(
                    data: (node) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        if (node.avatarLarge.isNotEmpty)
                          CircleAvatar(
                            radius: 32,
                            backgroundImage: NetworkImage(node.avatarLarge),
                            backgroundColor: Colors.transparent,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          node.titleAlternative,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                          ),
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
          nodeAsync.when(
            data: (node) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (node.header != null && node.header!.isNotEmpty)
                        Text(
                          node.header!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.topic, size: 16, color: Theme.of(context).colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(
                            '${node.topics ?? 0} 话题',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.star, size: 16, color: Theme.of(context).colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(
                            '${node.stars ?? 0} 收藏',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        '最新话题',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
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
}
