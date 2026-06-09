import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/node.dart';
import '../providers/api_client.dart';
import '../providers/node_provider.dart';
import '../utils/app_toast.dart';
import '../widgets/cached_avatar.dart';

class CreateTopicScreen extends ConsumerStatefulWidget {
  const CreateTopicScreen({super.key});

  @override
  ConsumerState<CreateTopicScreen> createState() => _CreateTopicScreenState();
}

class _CreateTopicScreenState extends ConsumerState<CreateTopicScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  Node? _selectedNode;
  bool _sending = false;
  bool _uploadingImage = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (_selectedNode == null) {
      AppToast.error(context, '请先选择节点');
      return;
    }
    if (title.isEmpty) {
      AppToast.error(context, '请输入标题');
      return;
    }

    setState(() => _sending = true);
    try {
      final api = V2exApiClient();
      await api.createTopic(_selectedNode!.name, title, content);
      if (mounted) {
        AppToast.success(context, '发布成功');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '发布失败: $e');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }


  Future<void> _pickAndUploadImage() async {
    if (_uploadingImage) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;

    setState(() => _uploadingImage = true);
    try {
      final api = V2exApiClient();
      final url = await api.uploadImage(
        bytes: bytes,
        filename: file.name,
        mimeType: _mimeTypeFor(file.name),
      );
      _insertAtCursor('![${file.name}]($url)');
      if (mounted) AppToast.success(context, '图片已插入正文');
    } catch (e) {
      if (mounted) AppToast.error(context, '图片上传失败: $e');
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  void _insertAtCursor(String text) {
    final selection = _contentController.selection;
    final value = _contentController.text;
    final start = selection.isValid ? selection.start : value.length;
    final end = selection.isValid ? selection.end : value.length;
    final prefix = value.substring(0, start);
    final suffix = value.substring(end);
    final needsLeadingBreak = prefix.isNotEmpty && !prefix.endsWith('\n');
    final needsTrailingBreak = suffix.isNotEmpty && !suffix.startsWith('\n');
    final insert = '${needsLeadingBreak ? '\n' : ''}$text${needsTrailingBreak ? '\n' : ''}';
    _contentController.text = '$prefix$insert$suffix';
    final cursor = prefix.length + insert.length;
    _contentController.selection = TextSelection.collapsed(offset: cursor);
  }

  String _mimeTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final nodesAsync = ref.watch(allNodesProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('发布新话题'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _sending ? null : _send,
            child: _sending
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                  )
                : Text(
                    '发布',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: nodesAsync.when(
        data: (nodes) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 节点选择
              DropdownMenu<Node>(
                expandedInsets: EdgeInsets.zero,
                label: const Text('选择节点'),
                hintText: '搜索或选择节点...',
                leadingIcon: const Icon(Icons.account_tree_outlined),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSelected: (node) => setState(() => _selectedNode = node),
                dropdownMenuEntries: nodes.map((node) {
                  return DropdownMenuEntry(
                    value: node,
                    label: node.title,
                    labelWidget: Row(
                      children: [
                        if (node.avatarNormal.isNotEmpty)
                          CachedAvatar(
                            imageUrl: node.avatarNormal,
                            radius: 12,
                            fallbackText: node.title,
                          )
                        else
                          CircleAvatar(radius: 12, child: Text(node.title[0])),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${node.title} · ${node.titleAlternative}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              if (_selectedNode != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      '已选择: ${_selectedNode!.title}',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              // 标题
              TextField(
                controller: _titleController,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: '标题',
                  hintText: '请输入话题标题...',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              // 正文
              TextField(
                controller: _contentController,
                maxLines: null,
                minLines: 8,
                maxLength: 20000,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: '正文内容',
                  hintText: '支持 Markdown 语法，可添加图片...',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _uploadingImage ? null : _pickAndUploadImage,
                  icon: _uploadingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.image_outlined),
                  label: Text(_uploadingImage ? '上传中...' : '添加图片'),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('节点加载失败: $err'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(allNodesProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
