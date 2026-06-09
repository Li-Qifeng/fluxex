import 'package:flutter/material.dart';

class CollapsibleContent extends StatefulWidget {
  final Widget child;
  final int collapsedLines;

  const CollapsibleContent({
    super.key,
    required this.child,
    this.collapsedLines = 12,
  });

  @override
  State<CollapsibleContent> createState() => _CollapsibleContentState();
}

class _CollapsibleContentState extends State<CollapsibleContent> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: ConstrainedBox(
            constraints: _expanded
                ? const BoxConstraints()
                : BoxConstraints(maxHeight: widget.collapsedLines * 24),
            child: ClipRect(child: widget.child),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            foregroundColor: cs.primary,
          ),
          onPressed: () => setState(() => _expanded = !_expanded),
          icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18),
          label: Text(_expanded ? '收起内容' : '展开全文'),
        ),
      ],
    );
  }
}
