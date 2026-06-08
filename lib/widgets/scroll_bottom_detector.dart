import 'package:flutter/material.dart';

class ScrollBottomDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onBottomReached;
  final double threshold;

  const ScrollBottomDetector({
    super.key,
    required this.child,
    this.onBottomReached,
    this.threshold = 200,
  });

  @override
  State<ScrollBottomDetector> createState() => _ScrollBottomDetectorState();
}

class _ScrollBottomDetectorState extends State<ScrollBottomDetector> {
  final ScrollController _controller = ScrollController();
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (_controller.position.pixels >=
        _controller.position.maxScrollExtent - widget.threshold) {
      if (!_triggered && widget.onBottomReached != null) {
        _triggered = true;
        widget.onBottomReached!();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _triggered = false);
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: _controller,
      child: widget.child,
    );
  }
}
