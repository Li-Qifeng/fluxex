import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:go_router/go_router.dart';
import '../models/topic.dart';
import '../utils/code_highlight.dart';
import '../utils/html_styles.dart';
import '../utils/image_extractor.dart';
import '../utils/link_actions.dart';
import '../utils/time_util.dart';
import '../widgets/cached_avatar.dart';
import '../widgets/collapsible_content.dart';
import 'image_gallery.dart';

class TopicHeader extends StatelessWidget {
  final Topic topic;

  const TopicHeader({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            topic.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 16),
          // 作者信息行 + 节点
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/member/${topic.member.username}'),
                child: CachedAvatar(
                  imageUrl: topic.member.avatarNormal,
                  radius: 16,
                  fallbackText: topic.member.username,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/member/${topic.member.username}'),
                  child: Text(
                    topic.member.username,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  topic.node.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: cs.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          // 正文内容
          if (topic.contentRendered != null && topic.contentRendered!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _maybeCollapse(
              topic.contentRendered!,
              HtmlWidget(
                topic.contentRendered!,
                textStyle: TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurface,
                ),
                customStylesBuilder: codeBlockStylesBuilder,
                customWidgetBuilder: codeBlockWidgetBuilder,
                onTapUrl: (url) {
                  handleTapUrl(context, url);
                  return true;
                },
              ),
            ),
            ImageGallery(urls: extractImageUrls(topic.contentRendered!)),
          ] else if (topic.content != null && topic.content!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              topic.content!,
              style: TextStyle(
                fontSize: 15,
                height: 1.7,
                fontWeight: FontWeight.w400,
                color: cs.onSurface,
              ),
            ),
          ],
          const SizedBox(height: 14),
          // 底部信息行（参照 Fluxdo metadata row 风格）
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _buildMetadataItem(
                context,
                Icons.chat_bubble_outline_rounded,
                '${topic.replies}',
                label: '回复',
              ),
              _buildMetadataItem(
                context,
                Icons.schedule_rounded,
                formatRelativeTime(topic.created),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(BuildContext context, IconData icon, String text, {String? label}) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurfaceVariant.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }

  Widget _maybeCollapse(String content, Widget child) {
    if (content.length < 1200) return child;
    return CollapsibleContent(child: child);
  }
}
