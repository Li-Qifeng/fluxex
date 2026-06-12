import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../models/topic_list_result.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/topic_list_provider.dart';
import '../widgets/gradient_app_bar_blur.dart';
import '../widgets/state_widgets.dart';
import '../widgets/topic_card.dart';
import '../widgets/topic_card_shimmer.dart';
import '../widgets/scroll_bottom_detector.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  bool _clipboardChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkClipboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _clipboardChecked = false;
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    if (_clipboardChecked) return;
    _clipboardChecked = true;

    try {
      final data = await Clipboard.getData('text/plain');
      final text = data?.text;
      if (text == null || text.isEmpty) return;

      final match = RegExp(r'v2ex\.com/t/(\d+)').firstMatch(text);
      if (match != null && mounted) {
        final topicId = match.group(1)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('检测到剪贴板中的 V2EX 链接'),
            action: SnackBarAction(
              label: '打开话题',
              onPressed: () {
                context.push('/topic/$topicId');
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (_) {
      // Clipboard access may fail silently on some platforms
    }
  }

  Future<bool> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出应用'),
        content: const Text('确定要退出 FluxEx 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(topicTabProvider);
    final hotAsync = ref.watch(hotTopicsProvider);
    final latestAsync = ref.watch(latestTopicsProvider);
    final auth = ref.watch(authProvider);

  Widget wrapForPullToRefresh(BuildContext ctx, Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: constraints.maxHeight > 0
                ? constraints.maxHeight
                : MediaQuery.of(context).size.height * 0.6,
            child: Center(child: child),
          ),
        ],
      ),
    );
  }

    Widget buildList(AsyncValue<TopicListResult> asyncValue, VoidCallback onRefresh) {
      return asyncValue.when(
        data: (result) {
          if (result.topics.isEmpty && result.error != null) {
            return wrapForPullToRefresh(
              context,
              ErrorState(
                message: '加载失败: ${result.error}',
                onRetry: onRefresh,
              ),
            );
          }
          if (result.topics.isEmpty) {
            return wrapForPullToRefresh(
              context,
              EmptyState(onRetry: onRefresh),
            );
          }
          final blockedKeywords = ref.watch(settingsProvider).blockedKeywords;
          final filteredTopics = blockedKeywords.isEmpty
              ? result.topics
              : result.topics.where((topic) {
                  final lowerTitle = topic.title.toLowerCase();
                  return !blockedKeywords.any(
                    (kw) => lowerTitle.contains(kw.toLowerCase()),
                  );
                }).toList();
          if (filteredTopics.isEmpty) {
            return wrapForPullToRefresh(
              context,
              EmptyState(onRetry: onRefresh),
            );
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + kToolbarHeight + 48,
            ),
            itemCount: filteredTopics.length + (result.fromCache ? 1 : 0) + 1,
            itemBuilder: (context, index) {
              if (result.fromCache && index == 0) {
                return Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.6),
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
              if (topicIndex == filteredTopics.length) {
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
              return TopicCard(topic: filteredTopics[topicIndex]);
            },
          );
        },
        loading: () => const TopicListShimmer(count: 6),
        error: (err, stack) => wrapForPullToRefresh(
          context,
          ErrorState(
            message: '加载失败: $err',
            onRetry: onRefresh,
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog();
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('V2EX'),
          centerTitle: true,
          actions: [
            if (auth.isLoggedIn)
              GlassIconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final result = await context.push('/create-topic');
                  if (result == true) {
                    ref.invalidate(hotTopicsProvider);
                    ref.invalidate(latestTopicsProvider);
                    ref.invalidate(followedTopicsProvider);
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
                    icon: Icon(Icons.local_fire_department, size: 16),
                  ),
                  ButtonSegment(
                    value: TopicTab.latest,
                    label: Text('最新'),
                    icon: Icon(Icons.access_time, size: 16),
                  ),
                  ButtonSegment(
                    value: TopicTab.followed,
                    label: Text('关注'),
                    icon: Icon(Icons.star, size: 16),
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
          flexibleSpace: const GradientAppBarBlur(),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(hotTopicsProvider);
            ref.invalidate(latestTopicsProvider);
            ref.invalidate(followedTopicsProvider);
            await ref.read(
              tab == TopicTab.hot
                  ? hotTopicsProvider.future
                  : tab == TopicTab.latest
                      ? latestTopicsProvider.future
                      : followedTopicsProvider.future,
            );
          },
          child: ScrollBottomDetector(
            onBottomReached: () {
              ref.invalidate(hotTopicsProvider);
              ref.invalidate(latestTopicsProvider);
              ref.invalidate(followedTopicsProvider);
            },
            child: tab == TopicTab.hot
                ? buildList(hotAsync, () => ref.invalidate(hotTopicsProvider))
                : tab == TopicTab.latest
                    ? buildList(latestAsync, () => ref.invalidate(latestTopicsProvider))
                    : buildList(ref.watch(followedTopicsProvider), () => ref.invalidate(followedTopicsProvider)),
          ),
        ),
      ),
    );
  }
}
