import 'dart:ui';
import 'package:flutter/material.dart';

/// 顶部渐变模糊背景：上部强模糊+表面色调，向下渐变至几近消失
/// 用于 extendBodyBehindAppBar=true 的 AppBar flexibleSpace
class GradientAppBarBlur extends StatelessWidget {
  final double maxBlur;
  final double tintAlpha;

  const GradientAppBarBlur({
    super.key,
    this.maxBlur = 32,
    this.tintAlpha = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: maxBlur, sigmaY: maxBlur),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                cs.surface.withValues(alpha: tintAlpha),
                cs.surface.withValues(alpha: tintAlpha * 0.45),
                cs.surface.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            border: Border(
              bottom: BorderSide(
                color: cs.outline.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
