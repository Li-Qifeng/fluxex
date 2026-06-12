import 'dart:async';
import 'package:flutter/material.dart';

/// 通过 [ScrollNotification] 监听滚动到达底部。
/// 不创建 [ScrollController]，避免干扰 [PrimaryScrollController]。
class ScrollBottomDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onBottomReached;
  final double threshold;
  final Duration debounce;

  const ScrollBottomDetector({
    super.key,
    required this.child,
    this.onBottomReached,
    this.threshold = 200,
    this.debounce = const Duration(seconds: 2),
  });

  @override
  State<ScrollBottomDetector> createState() => _ScrollBottomDetectorState();
}

class _ScrollBottomDetectorState extends State<ScrollBottomDetector> {
  bool _triggered = false;
  Timer? _timer;

  void _onReached() {
    if (_triggered) return;
    if (widget.onBottomReached == null) return;
    _triggered = true;
    widget.onBottomReached!();
    _timer?.cancel();
    _timer = Timer(widget.debounce, () {
      if (mounted) setState(() => _triggered = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        // 只有当内容实际可滚动时才触发
        if (metrics.maxScrollExtent <= 0) return false;
        if (metrics.pixels >= metrics.maxScrollExtent - widget.threshold) {
          _onReached();
        }
        return false;
      },
      child: widget.child,
    );
  }
}
