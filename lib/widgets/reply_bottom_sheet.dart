import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_client.dart';
import '../utils/app_toast.dart';
import '../utils/db_helper.dart';
import 'emoji_picker.dart';

class ReplyBottomSheet extends ConsumerStatefulWidget {
  final int topicId;
  final String? initialText;
  final Set<String> participants;

  const ReplyBottomSheet({
    super.key,
    required this.topicId,
    this.initialText,
    this.participants = const {},
  });

  @override
  ConsumerState<ReplyBottomSheet> createState() => _ReplyBottomSheetState();
}

class _ReplyBottomSheetState extends ConsumerState<ReplyBottomSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _sending = false;
  bool _showEmojiPicker = false;
  List<String> _mentionSuggestions = [];
  int? _mentionStart;
  int _selectedMentionIndex = 0;
  Timer? _draftTimer;

  String get _draftId => 'reply_${widget.topicId}';

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) {
      _controller.text = widget.initialText!;
      _controller.selection = TextSelection.collapsed(offset: widget.initialText!.length);
    } else {
      _restoreDraft();
    }
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _saveDraftNow();
    _draftTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final draft = await DbHelper.getDraft(_draftId);
    if (draft == null || !mounted) return;
    final content = draft['content'] as String? ?? '';
    if (content.trim().isNotEmpty) {
      _controller.text = content;
      _controller.selection = TextSelection.collapsed(offset: content.length);
      if (mounted) {
        AppToast.info(context, '已恢复草稿');
      }
    }
  }

  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(seconds: 2), _saveDraftNow);
  }

  Future<void> _saveDraftNow() async {
    final content = _controller.text;
    if (content.trim().isEmpty) {
      await DbHelper.deleteDraft(_draftId);
      return;
    }
    await DbHelper.saveDraft(
      draftId: _draftId,
      type: 'reply',
      content: content,
      extra: widget.topicId.toString(),
    );
  }

  void _onTextChanged() {
    _scheduleDraftSave();
    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isValid || selection.start != selection.end) {
      setState(() {
        _mentionSuggestions = [];
        _mentionStart = null;
        _selectedMentionIndex = 0;
      });
      return;
    }
    final cursor = selection.start;
    if (cursor <= 0) {
      setState(() {
        _mentionSuggestions = [];
        _mentionStart = null;
        _selectedMentionIndex = 0;
      });
      return;
    }
    int? atIndex;
    for (int i = cursor - 1; i >= 0; i--) {
      if (text[i] == '@') {
        atIndex = i;
        break;
      }
      if (text[i] == ' ' || text[i] == '\n') break;
    }
    if (atIndex != null) {
      final query = text.substring(atIndex + 1, cursor).toLowerCase();
      if (query.contains(' ') || query.contains('\n')) {
        setState(() {
          _mentionSuggestions = [];
          _mentionStart = null;
        });
        return;
      }
      final suggestions = widget.participants
          .where((name) => name.toLowerCase().contains(query))
          .toList();
      setState(() {
        _mentionStart = atIndex;
        _mentionSuggestions = suggestions;
        _selectedMentionIndex = 0;
      });
    } else {
      setState(() {
        _mentionSuggestions = [];
        _mentionStart = null;
        _selectedMentionIndex = 0;
      });
    }
  }

  void _insertMention(String username) {
    if (_mentionStart == null) return;
    final text = _controller.text;
    final cursor = _controller.selection.start;
    final before = text.substring(0, _mentionStart);
    final after = text.substring(cursor);
    final insert = '@$username ';
    _controller.text = before + insert + after;
    _controller.selection = TextSelection.collapsed(offset: before.length + insert.length);
    setState(() {
      _mentionSuggestions = [];
      _mentionStart = null;
      _selectedMentionIndex = 0;
    });
  }

  void _insertEmoji(String emoji) {
    if (emoji.isEmpty) return; // backspace
    final text = _controller.text;
    final cursor = _controller.selection.start;
    _controller.text = text.substring(0, cursor) + emoji + text.substring(cursor);
    _controller.selection = TextSelection.collapsed(offset: cursor + emoji.length);
    setState(() {});
  }

  Future<void> _send() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    try {
      final api = V2exApiClient();
      await api.replyTopic(widget.topicId, content);
      await DbHelper.deleteDraft(_draftId);
      if (mounted) {
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
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '回复',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: cs.onSurface),
                  ),
                  IconButton(
                    icon: Icon(
                      _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                      size: 22,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() => _showEmojiPicker = !_showEmojiPicker);
                      if (!_showEmojiPicker) {
                        _focusNode.requestFocus();
                      } else {
                        _focusNode.unfocus();
                      }
                    },
                    tooltip: _showEmojiPicker ? '显示键盘' : '表情',
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                          )
                        : Text(
                            '发送',
                            style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary),
                          ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_mentionSuggestions.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Text(
                        '选择提及用户',
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _mentionSuggestions.length,
                        itemBuilder: (context, index) {
                          final name = _mentionSuggestions[index];
                          final isSelected = index == _selectedMentionIndex;
                          return ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            minTileHeight: 40,
                            leading: CircleAvatar(
                              radius: 12,
                              backgroundColor: isSelected ? cs.primary : cs.primaryContainer,
                              child: Text(
                                name[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected ? cs.onPrimary : cs.onPrimaryContainer,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? cs.primary : cs.onSurface,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            tileColor: isSelected ? cs.primaryContainer.withValues(alpha: 0.3) : null,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            onTap: () => _insertMention(name),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            Focus(
              onKeyEvent: (node, event) {
                if (_mentionSuggestions.isEmpty) return KeyEventResult.ignored;
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                    setState(() {
                      _mentionSuggestions = [];
                      _mentionStart = null;
                      _selectedMentionIndex = 0;
                    });
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    setState(() => _selectedMentionIndex = (_selectedMentionIndex + 1).clamp(0, _mentionSuggestions.length - 1));
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    setState(() => _selectedMentionIndex = (_selectedMentionIndex - 1).clamp(0, _mentionSuggestions.length - 1));
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.tab) {
                    _insertMention(_mentionSuggestions[_selectedMentionIndex]);
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 120, maxHeight: 320),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: '输入回复内容...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  maxLines: null,
                  autofocus: true,
                  textAlignVertical: TextAlignVertical.top,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (value) => _send(),
                ),
              ),
            ),
            if (_showEmojiPicker)
              SizedBox(
                height: min(280, MediaQuery.of(context).size.height * 0.35),
                child: EmojiPickerPanel(
                  onEmojiSelected: _insertEmoji,
                  onBackspacePressed: () {
                    final text = _controller.text;
                    final cursor = _controller.selection.start;
                    if (cursor > 0) {
                      // Simple backspace — remove last character or grapheme
                      _controller.text = text.substring(0, cursor - 1) + text.substring(cursor);
                      _controller.selection = TextSelection.collapsed(offset: max(0, cursor - 1));
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
