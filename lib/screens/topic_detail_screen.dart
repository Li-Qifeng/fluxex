import 'dart:async';
import 'dart:io' show Directory, File;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../models/topic.dart';
import '../models/reply.dart';
import '../providers/topic_detail_provider.dart';
import '../utils/app_toast.dart';
import '../utils/export_utils.dart';
import '../utils/screenshot_utils.dart';
import '../utils/db_helper.dart';
import '../widgets/reply_bottom_sheet.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/share_image_widget.dart';
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
  final Map<int, GlobalKey> _replyKeys = {};
  final Set<String> _participantNames = {};

  int _currentFloor = 0;
  int _totalReplies = 0;
  int? _dragTargetFloor;
  int? _dragStartFloor;
  double _dragAccumulatedDx = 0;
  Timer? _saveTimer;
  bool _isSearching = false;
  bool _onlyAuthor = false;
  String _searchQuery = '';
  String? _topicAuthor;

  // ── Export / Share helpers ──────────────────────────────────────

  Future<void> _shareImage() async {
    if (!mounted) return;
    final topic =
        await ref.read(topicDetailProvider(widget.topicId).future);
    if (!mounted) return;

    ShareImageTheme imageTheme =
        Theme.of(context).brightness == Brightness.dark
            ? ShareImageTheme.dark
            : ShareImageTheme.light;
    final captureKey = GlobalKey();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Drag handle ──
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(sheetCtx)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // ── Header: title + theme toggle ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          '分享图片',
                          style: Theme.of(sheetCtx)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        SegmentedButton<ShareImageTheme>(
                          segments: const [
                            ButtonSegment(
                              value: ShareImageTheme.light,
                              icon: Icon(Icons.light_mode, size: 18),
                            ),
                            ButtonSegment(
                              value: ShareImageTheme.dark,
                              icon: Icon(Icons.dark_mode, size: 18),
                            ),
                          ],
                          selected: {imageTheme},
                          onSelectionChanged: (set) {
                            setSheetState(() => imageTheme = set.first);
                          },
                          showSelectedIcon: false,
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Preview ──
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(sheetCtx).size.height * 0.5,
                    ),
                    child: SingleChildScrollView(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ShareImageWidget(
                          topic: topic,
                          boundaryKey: captureKey,
                          theme: imageTheme,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── Action buttons ──
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _captureAndSave(
                                  sheetCtx, captureKey, topic),
                              icon: const Icon(Icons.save_alt, size: 18),
                              label: const Text('保存/分享'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _captureAndCopy(
                                  sheetCtx, captureKey, topic),
                              icon: const Icon(Icons.copy, size: 18),
                              label: const Text('复制到剪贴板'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _captureAndShare(
                                  sheetCtx, captureKey, topic),
                              icon: const Icon(Icons.share, size: 18),
                              label: const Text('分享'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _captureAndSave(
      BuildContext ctx, GlobalKey key, Topic topic) async {
    try {
      final bytes = await captureWidget(key);
      Navigator.pop(ctx);
      final tempDir = Directory.systemTemp.createTempSync('fluxex_save');
      final file = File('${tempDir.path}/v2ex_${topic.id}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: '保存图片');
      if (mounted) AppToast.success(context, '请在分享菜单中选择保存到相册');
    } catch (e) {
      try {
        Navigator.pop(ctx);
      } catch (_) {}
      if (mounted) AppToast.error(context, '保存失败: $e');
    }
  }

  Future<void> _captureAndCopy(
      BuildContext ctx, GlobalKey key, Topic topic) async {
    try {
      final bytes = await captureWidget(key);
      Navigator.pop(ctx);
      final tempDir = Directory.systemTemp.createTempSync('fluxex_clip');
      final file = File('${tempDir.path}/v2ex_${topic.id}.png');
      await file.writeAsBytes(bytes);
      await Clipboard.setData(ClipboardData(text: file.path));
      if (mounted) AppToast.success(context, '图片已复制到剪贴板');
    } catch (e) {
      try {
        Navigator.pop(ctx);
      } catch (_) {}
      if (mounted) AppToast.error(context, '复制失败: $e');
    }
  }

  Future<void> _captureAndShare(
      BuildContext ctx, GlobalKey key, Topic topic) async {
    try {
      final bytes = await captureWidget(key);
      Navigator.pop(ctx);
      final tempDir = Directory.systemTemp.createTempSync('fluxex_share');
      final file = File('${tempDir.path}/v2ex_${topic.id}.png');
      await file.writeAsBytes(bytes);
      if (mounted) await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      try {
        Navigator.pop(ctx);
      } catch (_) {}
      if (mounted) AppToast.error(context, '分享失败: $e');
    }
  }

  Future<void> _exportMarkdown() async {
    if (!mounted) return;
    try {
      final topic =
          await ref.read(topicDetailProvider(widget.topicId).future);
      final replies =
          await ref.read(topicRepliesProvider(widget.topicId).future);
      final md = exportAsMarkdown(topic, replies);

      final tempDir = Directory.systemTemp.createTempSync('fluxex_export');
      final file = File('${tempDir.path}/v2ex_${topic.id}.md');
      await file.writeAsString(md);

      if (mounted) {
        await Share.shareXFiles([XFile(file.path)]);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '导出 Markdown 失败: $e');
      }
    }
  }

  Future<void> _exportHtml() async {
    if (!mounted) return;
    try {
      final topic =
          await ref.read(topicDetailProvider(widget.topicId).future);
      final replies =
          await ref.read(topicRepliesProvider(widget.topicId).future);
      final html = exportAsHtml(topic, replies);

      final tempDir = Directory.systemTemp.createTempSync('fluxex_export');
      final file = File('${tempDir.path}/v2ex_${topic.id}.html');
      await file.writeAsString(html);

      if (mounted) {
        await Share.shareXFiles([XFile(file.path)]);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '导出 HTML 失败: $e');
      }
    }
  }

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
    _replyKeys.clear();
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

    final viewportCenter = MediaQuery.of(context).size.height / 2;

    int? closestFloor;
    double minDistance = double.infinity;

    for (final entry in _replyKeys.entries) {
      final keyContext = entry.value.currentContext;
      if (keyContext == null) continue;
      final renderBox = keyContext.findRenderObject() as RenderBox?;
      if (renderBox == null) continue;

      final offset = renderBox.localToGlobal(Offset.zero);
      final itemCenter = offset.dy + renderBox.size.height / 2;
      final distance = (itemCenter - viewportCenter).abs();

      if (distance < minDistance) {
        minDistance = distance;
        closestFloor = entry.key;
      }
    }

    final floor = closestFloor ?? 0;
    if (floor != _currentFloor) {
      setState(() {
        _currentFloor = floor;
        _dragTargetFloor = null;
      });
    }

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || _currentFloor <= 0) return;
      DbHelper.addBrowseHistory(
        widget.topicId,
        '',
        lastFloor: _currentFloor,
        scrollOffset: _scrollController.offset.toInt(),
      );
    });
  }

  Future<void> _jumpToFloor(int floor) async {
    if (floor < 1 || floor > _totalReplies) return;
    final key = _replyKeys[floor];
    if (key?.currentContext != null) {
      await Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  void _jumpToFloorInstant(int floor) {
    if (floor < 1 || floor > _totalReplies) return;
    final key = _replyKeys[floor];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: Duration.zero,
        curve: Curves.linear,
        alignment: 0.1,
      );
    }
  }

  void _commitDragJump() {
    final target = _dragTargetFloor;
    if (target != null && target != _currentFloor) {
      _jumpToFloorInstant(target);
    }
    setState(() {
      _dragTargetFloor = null;
      _dragStartFloor = null;
      _dragAccumulatedDx = 0;
    });
  }

  void _showFloorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '跳转到楼层',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _totalReplies,
                  itemBuilder: (context, index) {
                    final floor = index + 1;
                    final isCurrent = floor == _currentFloor;
                    return FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _jumpToFloor(floor);
                      },
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        foregroundColor: isCurrent
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      child: Text('$floor'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleQuote(Reply reply) {
    String plain = reply.content?.trim() ?? '';
    if (plain.isEmpty && reply.contentRendered != null) {
      plain = reply.contentRendered!
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
    if (plain.length > 80) plain = '${plain.substring(0, 80)}…';
    final quoteBlock = plain.isNotEmpty ? '\n> $plain\n\n' : '\n';
    final text = '@${reply.member.username} $quoteBlock';
    _openReplySheet(initialText: text);
  }

  Future<void> _openReplySheet({String? initialText}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ReplyBottomSheet(
        topicId: widget.topicId,
        initialText: initialText,
        participants: _participantNames,
      ),
    );
    if (result == true) {
      ref.invalidate(topicRepliesProvider(widget.topicId));
      if (mounted) {
        AppToast.success(context, '回复成功');
      }
    }
  }

  List<({Reply reply, int floor})> _filterReplies(List<dynamic> replies, String author) {
    var result = replies.indexed.map((e) => (reply: e.$2 as Reply, floor: e.$1 + 1)).toList();
    if (_onlyAuthor) {
      result = result.where((e) => e.reply.member.username == author).toList();
    }
    if (_searchQuery.isEmpty) return result;
    final query = _searchQuery.toLowerCase();
    return result.where((e) {
      final content = (e.reply.contentRendered ?? e.reply.content ?? '').toLowerCase();
      return e.reply.member.username.toLowerCase().contains(query) || content.contains(query);
    }).toList();
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
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: '更多',
              onSelected: (value) async {
                switch (value) {
                  case 'bookmark':
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
                    break;
                  case 'share':
                    final topic = await ref.read(topicDetailProvider(widget.topicId).future);
                    await Share.share('${topic.title} https://www.v2ex.com/t/${widget.topicId}');
                    break;
                  case 'open_in_browser':
                    final url = Uri.parse('https://www.v2ex.com/t/${widget.topicId}');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                    break;
                  case 'share_image':
                    _shareImage();
                    break;
                  case 'export_md':
                    _exportMarkdown();
                    break;
                  case 'export_html':
                    _exportHtml();
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'bookmark',
                  child: ListTile(
                    leading: Icon(Icons.bookmark_border),
                    title: Text('收藏'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share),
                    title: Text('分享'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'open_in_browser',
                  child: ListTile(
                    leading: Icon(Icons.open_in_browser),
                    title: Text('在浏览器中打开'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'share_image',
                  child: ListTile(
                    leading: Icon(Icons.image_outlined),
                    title: Text('生成分享图片'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'export_md',
                  child: ListTile(
                    leading: Icon(Icons.description_outlined),
                    title: Text('导出 Markdown'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'export_html',
                  child: ListTile(
                    leading: Icon(Icons.code_outlined),
                    title: Text('导出 HTML'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
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
          _topicAuthor = topic.member.username;
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
                // 回复标题栏（直接贴在 header 下方，无 Divider）
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Text(
                          '${topic.replies} 回复',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        FilterChip(
                          label: const Text('只看楼主'),
                          selected: _onlyAuthor,
                          onSelected: (value) => setState(() => _onlyAuthor = value),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),
                repliesAsync.when(
                  data: (replies) {
                    if (replies.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: EmptyState(message: '暂无回复'),
                      );
                    }
                    final filtered = _filterReplies(replies, topic.member.username);
                    if (filtered.isEmpty) {
                      String msg;
                      if (_searchQuery.isNotEmpty) {
                        msg = '未找到匹配的回复';
                      } else if (_onlyAuthor) {
                        msg = '楼主暂无回复';
                      } else {
                        msg = '暂无回复';
                      }
                      return SliverToBoxAdapter(
                        child: EmptyState(message: msg),
                      );
                    }
                    // Populate participant names for @mention
                    _participantNames.clear();
                    for (final r in replies) {
                      _participantNames.add((r as Reply).member.username);
                    }
                    _replyKeys.clear();
                    for (final f in filtered) {
                      _replyKeys.putIfAbsent(f.floor, () => GlobalKey());
                    }

                    return SliverList.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final floor = filtered[index].floor;
                        final reply = filtered[index].reply;
                        return ReplyItem(
                          key: _replyKeys[floor],
                          reply: reply,
                          floor: floor,
                          onQuote: () => _handleQuote(reply),
                        );
                      },
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
            child: SizedBox(
              width: 56,
              height: 56,
              child: FloatingActionButton(
                heroTag: 'reply',
                onPressed: () => _openReplySheet(),
                elevation: 0,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.reply),
              ),
            ),
          ),
          if (_totalReplies > 0 && !_isSearching)
            Positioned(
              bottom: 88,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  setState(() => _dragTargetFloor = null);
                  _showFloorPicker();
                },
                onHorizontalDragStart: (_) {
                  _dragStartFloor = _currentFloor;
                  _dragAccumulatedDx = 0;
                  setState(() => _dragTargetFloor = null);
                },
                onHorizontalDragUpdate: (details) {
                  if (_totalReplies <= 1 || _dragStartFloor == null) return;
                  _dragAccumulatedDx += details.delta.dx;
                  const sensitivity = 30.0;
                  final deltaFloor = (-_dragAccumulatedDx / sensitivity).round();
                  final target = (_dragStartFloor! + deltaFloor).clamp(1, _totalReplies);
                  if (target != _dragTargetFloor) {
                    setState(() => _dragTargetFloor = target);
                    HapticFeedback.lightImpact();
                  }
                },
                onHorizontalDragEnd: (_) => _commitDragJump(),
                onHorizontalDragCancel: _commitDragJump,
                child: GlassContainer(
                  shape: LiquidRoundedSuperellipse(borderRadius: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text(
                    (_dragTargetFloor ?? _currentFloor) > 0
                        ? '${_dragTargetFloor ?? _currentFloor} / $_totalReplies'
                        : '0 / $_totalReplies',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _dragTargetFloor != null
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onPrimaryContainer,
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
