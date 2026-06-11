import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/topic.dart';
import '../utils/db_helper.dart';
import '../widgets/cached_avatar.dart';

class TopicCard extends StatelessWidget {
  final Topic topic;

  const TopicCard({super.key, required this.topic});

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<bool>(
      future: DbHelper.isTopicRead(topic.id),
      builder: (context, snapshot) {
        final isRead = snapshot.data ?? false;
        final titleColor = isRead ? colorScheme.outline : colorScheme.onSurface;
        final metaColor = isRead ? colorScheme.outline.withValues(alpha: 0.7) : colorScheme.onSurfaceVariant;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/topic/${topic.id}'),
            onLongPress: () => _showTopicMenu(context, topic),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/node/${topic.node.name}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isRead
                                ? colorScheme.surfaceContainerHighest
                                : colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            topic.node.title,
                            style: TextStyle(
                              fontSize: 11,
                              color: isRead ? colorScheme.outline : colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Hero(
                        tag: 'member-avatar-${topic.member.username}',
                        child: CachedAvatar(
                          imageUrl: topic.member.avatarNormal,
                          radius: 10,
                          fallbackText: topic.member.username,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/member/${topic.member.username}'),
                          child: Text(
                            topic.member.username,
                            style: TextStyle(fontSize: 12, color: metaColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(topic.lastTouched),
                        style: TextStyle(fontSize: 11, color: metaColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    topic.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                      height: 1.4,
                      color: titleColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: metaColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${topic.replies} 回复',
                        style: TextStyle(fontSize: 12, color: metaColor),
                      ),
                      if (topic.lastReplyBy != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '最后回复: ${topic.lastReplyBy}',
                          style: TextStyle(fontSize: 12, color: metaColor),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

void _showTopicMenu(BuildContext context, Topic topic) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: FutureBuilder<bool>(
        future: DbHelper.isBookmarked(topic.id),
        builder: (context, snapshot) {
          final isBookmarked = snapshot.data ?? false;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('查看话题'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/topic/${topic.id}');
                },
              ),
              ListTile(
                leading: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                title: Text(isBookmarked ? '取消收藏' : '收藏话题'),
                onTap: () async {
                  Navigator.pop(context);
                  if (isBookmarked) {
                    await DbHelper.removeBookmark(topic.id);
                  } else {
                    await DbHelper.addBookmark(topic.id, topic.title);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('分享'),
                onTap: () {
                  Navigator.pop(context);
                  Share.share('${topic.title} https://www.v2ex.com/t/${topic.id}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('复制链接'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(
                    text: 'https://www.v2ex.com/t/${topic.id}',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('链接已复制')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text('查看用户: ${topic.member.username}'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/member/${topic.member.username}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text('查看节点: ${topic.node.title}'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/node/${topic.node.name}');
                },
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    ),
  );
}
