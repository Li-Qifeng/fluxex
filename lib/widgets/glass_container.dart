import 'dart:ui';
import 'package:flutter/material.dart';

/// 液态玻璃效果容器
/// iOS/macOS 上使用强模糊模拟 Liquid Glass，其他平台降级为半透明
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius borderRadius;
  final Border? border;
  final Color? tintColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 25.0,
    this.opacity = 0.15,
    this.borderRadius = const BorderRadius.all(Radius.circular(0)),
    this.border,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: (tintColor ?? cs.surface).withOpacity(isDark ? opacity + 0.1 : opacity),
            borderRadius: borderRadius,
            border: border ?? Border.all(
              color: (isDark ? Colors.white : Colors.white).withOpacity(isDark ? 0.08 : 0.2),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 液态玻璃 AppBar 的 flexibleSpace
class GlassAppBarBackground extends StatelessWidget {
  const GlassAppBarBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          color: (isDark ? Colors.black : Colors.white).withOpacity(isDark ? 0.4 : 0.6),
        ),
      ),
    );
  }
}

/// 液态玻璃底部导航栏背景
class GlassNavBarBackground extends StatelessWidget {
  const GlassNavBarBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withOpacity(isDark ? 0.5 : 0.7),
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.white : Colors.grey).withOpacity(isDark ? 0.06 : 0.15),
                width: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
