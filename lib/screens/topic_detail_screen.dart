import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/topic_detail_provider.dart';
import '../utils/db_helper.dart';
import '../widgets/topic_header.dart';
import '../widgets/reply_item.dart';

class TopicDetailScreen extends ConsumerWidget {
  final int topicId;

  const TopicDetailScreen({super.key, required this.topicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicAsync = ref.watch(topicDetailProvider(topicId));
    final repliesAsync = ref.watch(topicRepliesProvider(topicId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('话题详情'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            tooltip: '收藏',
            onPressed: () async {
              final topic = await ref.read(topicDetailProvider(topicId).future);
              final isBookmarked = await DbHelper.isBookmarked(topicId);
              if (isBookmarked) {
                await DbHelper.removeBookmark(topicId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已取消收藏')),
                  );
                }
              } else {
                await DbHelper.addBookmark(topicId, topic.title);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已收藏')),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: '在网页中打开',
            onPressed: () async {
              final url = Uri.parse('https://www.v2ex.com/t/$topicId');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: topicAsync.when(
        data: (topic) {
          // 记录浏览历史
          DbHelper.addBrowseHistory(topicId, topic.title);
          return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(topicDetailProvider(topicId));
            ref.invalidate(topicRepliesProvider(topicId));
            await ref.read(topicDetailProvider(topicId).future);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: TopicHeader(topic: topic),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(),
                ),
              ),
              repliesAsync.when(
                data: (replies) {
                  if (replies.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            '暂无回复',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverList.builder(
                    itemCount: replies.length,
                    itemBuilder: (context, index) => ReplyItem(
                      reply: replies[index],
                      floor: index + 1,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text('回复加载失败: $err')),
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text('话题加载失败: $err'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(topicDetailProvider(topicId)),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push('/reply/$topicId');
          if (result == true) {
            ref.invalidate(topicRepliesProvider(topicId));
          }
        },
        icon: const Icon(Icons.reply),
        label: const Text('回复'),
      ),
    );
  }
}
