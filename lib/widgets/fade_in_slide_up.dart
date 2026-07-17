import 'package:flutter/material.dart';
import '../utils/app_easings.dart';

/// 子元素挂载时渐进式入场动画：从下往上 + 淡入
class FadeInSlideUp extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offsetY;

  const FadeInSlideUp({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 250),
    this.offsetY = 12.0,
  });

  @override
  State<FadeInSlideUp> createState() => _FadeInSlideUpState();
}

class _FadeInSlideUpState extends State<FadeInSlideUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: AppEasings.easeOutStrong),
    );
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offsetY / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: AppEasings.easeOutStrong));

    // 使用 microtask 确保 widget 已挂载后再触发
    Future.microtask(() {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _slide.value.dy * widget.offsetY),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}