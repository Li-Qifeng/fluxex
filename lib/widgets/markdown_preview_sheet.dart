import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownPreviewSheet extends StatelessWidget {
  final String title;
  final String content;

  const MarkdownPreviewSheet({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '预览',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (title.isNotEmpty) const SizedBox(height: 16),
                    MarkdownBody(
                      data: content.isEmpty ? '（无内容）' : content,
                      selectable: true,
                      onTapLink: (text, href, title) async {
                        if (href == null) return;
                        final uri = Uri.parse(href);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(fontSize: 15, height: 1.7, color: cs.onSurfaceVariant),
                        h1: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.onSurface),
                        h2: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
                        h3: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface),
                        code: TextStyle(
                          fontFamily: 'monospace',
                          backgroundColor: cs.surfaceContainerHighest,
                          color: cs.primary,
                          fontSize: 13,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        blockquote: TextStyle(
                          fontSize: 15,
                          color: cs.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(left: BorderSide(color: cs.primary, width: 4)),
                          color: cs.primaryContainer.withOpacity(0.2),
                        ),
                        blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        a: TextStyle(color: cs.primary, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
