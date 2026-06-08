import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_client.dart';

class ReplyBottomSheet extends ConsumerStatefulWidget {
  final int topicId;

  const ReplyBottomSheet({super.key, required this.topicId});

  @override
  ConsumerState<ReplyBottomSheet> createState() => _ReplyBottomSheetState();
}

class _ReplyBottomSheetState extends ConsumerState<ReplyBottomSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    try {
      final api = V2exApiClient();
      await api.replyTopic(widget.topicId, content);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('回复失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部把手
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 标题栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '回复',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.primary,
                            ),
                          )
                        : Text(
                            '发送',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 输入区
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 120, maxHeight: 320),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: '输入回复内容...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                maxLines: null,
                autofocus: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
