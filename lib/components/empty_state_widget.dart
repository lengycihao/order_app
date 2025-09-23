import 'package:flutter/material.dart';

/// 空状态图工具类
/// 提供多种空状态展示方式，包括纯文字、文字+图片、网络错误等
class EmptyStateWidget {
  /// 纯文字空状态
  static Widget textOnly({
    required String message,
    String? subtitle,
    Color? textColor,
    double? fontSize,
    EdgeInsets? padding,
  }) {
    return Center(
      child: Container(
        padding: padding ?? EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: fontSize ?? 16,
                color: textColor ?? Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 文字 + 图片空状态
  static Widget withImage({
    required String message,
    String? subtitle,
    required String imagePath,
    double? imageWidth,
    double? imageHeight,
    Color? textColor,
    double? fontSize,
    EdgeInsets? padding,
    VoidCallback? onTap,
  }) {
    return Center(
      child: Container(
        padding: padding ?? EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onTap,
              child: Image.asset(
                imagePath,
                width: imageWidth ?? 120,
                height: imageHeight ?? 120,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: fontSize ?? 16,
                color: textColor ?? Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 网络错误空状态
  static Widget networkError({
    required String message,
    String? subtitle,
    required VoidCallback onRetry,
    String? retryButtonText,
    Color? textColor,
    double? fontSize,
    EdgeInsets? padding,
  }) {
    return Center(
      child: Container(
        padding: padding ?? EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 80,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: fontSize ?? 16,
                color: textColor ?? Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh, size: 18),
              label: Text(retryButtonText ?? '重新加载'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 加载失败空状态
  static Widget loadFailed({
    required String message,
    String? subtitle,
    required VoidCallback onRetry,
    String? retryButtonText,
    Color? textColor,
    double? fontSize,
    EdgeInsets? padding,
  }) {
    return Center(
      child: Container(
        padding: padding ?? EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: Colors.red.shade300,
            ),
            SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: fontSize ?? 16,
                color: textColor ?? Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh, size: 18),
              label: Text(retryButtonText ?? '重新加载'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 自定义空状态
  static Widget custom({
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Container(
      padding: padding ?? EdgeInsets.all(32),
      child: Center(child: child),
    );
  }

  /// 桌台列表空状态
  static Widget tableListEmpty({
    VoidCallback? onRefresh,
  }) {
    return withImage(
      message: '暂无桌台数据',
      subtitle: '请稍后再试或联系管理员',
      imagePath: 'assets/empty_table.png', // 需要添加对应的图片资源
      onTap: onRefresh,
    );
  }

  /// 外卖列表空状态
  static Widget takeawayListEmpty({
    VoidCallback? onRefresh,
  }) {
    return withImage(
      message: '暂无外卖订单',
      subtitle: '还没有外卖订单，快去下单吧',
      imagePath: 'assets/empty_takeaway.png', // 需要添加对应的图片资源
      onTap: onRefresh,
    );
  }

  /// 网络错误状态（通用）
  static Widget networkErrorGeneric({
    required VoidCallback onRetry,
  }) {
    return networkError(
      message: '网络连接失败',
      subtitle: '请检查网络连接后重试',
      onRetry: onRetry,
    );
  }

  /// 加载失败状态（通用）
  static Widget loadFailedGeneric({
    required VoidCallback onRetry,
  }) {
    return loadFailed(
      message: '数据加载失败',
      subtitle: '请稍后重试',
      onRetry: onRetry,
    );
  }
}
