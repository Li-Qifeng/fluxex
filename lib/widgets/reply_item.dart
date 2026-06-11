import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../models/reply.dart';
import '../utils/code_highlight.dart';
import '../utils/html_styles.dart';
import '../utils/link_actions.dart';
import '../utils/time_util.dart';
import '../widgets/cached_avatar.dart';
import '../widgets/collapsible_content.dart';

class ReplyItem extends StatelessWidget {
  final Reply reply;
  final int floor;
  final VoidCallback? onQuote;

  const ReplyItem({super.key, required this.reply, required this.floor, this.onQuote});

  /// 提取被引用的用户名前缀，如 "@username "
  String? _extractMention(String? rendered) {
    if (rendered == null) return null;
    final exp = RegExp(r'<a[^>]*member[^>]*>@([^<]+)</a>');
    final match = exp.firstMatch(rendered);
    if (match != null) {
      return '@${match.group(1)}';
    }
    return null;
  }

  /// 移除引用标记后展示正文
  String? _stripLeadingMention(String? rendered) {
    if (rendered == null) return null;
    final exp = RegExp(r'^\s*<a[^>]*member[^>]*>@[^<]+</a>\s*');
    return rendered.replaceFirst(exp, '');
  }

  /// 提取纯文本摘要用于分享
  String _getPlainTextSummary(String? content, String? contentRendered) {
    String text = content ?? '';
    if (text.isEmpty && contentRendered != null) {
      text = contentRendered.replaceAll(RegExp(r'<[^>]*>'), ' ');
      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    if (text.length > 120) {
      text = '${text.substring(0, 120)}...';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final mention = _extractMention(reply.contentRendered ?? reply.content);
    final bodyRendered = _stripLeadingMention(reply.contentRendered) ?? reply.contentRendered;
    final bodyContent = _stripLeadingMention(reply.content) ?? reply.content;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
          // 头部：用户名 + 时间 + 楼层
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/member/${reply.member.username}'),
                child: CachedAvatar(
                  imageUrl: reply.member.avatarNormal,
                  radius: 16,
                  fallbackText: reply.member.username,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      formatRelativeTime(reply.created),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '#$floor',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          // 引用标记
          if (mention != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
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
            ),
          const SizedBox(height: 10),
          // 正文
          if (bodyRendered != null && bodyRendered.isNotEmpty)
            _maybeCollapse(
              bodyRendered,
              HtmlWidget(
                bodyRendered,
                textStyle: TextStyle(
                  fontSize: 15,
                  height: 1.6,
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
            )
          else if (bodyContent != null)
            Text(
              bodyContent,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                fontWeight: FontWeight.w400,
                color: cs.onSurface,
              ),
            ),
          // 操作栏
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onQuote != null)
                IconButton(
                  icon: Icon(Icons.format_quote_outlined, size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                  tooltip: '引用',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: onQuote,
                ),
              IconButton(
                icon: Icon(Icons.share_outlined, size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                tooltip: '分享回复',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () {
                  final summary = _getPlainTextSummary(reply.content, reply.contentRendered);
                  final text = '@${reply.member.username}: $summary\nhttps://www.v2ex.com/t/${reply.topicId}';
                  Share.share(text);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _maybeCollapse(String content, Widget child) {
    if (content.length < 900) return child;
    return CollapsibleContent(collapsedLines: 8, child: child);
  }
}
