import 'package:flutter/material.dart';

/// 桌面端内容宽度约束器
/// 当屏幕宽度大于 840 时，限制内容最大宽度为 760px 并居中
class ConstrainedContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth = 760,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 840) return child;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}
