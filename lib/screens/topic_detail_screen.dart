import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/topic_detail_provider.dart';
import '../utils/db_helper.dart';
import '../widgets/reply_bottom_sheet.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/topic_header.dart';
import '../widgets/reply_item.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  final int topicId;

  const TopicDetailScreen({super.key, required this.topicId});

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentFloor = 0;
  int _totalReplies = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || _totalReplies == 0) return;
    // 粗略估算当前楼层：Header 约 300dp，每个 reply 约 120dp
    const headerEstimate = 300.0;
    const itemEstimate = 120.0;
    final offset = _scrollController.offset;
    if (offset < headerEstimate) {
      if (_currentFloor != 0) {
        setState(() => _currentFloor = 0);
      }
      return;
    }
    final estimated = ((offset - headerEstimate) / itemEstimate).floor() + 1;
    final floor = estimated.clamp(1, _totalReplies);
    if (floor != _currentFloor) {
      setState(() => _currentFloor = floor);
    }
  }

  Future<void> _jumpToFloor(int floor) async {
    if (floor < 1 || floor > _totalReplies) return;
    const headerEstimate = 300.0;
    const itemEstimate = 120.0;
    final offset = headerEstimate + (floor - 1) * itemEstimate;
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _showFloorPicker() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('跳转到楼层'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '1 ~ $_totalReplies',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('跳转'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final floor = int.tryParse(controller.text.trim()) ?? 0;
      controller.dispose();
      if (floor >= 1 && floor <= _totalReplies) {
        await _jumpToFloor(floor);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请输入 1~$_totalReplies 的有效楼层')),
        );
      }
    } else {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicAsync = ref.watch(topicDetailProvider(widget.topicId));
    final repliesAsync = ref.watch(topicRepliesProvider(widget.topicId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('话题详情'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            tooltip: '收藏',
            onPressed: () async {
              final topic = await ref.read(topicDetailProvider(widget.topicId).future);
              final isBookmarked = await DbHelper.isBookmarked(widget.topicId);
              if (isBookmarked) {
                await DbHelper.removeBookmark(widget.topicId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已取消收藏')),
                  );
                }
              } else {
                await DbHelper.addBookmark(widget.topicId, topic.title);
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
              final url = Uri.parse('https://www.v2ex.com/t/${widget.topicId}');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: topicAsync.when(
        data: (topic) {
          DbHelper.addBrowseHistory(widget.topicId, topic.title);
          _totalReplies = topic.replies;
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(topicDetailProvider(widget.topicId));
              ref.invalidate(topicRepliesProvider(widget.topicId));
              await ref.read(topicDetailProvider(widget.topicId).future);
            },
            child: CustomScrollView(
              controller: _scrollController,
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
                const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
              ],
            ),
          );
        },
        loading: () => const TopicDetailSkeleton(),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text('话题加载失败: $err'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(topicDetailProvider(widget.topicId)),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'reply',
              onPressed: () async {
                final result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => ReplyBottomSheet(topicId: widget.topicId),
                );
                if (result == true) {
                  ref.invalidate(topicRepliesProvider(widget.topicId));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('回复成功')),
                    );
                  }
                }
              },
              child: const Icon(Icons.reply),
            ),
          ),
          // 楼层进度胶囊
          if (_totalReplies > 0)
            Positioned(
              bottom: 88,
              right: 16,
              child: GestureDetector(
                onTap: _showFloorPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _currentFloor > 0
                        ? '$_currentFloor / $_totalReplies'
                        : '0 / $_totalReplies',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
