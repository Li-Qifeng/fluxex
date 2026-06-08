import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_client.dart';
import '../utils/app_toast.dart';

class ReplyScreen extends ConsumerStatefulWidget {
  final int topicId;

  const ReplyScreen({super.key, required this.topicId});

  @override
  ConsumerState<ReplyScreen> createState() => _ReplyScreenState();
}

class _ReplyScreenState extends ConsumerState<ReplyScreen> {
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
        AppToast.success(context, '回复成功');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '回复失败: $e');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('回复'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _sending ? null : _send,
            child: _sending
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('发送'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: '输入回复内容...',
            border: InputBorder.none,
          ),
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          autofocus: true,
        ),
      ),
    );
  }
}
