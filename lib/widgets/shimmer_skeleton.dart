import 'package:flutter/material.dart';

/// 通用骨架屏 shimmer 动画
class ShimmerSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsets margin;

  const ShimmerSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
    this.margin = EdgeInsets.zero,
  });

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseColor = cs.surfaceContainerHighest;
    final highlightColor = baseColor.withOpacity(0.6);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + _controller.value * 2.0, 0),
              end: Alignment(0.0 + _controller.value * 2.0, 0),
            ).createShader(bounds);
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            margin: widget.margin,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

/// 帖子骨架屏：Header + 若干回复占位
class TopicDetailSkeleton extends StatelessWidget {
  const TopicDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Header 占位
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const ShimmerSkeleton(width: 40, height: 40, borderRadius: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerSkeleton(width: 100, height: 14, borderRadius: 4),
                          const SizedBox(height: 6),
                          ShimmerSkeleton(width: 80, height: 11, borderRadius: 3),
                        ],
                      ),
                    ),
                    const ShimmerSkeleton(width: 60, height: 22, borderRadius: 12),
                  ],
                ),
                const SizedBox(height: 14),
                ShimmerSkeleton(width: double.infinity, height: 22, borderRadius: 4),
                const SizedBox(height: 8),
                ShimmerSkeleton(width: double.infinity, height: 18, borderRadius: 4),
                const SizedBox(height: 8),
                ShimmerSkeleton(width: 200, height: 18, borderRadius: 4),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const ShimmerSkeleton(width: 80, height: 13, borderRadius: 3),
                    const SizedBox(width: 16),
                    ShimmerSkeleton(width: 80, height: 13, borderRadius: 3),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 回复占位
          for (int i = 0; i < 6; i++) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const ShimmerSkeleton(width: 32, height: 32, borderRadius: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerSkeleton(width: 80, height: 13, borderRadius: 3),
                            const SizedBox(height: 4),
                            ShimmerSkeleton(width: 60, height: 11, borderRadius: 3),
                          ],
                        ),
                      ),
                      const ShimmerSkeleton(width: 36, height: 18, borderRadius: 8),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ShimmerSkeleton(width: double.infinity, height: 14, borderRadius: 3),
                  const SizedBox(height: 6),
                  ShimmerSkeleton(width: double.infinity, height: 14, borderRadius: 3),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
