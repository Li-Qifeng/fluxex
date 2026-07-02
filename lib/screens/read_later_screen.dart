import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_toast.dart';
import '../utils/db_helper.dart';
import '../widgets/state_widgets.dart';

class ReadLaterScreen extends ConsumerStatefulWidget {
  const ReadLaterScreen({super.key});

  @override
  ConsumerState<ReadLaterScreen> createState() => _ReadLaterScreenState();
}

class _ReadLaterScreenState extends ConsumerState<ReadLaterScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await DbHelper.getReadLater();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _remove(int topicId) async {
    await DbHelper.removeReadLater(topicId);
    setState(() => _items.removeWhere((e) => e['topic_id'] == topicId));
    if (mounted) AppToast.success(context, '已移除');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('稍后阅读'),
        centerTitle: true,
        actions: _items.isEmpty
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: '清空',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('确认清空'),
                        content: const Text('确定要清空所有稍后阅读吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('清空'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      for (final item in _items) {
                        await DbHelper.removeReadLater(item['topic_id'] as int);
                      }
                      setState(() => _items.clear());
                      if (mounted) AppToast.success(context, '已清空');
                    }
                  },
                ),
              ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final topicId = item['topic_id'] as int;
                    final title = (item['title'] as String?) ?? '无标题';
                    final addedAt = DateTime.fromMillisecondsSinceEpoch(
                      item['added_at'] as int,
                    );
                    final timeStr =
                        '${addedAt.month}/${addedAt.day} ${addedAt.hour.toString().padLeft(2, '0')}:${addedAt.minute.toString().padLeft(2, '0')}';

                    return Dismissible(
                      key: ValueKey(topicId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        color: cs.error,
                        child: Icon(Icons.delete_outline, color: cs.onError),
                      ),
                      onDismissed: (_) => _remove(topicId),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.bookmark_border,
                            color: cs.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '加入于 $timeStr',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.outline,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: cs.outline,
                        ),
                        onTap: () {
                          context.push('/topic/$topicId');
                        },
                      ),
                    );
                  },
                ),
    );
  }
}