import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/topic_list_result.dart';
import '../providers/auth_provider.dart';
import '../providers/topic_list_provider.dart';
import '../widgets/state_widgets.dart';
import '../widgets/topic_card.dart';
import '../widgets/topic_card_shimmer.dart';
import '../widgets/scroll_bottom_detector.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(topicTabProvider);
    final hotAsync = ref.watch(hotTopicsProvider);
    final latestAsync = ref.watch(latestTopicsProvider);
    final auth = ref.watch(authProvider);

    Widget buildList(AsyncValue<TopicListResult> asyncValue, VoidCallback onRefresh) {
      return asyncValue.when(
        data: (result) {
          if (result.topics.isEmpty && result.error != null) {
            return ErrorState(
              message: '加载失败: ${result.error}',
              onRetry: onRefresh,
            );
          }
          if (result.topics.isEmpty) {
            return EmptyState(onRetry: onRefresh);
          }
          return ListView.builder(
            itemCount: result.topics.length + (result.fromCache ? 1 : 0) + 1,
            itemBuilder: (context, index) {
              if (result.fromCache && index == 0) {
                return Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.offline_bolt,
                          color: Theme.of(context).colorScheme.onSecondaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '当前处于离线状态，展示缓存内容',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              final topicIndex = result.fromCache ? index - 1 : index;
              if (topicIndex == result.topics.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      '—— 已显示全部内容 ——',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                );
              }
              return TopicCard(topic: result.topics[topicIndex]);
            },
          );
        },
        loading: () => const TopicListShimmer(count: 6),
        error: (err, stack) => ErrorState(
          message: '加载失败: $err',
          onRetry: onRefresh,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('V2EX'),
        centerTitle: true,
        actions: [
          if (auth.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: '发布新话题',
              onPressed: () async {
                final result = await context.push('/create-topic');
                if (result == true) {
                  ref.invalidate(hotTopicsProvider);
                  ref.invalidate(latestTopicsProvider);
                }
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<TopicTab>(
              segments: const [
                ButtonSegment(
                  value: TopicTab.hot,
                  label: Text('最热'),
                  icon: Icon(Icons.local_fire_department),
                ),
                ButtonSegment(
                  value: TopicTab.latest,
                  label: Text('最新'),
                  icon: Icon(Icons.access_time),
                ),
              ],
              selected: {tab},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) {
                  ref.read(topicTabProvider.notifier).state = set.first;
                }
              },
              showSelectedIcon: false,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(hotTopicsProvider);
          ref.invalidate(latestTopicsProvider);
          await ref.read(
            tab == TopicTab.hot ? hotTopicsProvider.future : latestTopicsProvider.future,
          );
        },
        child: ScrollBottomDetector(
          onBottomReached: () {
            ref.invalidate(hotTopicsProvider);
            ref.invalidate(latestTopicsProvider);
          },
          child: tab == TopicTab.hot
              ? buildList(hotAsync, () => ref.invalidate(hotTopicsProvider))
              : buildList(latestAsync, () => ref.invalidate(latestTopicsProvider)),
        ),
      ),
    );
  }
}
