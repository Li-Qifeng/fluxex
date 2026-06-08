import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/node_provider.dart';
import '../utils/db_helper.dart';
import '../utils/app_toast.dart';
import '../widgets/cached_avatar.dart';
import '../widgets/state_widgets.dart';
import '../widgets/topic_card.dart';

class NodeDetailScreen extends ConsumerStatefulWidget {
  final String nodeName;

  const NodeDetailScreen({super.key, required this.nodeName});

  @override
  ConsumerState<NodeDetailScreen> createState() => _NodeDetailScreenState();
}

class _NodeDetailScreenState extends ConsumerState<NodeDetailScreen> {
  bool _isFollowed = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final followed = await DbHelper.isNodeFollowed(widget.nodeName);
    if (mounted) setState(() => _isFollowed = followed);
  }

  Future<void> _toggleFollow() async {
    final nodeAsync = ref.read(nodeDetailProvider(widget.nodeName));
    String title = widget.nodeName;
    nodeAsync.whenData((node) => title = node.title);

    if (_isFollowed) {
      await DbHelper.unfollowNode(widget.nodeName);
      if (mounted) {
        setState(() => _isFollowed = false);
        AppToast.info(context, '已取消关注');
      }
    } else {
      await DbHelper.followNode(widget.nodeName, title);
      if (mounted) {
        setState(() => _isFollowed = true);
        AppToast.success(context, '关注成功');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodeAsync = ref.watch(nodeDetailProvider(widget.nodeName));
    final topicsAsync = ref.watch(paginatedNodeTopicsProvider(widget.nodeName));
    final notifier = ref.read(paginatedNodeTopicsProvider(widget.nodeName).notifier);

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (scroll) {
          if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 200) {
            if (notifier.hasMore && !notifier.isLoadingMore) {
              notifier.loadMore();
            }
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              actions: [
                IconButton(
                  icon: Icon(_isFollowed ? Icons.star : Icons.star_border),
                  tooltip: _isFollowed ? '取消关注' : '关注节点',
                  onPressed: _toggleFollow,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: nodeAsync.when(
                  data: (node) => Text(node.title),
                  loading: () => const Text('加载中...'),
                  error: (_, __) => const Text(''),
                ),
                background: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Center(
                    child: nodeAsync.when(
                      data: (node) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          if (node.avatarLarge.isNotEmpty)
                            CachedAvatar(
                              imageUrl: node.avatarLarge,
                              radius: 32,
                              fallbackText: node.title,
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
                    child: EmptyState(message: '暂无话题'),
                  );
                }
                return SliverList.builder(
                  itemCount: topics.length,
                  itemBuilder: (context, index) => TopicCard(topic: topics[index]),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: LoadingState(),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: ErrorState(
                  message: '话题加载失败: $err',
                  onRetry: () => ref.invalidate(paginatedNodeTopicsProvider(widget.nodeName)),
                ),
              ),
            ),
            // 底部加载更多
            SliverToBoxAdapter(
              child: topicsAsync.when(
                data: (topics) {
                  if (topics.isEmpty) return const SizedBox();
                  if (notifier.isLoadingMore) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  if (!notifier.hasMore) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          '—— 已显示全部话题 ——',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    );
                  }
                  return const SizedBox(height: 16);
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
