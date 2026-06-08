import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// 自定义图片缓存管理器
/// - 最多缓存 200 个文件
/// - 单个文件最大 10MB
/// - 缓存有效期 7 天
class AppImageCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'app_image_cache';
  static final AppImageCacheManager _instance = AppImageCacheManager._();

  factory AppImageCacheManager() => _instance;

  AppImageCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 200,
          ),
        );
}
