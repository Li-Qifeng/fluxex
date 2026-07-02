import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_toast.dart';
import '../utils/db_helper.dart';
import '../widgets/state_widgets.dart';

class DraftsScreen extends ConsumerStatefulWidget {
  const DraftsScreen({super.key});

  @override
  ConsumerState<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends ConsumerState<DraftsScreen> {
  List<Map<String, dynamic>> _drafts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = await DbHelper.database;
    final drafts =
        await db.query('drafts', orderBy: 'saved_at DESC');
    if (mounted) {
      setState(() {
        _drafts = drafts;
        _loading = false;
      });
    }
  }

  Future<void> _delete(String draftId) async {
    await DbHelper.deleteDraft(draftId);
    setState(() => _drafts.removeWhere((e) => e['draft_id'] == draftId));
    if (mounted) AppToast.success(context, '草稿已删除');
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'reply':
        return '回复';
      case 'topic':
        return '新话题';
      default:
        return type;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'reply':
        return Icons.reply_outlined;
      case 'topic':
        return Icons.add_comment_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('草稿'),
        centerTitle: true,
        actions: _drafts.isEmpty
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: '清空所有',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('确认清空'),
                        content: const Text('确定要删除所有草稿吗？此操作不可恢复。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.error,
                            ),
                            child: const Text('删除全部'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      final db = await DbHelper.database;
                      await db.delete('drafts');
                      setState(() => _drafts.clear());
                      if (mounted) AppToast.success(context, '所有草稿已删除');
                    }
                  },
                ),
              ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _drafts.isEmpty
              ? const EmptyState(message: '暂无草稿')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _drafts.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (context, index) {
                    final draft = _drafts[index];
                    final draftId = draft['draft_id'] as String;
                    final type = draft['type'] as String? ?? '';
                    final title = draft['title'] as String?;
                    final content = draft['content'] as String? ?? '';
                    final savedAt = DateTime.fromMillisecondsSinceEpoch(
                      draft['saved_at'] as int,
                    );
                    final timeStr =
                        '${savedAt.month}/${savedAt.day} ${savedAt.hour.toString().padLeft(2, '0')}:${savedAt.minute.toString().padLeft(2, '0')}';

                    // Parse topicId from draft_id for reply drafts
                    int? replyTopicId;
                    if (type == 'reply' && draftId.startsWith('reply:')) {
                      final parts = draftId.split(':');
                      if (parts.length >= 2) {
                        replyTopicId = int.tryParse(parts[1]);
                      }
                    }

                    return Dismissible(
                      key: ValueKey(draftId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        color: cs.error,
                        child: Icon(Icons.delete_outline, color: cs.onError),
                      ),
                      onDismissed: (_) => _delete(draftId),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cs.tertiaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _typeIcon(type),
                            color: cs.tertiary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          title ?? (type == 'reply' ? '回复草稿' : '无标题'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${_typeLabel(type)} · $timeStr\n${content.length > 60 ? '${content.substring(0, 60)}...' : content}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.outline,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: cs.outline),
                          onSelected: (value) async {
                            switch (value) {
                              case 'delete':
                                _delete(draftId);
                                break;
                              case 'open':
                                if (replyTopicId != null) {
                                  context.push('/topic/$replyTopicId');
                                } else if (type == 'topic') {
                                  context.push('/create-topic');
                                }
                                break;
                              case 'copy':
                                await Clipboard.setData(
                                  ClipboardData(text: content),
                                );
                                if (mounted) {
                                  AppToast.success(context, '内容已复制');
                                }
                                break;
                            }
                          },
                          itemBuilder: (ctx) => [
                            if (replyTopicId != null || type == 'topic')
                              const PopupMenuItem(
                                value: 'open',
                                child: ListTile(
                                  leading: Icon(Icons.open_in_new, size: 18),
                                  title: Text('打开', style: TextStyle(fontSize: 14)),
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'copy',
                              child: ListTile(
                                leading: Icon(Icons.copy, size: 18),
                                title: Text('复制内容', style: TextStyle(fontSize: 14)),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete_outline, size: 18),
                                title: Text('删除', style: TextStyle(fontSize: 14)),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (replyTopicId != null) {
                            context.push('/topic/$replyTopicId');
                          } else if (type == 'topic') {
                            context.push('/create-topic');
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}