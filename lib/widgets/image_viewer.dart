import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/image_utils.dart';

/// Shows a full-screen image gallery viewer with gesture support:
/// - Tap: toggle controls
/// - Double tap: zoom in/out
/// - Vertical drag (when not zoomed): dismiss with opacity fade
/// - Horizontal swipe: navigate between images
/// - Long press: options menu (save/share/copy)
void showImageViewer(BuildContext context, List<String> urls, {int initialIndex = 0}) {
  if (urls.isEmpty) return;
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, animation, __) => _ImageViewerPage(urls: urls, initialIndex: initialIndex),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

/// Convenience: show a single image.
void showSingleImageViewer(BuildContext context, String url) {
  showImageViewer(context, [url], initialIndex: 0);
}

class _ImageViewerPage extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _ImageViewerPage({required this.urls, this.initialIndex = 0});

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;

  // Drag-to-dismiss state
  double _dragOffset = 0;

  // Zoom tracking
  final _transformationControllers = <int, TransformationController>{};
  final _zoomedStates = <int, bool>{};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _transformationControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TransformationController _getController(int index) {
    return _transformationControllers.putIfAbsent(index, () {
      final ctrl = TransformationController();
      ctrl.addListener(() {
        final scale = ctrl.value.getMaxScaleOnAxis();
        final isZoomed = scale > 1.01;
        if ((_zoomedStates[index] ?? false) != isZoomed) {
          setState(() => _zoomedStates[index] = isZoomed);
        }
      });
      return ctrl;
    });
  }

  bool get _isZoomed => _zoomedStates[_currentIndex] ?? false;

  double get _backgroundOpacity {
    if (_dragOffset == 0) return 1.0;
    return (1.0 - _dragOffset.abs() / 250.0).clamp(0.0, 1.0);
  }

  void _commitDrag([double? velocity]) {
    const threshold = 120.0;
    const velThreshold = 400.0;
    if (_dragOffset.abs() > threshold || (velocity?.abs() ?? 0) > velThreshold) {
      Navigator.of(context).pop();
    } else {
      _animateReset();
    }
  }

  void _animateReset() {
    final start = _dragOffset;
    const duration = Duration(milliseconds: 200);
    final controller = AnimationController(vsync: this, duration: duration);
    final anim = Tween<double>(begin: start, end: 0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );
    anim.addListener(() => setState(() => _dragOffset = anim.value));
    anim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      }
    });
    controller.forward();
  }

  Future<void> _saveImage(String url) async {
    final loading = ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('正在保存图片...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );
    final ok = await saveImageToGallery(url);
    loading.close();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '图片已保存到相册' : '保存失败，请检查相册权限')),
    );
  }

  void _showOptions(String url) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '图片操作',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.save_alt, color: Colors.white),
              title: const Text('保存图片', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _saveImage(url);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('分享图片', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                shareImageFile(url);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.white),
              title: const Text('复制链接', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('链接已复制')),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  Widget _buildImage(String url, int index) {
    return Hero(
      tag: 'img_$url',
      child: InteractiveViewer(
        transformationController: _getController(index),
        panEnabled: true,
        boundaryMargin: const EdgeInsets.all(20),
        minScale: 0.8,
        maxScale: 4.0,
        child: Image.network(
          url,
          fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.white.withValues(alpha: 0.8),
                strokeWidth: 3,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image, color: Colors.white70, size: 64),
            SizedBox(height: 12),
            Text('图片加载失败', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    ),
  );
}

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: _backgroundOpacity),
      body: Stack(
        children: [
          // Image PageView with drag-to-dismiss
          GestureDetector(
            onTap: _toggleControls,
            onLongPress: () => _showOptions(widget.urls[_currentIndex]),
            onVerticalDragStart: (_) {
              if (_isZoomed) return;
            },
            onVerticalDragUpdate: (details) {
              if (_isZoomed) return;
              setState(() => _dragOffset += details.delta.dy);
            },
            onVerticalDragEnd: (details) {
              if (_isZoomed) return;
              _commitDrag(details.primaryVelocity);
            },
            onVerticalDragCancel: () {
              if (_isZoomed) return;
              _commitDrag();
            },
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.urls.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  // Reset drag when page changes
                  if (_dragOffset != 0) {
                    _dragOffset = 0;
                  }
                },
                itemBuilder: (context, index) {
                  return _buildImage(widget.urls[index], index);
                },
              ),
            ),
          ),

          // Top controls bar
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  right: 8,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    if (widget.urls.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.urls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
