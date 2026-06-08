import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/topic_list_result.dart';
import '../providers/topic_list_provider.dart';
import '../widgets/topic_card.dart';
import '../widgets/scroll_bottom_detector.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(topicTabProvider);
    final hotAsync = ref.watch(hotTopicsProvider);
    final latestAsync = ref.watch(latestTopicsProvider);

    Widget buildList(AsyncValue<TopicListResult> asyncValue, VoidCallback onRefresh) {
      return asyncValue.when(
        data: (result) {
          if (result.topics.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  const Text('暂无内容'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onRefresh,
                    child: const Text('刷新'),
                  ),
                ],
              ),
            );
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text('加载失败: $err'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onRefresh,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('V2EX'),
        centerTitle: true,
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
