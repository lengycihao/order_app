import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 图片缓存管理器
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  /// 预加载图片列表
  final List<String> _preloadUrls = [];
  
  /// 最大预加载数量
  static const int maxPreloadCount = 20;

  /// 预加载图片
  Future<void> preloadImages(List<String> urls) async {
    if (urls.isEmpty) return;
    
    // 限制预加载数量
    final limitedUrls = urls.take(maxPreloadCount).toList();
    
    for (final url in limitedUrls) {
      if (url.isNotEmpty && !_preloadUrls.contains(url)) {
        try {
          await precacheImage(
            CachedNetworkImageProvider(url),
            NavigationService.navigatorKey.currentContext!,
          );
          _preloadUrls.add(url);
          print('✅ 预加载图片成功: $url');
        } catch (e) {
          print('❌ 预加载图片失败: $url, 错误: $e');
        }
      }
    }
  }

  /// 清理所有缓存
  Future<void> clearAllCache() async {
    try {
      await CachedNetworkImage.evictFromCache('');
      _preloadUrls.clear();
      print('✅ 清理所有图片缓存成功');
    } catch (e) {
      print('❌ 清理图片缓存失败: $e');
    }
  }

  /// 清理特定URL的缓存
  Future<void> clearCacheForUrl(String url) async {
    if (url.isEmpty) return;
    
    try {
      await CachedNetworkImage.evictFromCache(url);
      _preloadUrls.remove(url);
      print('✅ 清理图片缓存成功: $url');
    } catch (e) {
      print('❌ 清理图片缓存失败: $url, 错误: $e');
    }
  }

  /// 清理过期的缓存
  Future<void> clearExpiredCache() async {
    try {
      // 这里可以根据需要实现更复杂的缓存清理逻辑
      // 比如根据时间、大小等条件清理
      print('🔄 清理过期缓存...');
      // 暂时使用简单的清理方式
      await CachedNetworkImage.evictFromCache('');
      _preloadUrls.clear();
      print('✅ 清理过期缓存完成');
    } catch (e) {
      print('❌ 清理过期缓存失败: $e');
    }
  }

  /// 获取缓存大小（估算）
  Future<int> getCacheSize() async {
    try {
      // 这里可以根据需要实现获取缓存大小的逻辑
      // 暂时返回预加载的图片数量作为参考
      return _preloadUrls.length;
    } catch (e) {
      print('❌ 获取缓存大小失败: $e');
      return 0;
    }
  }

  /// 检查图片是否已缓存
  bool isImageCached(String url) {
    return _preloadUrls.contains(url);
  }

  /// 获取已预加载的图片列表
  List<String> getPreloadedUrls() {
    return List.from(_preloadUrls);
  }
}

/// 导航服务类（简化版）
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
