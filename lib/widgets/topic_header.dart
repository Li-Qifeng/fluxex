import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:go_router/go_router.dart';
import '../models/topic.dart';
import '../utils/html_styles.dart';
import '../utils/image_extractor.dart';
import '../utils/link_actions.dart';
import '../utils/time_util.dart';
import 'image_gallery.dart';

class TopicHeader extends StatelessWidget {
  final Topic topic;

  const TopicHeader({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      color: cs.surfaceContainerHighest.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 作者信息行
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/member/${topic.member.username}'),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(topic.member.avatarNormal),
                  ),
                ),
                const SizedBox(width: 12),
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
            const SizedBox(height: 14),
            // 标题
            Text(
              topic.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.3,
                color: cs.onSurface,
              ),
            ),
            // 正文内容
            if (topic.contentRendered != null && topic.contentRendered!.isNotEmpty) ...[
              const SizedBox(height: 14),
              HtmlWidget(
                topic.contentRendered!,
                textStyle: TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  color: cs.onSurfaceVariant,
                ),
                customStylesBuilder: codeBlockStylesBuilder,
                onTapUrl: (url) {
                  showUrlOptions(context, url);
                  return true;
                },
              ),
              ImageGallery(urls: extractImageUrls(topic.contentRendered!)),
            ] else if (topic.content != null && topic.content!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                topic.content!,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 14),
            // 底部信息行
            Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 16, color: cs.outline),
                const SizedBox(width: 4),
                Text(
                  '${topic.replies} 回复',
                  style: TextStyle(fontSize: 13, color: cs.outline),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: cs.outline),
                const SizedBox(width: 4),
                Text(
                  formatRelativeTime(topic.created),
                  style: TextStyle(fontSize: 13, color: cs.outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
