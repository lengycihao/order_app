import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 图片缓存配置工具类
class ImageCacheConfig {
  /// 默认缓存配置
  static const int defaultMemCacheWidth = 300;
  static const int defaultMemCacheHeight = 300;
  static const int defaultMaxWidthDiskCache = 600;
  static const int defaultMaxHeightDiskCache = 600;
  
  /// 菜单图片缓存配置
  static const int menuMemCacheWidth = 300;
  static const int menuMemCacheHeight = 300;
  static const int menuMaxWidthDiskCache = 600;
  static const int menuMaxHeightDiskCache = 600;
  
  /// 菜品图片缓存配置
  static const int dishMemCacheWidth = 200;
  static const int dishMemCacheHeight = 200;
  static const int dishMaxWidthDiskCache = 400;
  static const int dishMaxHeightDiskCache = 400;
  
  /// 头像图片缓存配置
  static const int avatarMemCacheWidth = 100;
  static const int avatarMemCacheHeight = 100;
  static const int avatarMaxWidthDiskCache = 200;
  static const int avatarMaxHeightDiskCache = 200;

  /// 获取菜单图片的默认占位符
  static Widget getMenuPlaceholder({
    double? width,
    double? height,
    String? loadingText,
  }) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.orange.shade300,
            ),
          ),
          if (loadingText != null) ...[
            const SizedBox(height: 8),
            Text(
              loadingText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 获取菜单图片的默认错误占位符
  static Widget getMenuErrorWidget({
    double? width,
    double? height,
    String? errorText,
    IconData? icon,
  }) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.restaurant_menu,
            size: 32,
            color: Colors.grey.shade400,
          ),
          if (errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              errorText,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 获取菜品图片的默认占位符
  static Widget getDishPlaceholder({
    double? width,
    double? height,
  }) {
    return Container(
      width: width ?? 100,
      height: height ?? 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/order_menu_placeholder.webp',
          width: width ?? 100,
          height: height ?? 100,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// 获取菜品图片的默认错误占位符
  static Widget getDishErrorWidget({
    double? width,
    double? height,
  }) {
    return Container(
      width: width ?? 100,
      height: height ?? 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/order_menu_placeholder.webp',
          width: width ?? 100,
          height: height ?? 100,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// 清理图片缓存
  static Future<void> clearCache() async {
    await CachedNetworkImage.evictFromCache('');
  }

  /// 清理特定URL的缓存
  static Future<void> clearCacheForUrl(String url) async {
    await CachedNetworkImage.evictFromCache(url);
  }
}

