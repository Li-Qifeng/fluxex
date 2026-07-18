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
import '../widgets/gradient_app_bar_blur.dart';

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
  bool _isExpandedFloor = false;
  Timer? _saveTimer;
  bool _isSearching = false;
  bool _onlyAuthor = false;
  String _searchQuery = '';
  double _scrollProgress = 0.0;

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

    // 更新阅读进度
    final pos = _scrollController.position;
    if (pos.maxScrollExtent > 0) {
      _scrollProgress = (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
    }

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
      return;
    }

    // Fallback: proportional scroll estimation + retry after build
    final maxExtent = _scrollController.position.maxScrollExtent;
    final estimated = ((floor - 1) / _totalReplies) * maxExtent;
    await _scrollController.animateTo(
      estimated.clamp(0.0, maxExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Wait for target item to be built by SliverList, then precisely position
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    final retryKey = _replyKeys[floor];
    if (retryKey?.currentContext != null) {
      await Scrollable.ensureVisible(
        retryKey!.currentContext!,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  void _commitDragJump() {
    final target = _dragTargetFloor;
    if (target != null && target != _currentFloor) {
      _jumpToFloor(target);
    }
    setState(() {
      _dragTargetFloor = null;
    });
  }

  void _showFloorInputDialog() {
    HapticFeedback.mediumImpact();
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('跳转到楼层'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1 - $_totalReplies',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onSubmitted: (value) {
            final floor = int.tryParse(value.trim());
            Navigator.pop(ctx);
            if (floor != null && floor >= 1 && floor <= _totalReplies) {
              _jumpToFloor(floor);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final floor = int.tryParse(controller.text.trim());
              Navigator.pop(ctx);
              if (floor != null && floor >= 1 && floor <= _totalReplies) {
                _jumpToFloor(floor);
              }
            },
            child: const Text('跳转'),
          ),
        ],
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
      extendBodyBehindAppBar: true,
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
                  case 'read_later':
                    final topic = await ref.read(topicDetailProvider(widget.topicId).future);
                    final isLater = await DbHelper.isReadLater(widget.topicId);
                    if (isLater) {
                      await DbHelper.removeReadLater(widget.topicId);
                      if (context.mounted) {
                        AppToast.info(context, '已移除稍后阅读');
                      }
                    } else {
                      await DbHelper.addReadLater(widget.topicId, topic.title);
                      if (context.mounted) {
                        AppToast.success(context, '已加入稍后阅读');
                      }
                    }
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
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'read_later',
                  child: ListTile(
                    leading: Icon(Icons.bookmark_border_outlined),
                    title: Text('稍后阅读'),
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
        flexibleSpace: const GradientAppBarBlur(maxBlur: 20, tintAlpha: 0.50),
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
                  child: SizedBox(
                    height: MediaQuery.paddingOf(context).top + kToolbarHeight,
                  ),
                ),
                // 阅读进度条
                if (_totalReplies > 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 4,
                        bottom: 0,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _scrollProgress,
                          minHeight: 3,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
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
                      _participantNames.add(r.member.username);
                    }
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
              child: GlassButton(
                icon: const Icon(Icons.reply),
                onTap: () => _openReplySheet(),
                width: 56,
                height: 56,
                glowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
          if (_totalReplies > 0 && !_isSearching)
            Positioned(
              bottom: 88,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedOpacity(
                    opacity: _dragTargetFloor != null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 120),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8, right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        '${_dragTargetFloor ?? ''} 楼',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  _FloorDragCapsule(
                    totalReplies: _totalReplies,
                    currentFloor: _currentFloor,
                    dragTargetFloor: _dragTargetFloor,
                    isExpanded: _isExpandedFloor,
                    onTap: () =>
                        setState(() => _isExpandedFloor = !_isExpandedFloor),
                    onLongPress: () {
                      HapticFeedback.heavyImpact();
                      _showFloorInputDialog();
                    },
                    onDragUpdate: (targetFloor, expand) {
                      setState(() {
                        _dragTargetFloor = targetFloor;
                        if (expand) _isExpandedFloor = true;
                      });
                      HapticFeedback.selectionClick();
                    },
                    onDragEnd: (targetFloor) {
                      _dragTargetFloor = targetFloor;
                      _commitDragJump();
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Floor capsule replaced by _FloorDragCapsule ──

// ── Floor drag capsule widget ──────────────────────────────────────
// 完全自包含的楼层选择控件，使用绝对坐标跟踪手指，跟手无延迟。
// 碰撞检测：仅垂直拖拽，无水平-垂直方向竞争。
// 灵敏度：根据控件高度动态计算 px-per-floor，收起~60px/展开~180px 均可覆盖全部楼层。

class _FloorDragCapsule extends StatefulWidget {
  final int totalReplies;
  final int currentFloor;
  final int? dragTargetFloor;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final void Function(int targetFloor, bool expand) onDragUpdate;
  final void Function(int targetFloor) onDragEnd;

  const _FloorDragCapsule({
    required this.totalReplies,
    required this.currentFloor,
    required this.dragTargetFloor,
    required this.isExpanded,
    required this.onTap,
    required this.onLongPress,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  State<_FloorDragCapsule> createState() => _FloorDragCapsuleState();
}

class _FloorDragCapsuleState extends State<_FloorDragCapsule> {
  final GlobalKey _widgetKey = GlobalKey();
  int _startFloor = 0;
  double _dragStartY = 0;
  int _lastReportedFloor = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _lastReportedFloor = widget.dragTargetFloor ?? widget.currentFloor;
  }

  @override
  void didUpdateWidget(_FloorDragCapsule old) {
    super.didUpdateWidget(old);
    _lastReportedFloor = widget.dragTargetFloor ?? widget.currentFloor;
  }

  // 控件高度 / 总楼层数 = 拖动覆盖全部楼层所需 px
  double _getSensitivity() {
    final renderBox =
        _widgetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return 12.0;
    final height = renderBox.size.height;
    if (widget.totalReplies <= 1 || height <= 0) return 12.0;
    return height / widget.totalReplies;
  }

  int _floorFromDelta(double dy) {
    final deltaFloor = -(dy / _getSensitivity());
    return (_startFloor + deltaFloor.round()).clamp(1, widget.totalReplies);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayFloor = widget.dragTargetFloor ?? widget.currentFloor;

    // 使用 Listener 监听原始指针事件（无手势竞技场延迟）
    // 内部 GestureDetector 只处理 tap/longpress，不参与拖拽竞争
    return Listener(
      key: _widgetKey,
      onPointerDown: (event) {
        _isDragging = false;
        _startFloor = displayFloor;
        _dragStartY = event.position.dy;
      },
      onPointerMove: (event) {
        if (widget.totalReplies <= 1) return;
        final dy = event.position.dy - _dragStartY;
        // 移动超过 4px 才判定为拖拽（防误触）
        if (!_isDragging && dy.abs() < 4) return;
        _isDragging = true;
        final target = _floorFromDelta(dy);
        if (target != _lastReportedFloor) {
          _lastReportedFloor = target;
          widget.onDragUpdate(target, true);
        }
      },
      onPointerUp: (event) {
        if (_isDragging) {
          widget.onDragEnd(widget.dragTargetFloor ?? widget.currentFloor);
        }
        _isDragging = false;
      },
      onPointerCancel: (event) {
        if (_isDragging) {
          widget.onDragEnd(widget.currentFloor);
        }
        _isDragging = false;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: widget.isExpanded ? 180 : null,
        child: GlassContainer(
          shape: const LiquidRoundedSuperellipse(borderRadius: 18),
          child: widget.isExpanded
              ? _buildExpanded(cs, displayFloor)
              : _buildCollapsed(cs, displayFloor),
        ),
      ),
      ),
    );
  }

  Widget _buildCollapsed(ColorScheme cs, int displayFloor) {
    final progress = widget.totalReplies > 0
        ? (displayFloor / widget.totalReplies).clamp(0.0, 1.0)
        : 0.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 进度条
        Container(
          width: 100,
          height: 3,
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          decoration: BoxDecoration(
            color: cs.outline.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: widget.dragTargetFloor != null
                    ? cs.primary
                    : cs.onPrimaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 12, right: 12),
          child: Text(
            '$displayFloor / ${widget.totalReplies} 楼',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.dragTargetFloor != null
                  ? cs.primary
                  : cs.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpanded(ColorScheme cs, int displayFloor) {
    final progress = widget.totalReplies > 0
        ? (displayFloor / widget.totalReplies).clamp(0.0, 1.0)
        : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$displayFloor 楼',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 8),
          // 自定义进度条（代替 Flutter Slider，消除触摸竞争）
          Container(
            width: 120,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.totalReplies} 楼',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
