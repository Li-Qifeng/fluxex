import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/image_cache_manager.dart';

class CachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? fallbackText;

  const CachedAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = imageUrl;

    if (url == null || url.isEmpty) {
      return _fallbackAvatar(cs);
    }

    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: AppImageCacheManager(),
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
        backgroundColor: Colors.transparent,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: cs.surfaceContainerHighest,
        child: SizedBox(
          width: radius * 0.8,
          height: radius * 0.8,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: cs.primary,
          ),
        ),
      ),
      errorWidget: (context, url, error) => _fallbackAvatar(cs),
    );
  }

  Widget _fallbackAvatar(ColorScheme cs) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: cs.primaryContainer,
      child: Text(
        (fallbackText ?? '?')[0].toUpperCase(),
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w600,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }
}
