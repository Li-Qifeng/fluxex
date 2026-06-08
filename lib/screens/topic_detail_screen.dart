import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/reply.dart';
import '../providers/topic_detail_provider.dart';
import '../utils/app_toast.dart';
import '../utils/db_helper.dart';
import '../widgets/reply_bottom_sheet.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/state_widgets.dart';
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
  final TextEditingController _searchController = TextEditingController();
  int _currentFloor = 0;
  int _totalReplies = 0;
  Timer? _saveTimer;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _restorePosition();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }

  Future<void> _restorePosition() async {
    final entry = await DbHelper.getBrowseHistoryEntry(widget.topicId);
    if (entry == null) return;
    final floor = (entry['last_floor'] as num?)?.toInt() ?? 0;
    if (floor <= 0 || !mounted) return;
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.bookmark_added, size: 18),
            const SizedBox(width: 8),
            Text('上次阅读到第 $floor 楼'),
          ],
        ),
        action: SnackBarAction(
          label: '跳转',
          onPressed: () => _jumpToFloor(floor),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _onScroll() {
    if (!mounted || _totalReplies == 0 || _isSearching) return;
    const headerEstimate = 300.0;
    const itemEstimate = 120.0;
    final offset = _scrollController.offset;
    int floor;
    if (offset < headerEstimate) {
      floor = 0;
    } else {
      floor = ((offset - headerEstimate) / itemEstimate).floor() + 1;
      floor = floor.clamp(1, _totalReplies);
    }
    if (floor != _currentFloor) {
      setState(() => _currentFloor = floor);
    }
    // Debounce save position every 1.5s after scroll stops
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || _currentFloor <= 0) return;
      DbHelper.addBrowseHistory(
        widget.topicId,
        '',
        lastFloor: _currentFloor,
        scrollOffset: offset.toInt(),
      );
    });
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
        AppToast.error(context, '请输入 1~$_totalReplies 的有效楼层');
      }
    } else {
      controller.dispose();
    }
  }

  List<({Reply reply, int floor})> _filterReplies(List<dynamic> replies) {
    if (_searchQuery.isEmpty) {
      return replies.indexed.map((e) => (reply: e.$2 as Reply, floor: e.$1 + 1)).toList();
    }
    final query = _searchQuery.toLowerCase();
    final result = <({Reply reply, int floor})>[];
    for (var i = 0; i < replies.length; i++) {
      final r = replies[i] as Reply;
      final content = (r.contentRendered ?? r.content ?? '').toLowerCase();
      if (r.member.username.toLowerCase().contains(query) ||
          content.contains(query)) {
        result.add((reply: r, floor: i + 1));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final topicAsync = ref.watch(topicDetailProvider(widget.topicId));
    final repliesAsync = ref.watch(topicRepliesProvider(widget.topicId));

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '搜索回复内容或用户名...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                style: Theme.of(context).textTheme.titleMedium,
                onChanged: (value) => setState(() => _searchQuery = value.trim()),
              )
            : const Text('话题详情'),
        centerTitle: !_isSearching,
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              )
            : null,
        actions: [
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: '搜索回复',
              onPressed: () => setState(() => _isSearching = true),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_border),
              tooltip: '收藏',
              onPressed: () async {
                final topic = await ref.read(topicDetailProvider(widget.topicId).future);
                final isBookmarked = await DbHelper.isBookmarked(widget.topicId);
                if (isBookmarked) {
                  await DbHelper.removeBookmark(widget.topicId);
                  if (context.mounted) {
                    AppToast.info(context, '已取消收藏');
                  }
                } else {
                  await DbHelper.addBookmark(widget.topicId, topic.title);
                  if (context.mounted) {
                    AppToast.success(context, '已收藏');
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
          ] else if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
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
                        child: EmptyState(message: '暂无回复'),
                      );
                    }
                    final filtered = _filterReplies(replies);
                    if (filtered.isEmpty && _searchQuery.isNotEmpty) {
                      return const SliverToBoxAdapter(
                        child: EmptyState(message: '未找到匹配的回复'),
                      );
                    }
                    return SliverList.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => ReplyItem(
                        reply: filtered[index].reply,
                        floor: filtered[index].floor,
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: LoadingState(),
                  ),
                  error: (err, stack) => SliverToBoxAdapter(
                    child: ErrorState(
                      message: '回复加载失败: $err',
                      onRetry: () => ref.invalidate(topicRepliesProvider(widget.topicId)),
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
              ],
            ),
          );
        },
        loading: () => const TopicDetailSkeleton(),
        error: (err, stack) => ErrorState(
          message: '话题加载失败: $err',
          onRetry: () => ref.invalidate(topicDetailProvider(widget.topicId)),
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
                    AppToast.success(context, '回复成功');
                  }
                }
              },
              child: const Icon(Icons.reply),
            ),
          ),
          // 楼层进度胶囊（搜索时隐藏）
          if (_totalReplies > 0 && !_isSearching)
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
