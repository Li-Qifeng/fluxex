import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

/// 轻量化的 emoji 选择面板；在 BottomSheet 内使用。
class EmojiPickerPanel extends StatelessWidget {
  final void Function(String emoji) onEmojiSelected;
  final VoidCallback? onBackspacePressed;

  const EmojiPickerPanel({
    super.key,
    required this.onEmojiSelected,
    this.onBackspacePressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 280,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) => onEmojiSelected(emoji.emoji),
        config: Config(
          height: 280,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            columns: 8,
            emojiSizeMax: 28,
            verticalSpacing: 2,
            horizontalSpacing: 2,
            backgroundColor: cs.surface,
            gridPadding: const EdgeInsets.symmetric(horizontal: 4),
            recentsLimit: 32,
            replaceEmojiOnLimitExceed: true,
            buttonMode: ButtonMode.MATERIAL,
          ),
          categoryViewConfig: CategoryViewConfig(
            initCategory: Category.RECENT,
            recentTabBehavior: RecentTabBehavior.RECENT,
            backgroundColor: cs.surface,
            indicatorColor: cs.primary,
            iconColorSelected: cs.primary,
            iconColor: cs.outline,
            dividerColor: cs.outlineVariant.withOpacity(0.3),
            tabBarHeight: 44,
          ),
          bottomActionBarConfig: BottomActionBarConfig(
            enabled: true,
            backgroundColor: cs.surface,
            buttonColor: cs.primary,
            buttonIconColor: cs.onPrimary,
            showBackspaceButton: onBackspacePressed != null,
          ),
          searchViewConfig: SearchViewConfig(
            buttonIconColor: cs.onSurfaceVariant,
            backgroundColor: cs.surfaceContainerHighest.withOpacity(0.4),
            hintText: '搜索表情...',
            inputTextStyle: TextStyle(color: cs.onSurface),
            hintTextStyle: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

/// 在底部内嵌的 emoji 面板；适合在 TextField 下方弹出。
class InlineEmojiPicker extends StatefulWidget {
  final void Function(String emoji) onEmojiSelected;
  final VoidCallback onClose;

  const InlineEmojiPicker({
    super.key,
    required this.onEmojiSelected,
    required this.onClose,
  });

  @override
  State<InlineEmojiPicker> createState() => _InlineEmojiPickerState();
}

class _InlineEmojiPickerState extends State<InlineEmojiPicker> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Text(
                '选择表情',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.keyboard_hide, size: 20),
                onPressed: widget.onClose,
                tooltip: '收起表情面板',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        EmojiPickerPanel(
          onEmojiSelected: widget.onEmojiSelected,
          onBackspacePressed: () => widget.onEmojiSelected(''),
        ),
      ],
    );
  }
}
