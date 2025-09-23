import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'image_cache_config.dart';
import 'image_cache_manager.dart';

/// 图片缓存使用示例
class ImageCacheUsageExample {
  
  /// 示例1: 基础菜单图片加载
  static Widget buildMenuImageExample(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => ImageCacheConfig.getMenuPlaceholder(
          loadingText: '加载中...',
        ),
        errorWidget: (context, url, error) => ImageCacheConfig.getMenuErrorWidget(
          errorText: '图片加载失败',
        ),
        // 使用配置类的缓存设置
        memCacheWidth: ImageCacheConfig.menuMemCacheWidth,
        memCacheHeight: ImageCacheConfig.menuMemCacheHeight,
        maxWidthDiskCache: ImageCacheConfig.menuMaxWidthDiskCache,
        maxHeightDiskCache: ImageCacheConfig.menuMaxHeightDiskCache,
      ),
    );
  }

  /// 示例2: 菜品图片加载
  static Widget buildDishImageExample(String imageUrl) {
    return Container(
      width: 100,
      height: 100,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        imageBuilder: (context, imageProvider) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image(
            image: imageProvider,
            fit: BoxFit.cover,
            width: 100,
            height: 100,
          ),
        ),
        placeholder: (context, url) => ImageCacheConfig.getDishPlaceholder(),
        errorWidget: (context, url, error) => ImageCacheConfig.getDishErrorWidget(),
        // 使用菜品图片的缓存设置
        memCacheWidth: ImageCacheConfig.dishMemCacheWidth,
        memCacheHeight: ImageCacheConfig.dishMemCacheHeight,
        maxWidthDiskCache: ImageCacheConfig.dishMaxWidthDiskCache,
        maxHeightDiskCache: ImageCacheConfig.dishMaxHeightDiskCache,
      ),
    );
  }

  /// 示例3: 头像图片加载
  static Widget buildAvatarImageExample(String imageUrl) {
    return Container(
      width: 50,
      height: 50,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        imageBuilder: (context, imageProvider) => ClipOval(
          child: Image(
            image: imageProvider,
            fit: BoxFit.cover,
            width: 50,
            height: 50,
          ),
        ),
        placeholder: (context, url) => Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            color: Colors.grey.shade400,
            size: 24,
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_outline,
            color: Colors.grey.shade400,
            size: 24,
          ),
        ),
        // 使用头像图片的缓存设置
        memCacheWidth: ImageCacheConfig.avatarMemCacheWidth,
        memCacheHeight: ImageCacheConfig.avatarMemCacheHeight,
        maxWidthDiskCache: ImageCacheConfig.avatarMaxWidthDiskCache,
        maxHeightDiskCache: ImageCacheConfig.avatarMaxHeightDiskCache,
      ),
    );
  }

  /// 示例4: 预加载图片
  static Future<void> preloadImagesExample(List<String> imageUrls) async {
    try {
      await ImageCacheManager().preloadImages(imageUrls);
      print('✅ 图片预加载完成');
    } catch (e) {
      print('❌ 图片预加载失败: $e');
    }
  }

  /// 示例5: 清理缓存
  static Future<void> clearCacheExample() async {
    try {
      await ImageCacheManager().clearAllCache();
      print('✅ 缓存清理完成');
    } catch (e) {
      print('❌ 缓存清理失败: $e');
    }
  }

  /// 示例6: 清理特定URL的缓存
  static Future<void> clearSpecificCacheExample(String url) async {
    try {
      await ImageCacheManager().clearCacheForUrl(url);
      print('✅ 特定URL缓存清理完成: $url');
    } catch (e) {
      print('❌ 特定URL缓存清理失败: $e');
    }
  }

  /// 示例7: 检查图片是否已缓存
  static bool checkImageCachedExample(String url) {
    return ImageCacheManager().isImageCached(url);
  }

  /// 示例8: 获取缓存大小
  static Future<int> getCacheSizeExample() async {
    return await ImageCacheManager().getCacheSize();
  }
}

/// 使用说明:
/// 
/// 1. 基础使用:
///    - 使用 CachedNetworkImage 替代 Image.network
///    - 配置 placeholder 和 errorWidget
///    - 设置合适的缓存参数
/// 
/// 2. 性能优化:
///    - 使用 memCacheWidth/Height 控制内存缓存大小
///    - 使用 maxWidthDiskCache/maxHeightDiskCache 控制磁盘缓存大小
///    - 预加载常用图片
/// 
/// 3. 缓存管理:
///    - 定期清理过期缓存
///    - 在应用启动时预加载关键图片
///    - 在内存不足时清理缓存
/// 
/// 4. 错误处理:
///    - 提供友好的加载占位符
///    - 提供清晰的错误提示
///    - 处理网络异常情况
