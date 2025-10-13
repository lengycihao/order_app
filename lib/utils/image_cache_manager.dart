import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lib_base/logging/logging.dart';
import 'package:order_app/pages/order/model/dish.dart';

/// 图片缓存管理器
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  /// 预加载图片列表
  final List<String> _preloadUrls = [];
  
  /// 最大预加载数量
  static const int maxPreloadCount = 20;
  
  /// 预加载队列
  final List<String> _preloadQueue = [];
  
  /// 是否正在预加载
  bool _isPreloading = false;

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
          logDebug('预加载图片成功: $url', tag: 'ImageCacheManager');
        } catch (e) {
          // logError('预加载图片失败: $url, 错误: $e', tag: 'ImageCacheManager');
        }
      }
    }
  }

  /// 预加载菜品图片
  Future<void> preloadDishImages(List<Dish> dishes) async {
    if (dishes.isEmpty) return;
    
    // 提取图片URL
    final imageUrls = dishes
        .where((dish) => dish.image.isNotEmpty)
        .map((dish) => dish.image)
        .toList();
    
    // 提取敏感物图标URL
    final allergenUrls = dishes
        .where((dish) => dish.allergens != null && dish.allergens!.isNotEmpty)
        .expand((dish) => dish.allergens!)
        .where((allergen) => allergen.icon != null && allergen.icon!.isNotEmpty)
        .map((allergen) => allergen.icon!)
        .toList();
    
    // 合并所有URL
    final allUrls = [...imageUrls, ...allergenUrls];
    
    await preloadImages(allUrls);
  }

  /// 异步预加载图片（不阻塞UI）
  void preloadImagesAsync(List<String> urls) {
    if (_isPreloading) {
      // 如果正在预加载，将URL添加到队列
      _preloadQueue.addAll(urls);
      return;
    }
    
    _isPreloading = true;
    preloadImages(urls).then((_) {
      _isPreloading = false;
      
      // 处理队列中的URL
      if (_preloadQueue.isNotEmpty) {
        final queuedUrls = List<String>.from(_preloadQueue);
        _preloadQueue.clear();
        preloadImagesAsync(queuedUrls);
      }
    });
  }

  /// 预加载可见区域附近的图片
  void preloadNearbyImages(List<Dish> allDishes, int currentIndex, int range) {
    final startIndex = (currentIndex - range).clamp(0, allDishes.length - 1);
    final endIndex = (currentIndex + range).clamp(0, allDishes.length - 1);
    
    final nearbyDishes = allDishes.sublist(startIndex, endIndex + 1);
    preloadImagesAsync(nearbyDishes.map((dish) => dish.image).where((url) => url.isNotEmpty).toList());
  }

  /// 清理所有缓存
  Future<void> clearAllCache() async {
    try {
      await CachedNetworkImage.evictFromCache('');
      _preloadUrls.clear();
      logDebug('清理所有图片缓存成功', tag: 'ImageCacheManager');
    } catch (e) {
      logError('清理图片缓存失败: $e', tag: 'ImageCacheManager');
    }
  }

  /// 清理特定URL的缓存
  Future<void> clearCacheForUrl(String url) async {
    if (url.isEmpty) return;
    
    try {
      await CachedNetworkImage.evictFromCache(url);
      _preloadUrls.remove(url);
      logDebug('清理图片缓存成功: $url', tag: 'ImageCacheManager');
    } catch (e) {
      logError('清理图片缓存失败: $url, 错误: $e', tag: 'ImageCacheManager');
    }
  }

  /// 清理过期的缓存
  Future<void> clearExpiredCache() async {
    try {
      // 这里可以根据需要实现更复杂的缓存清理逻辑
      // 比如根据时间、大小等条件清理
      logDebug('清理过期缓存...', tag: 'ImageCacheManager');
      // 暂时使用简单的清理方式
      await CachedNetworkImage.evictFromCache('');
      _preloadUrls.clear();
      logDebug('清理过期缓存完成', tag: 'ImageCacheManager');
    } catch (e) {
      logError('清理过期缓存失败: $e', tag: 'ImageCacheManager');
    }
  }

  /// 获取缓存大小（估算）
  Future<int> getCacheSize() async {
    try {
      // 这里可以根据需要实现获取缓存大小的逻辑
      // 暂时返回预加载的图片数量作为参考
      return _preloadUrls.length;
    } catch (e) {
      logError('获取缓存大小失败: $e', tag: 'ImageCacheManager');
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
