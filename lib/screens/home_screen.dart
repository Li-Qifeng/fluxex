import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/topic_list_provider.dart';
import '../widgets/topic_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(topicTabProvider);
    final hotAsync = ref.watch(hotTopicsProvider);
    final latestAsync = ref.watch(latestTopicsProvider);

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
        child: tab == TopicTab.hot
            ? hotAsync.when(
                data: (topics) => ListView.builder(
                  itemCount: topics.length,
                  itemBuilder: (context, index) => TopicCard(topic: topics[index]),
                ),
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
                        onPressed: () => ref.invalidate(hotTopicsProvider),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              )
            : latestAsync.when(
                data: (topics) => ListView.builder(
                  itemCount: topics.length,
                  itemBuilder: (context, index) => TopicCard(topic: topics[index]),
                ),
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
                        onPressed: () => ref.invalidate(latestTopicsProvider),
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
