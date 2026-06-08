import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:go_router/go_router.dart';
import '../models/reply.dart';
import '../utils/html_styles.dart';
import '../utils/link_actions.dart';
import '../utils/time_util.dart';

class ReplyItem extends StatelessWidget {
  final Reply reply;
  final int floor;

  const ReplyItem({super.key, required this.reply, required this.floor});

  /// 提取被引用的用户名前缀，如 "@username "
  String? _extractMention(String? rendered) {
    if (rendered == null) return null;
    // v2ex 的引用通常是 <a href="/member/xxx">@xxx</a> 开头
    final exp = RegExp(r'<a[^>]*member[^>]*>@([^<]+)</a>');
    final match = exp.firstMatch(rendered);
    if (match != null) {
      return '@${match.group(1)}';
    }
    return null;
  }

  /// 移除引用标记后展示正文（如果有引用的话）
  String? _stripLeadingMention(String? rendered) {
    if (rendered == null) return null;
    final exp = RegExp(r'^\s*<a[^>]*member[^>]*>@[^<]+</a>\s*');
    return rendered.replaceFirst(exp, '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final mention = _extractMention(reply.contentRendered ?? reply.content);
    final bodyRendered = _stripLeadingMention(reply.contentRendered) ?? reply.contentRendered;
    final bodyContent = _stripLeadingMention(reply.content) ?? reply.content;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: cs.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/member/${reply.member.username}'),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(reply.member.avatarNormal),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/member/${reply.member.username}'),
                        child: Text(
                          reply.member.username,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        formatRelativeTime(reply.created),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$floor',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (mention != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mention,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
            if (bodyRendered != null && bodyRendered.isNotEmpty)
              HtmlWidget(
                bodyRendered,
                textStyle: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: cs.onSurfaceVariant,
                ),
                customStylesBuilder: codeBlockStylesBuilder,
                onTapUrl: (url) {
                  showUrlOptions(context, url);
                  return true;
                },
              )
            else if (bodyContent != null)
              Text(
                bodyContent,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: cs.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
