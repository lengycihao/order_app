import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? subtitle;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final Widget? icon;
  final Widget? image;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.subtitle,
    this.onRetry,
    this.retryButtonText,
    this.icon,
    this.image,
  });

  /// 网络错误状态
  factory EmptyStateWidget.networkError({
    required String message,
    String? subtitle,
    VoidCallback? onRetry,
    String? retryButtonText,
  }) {
    return EmptyStateWidget(
      message: message,
      subtitle: subtitle,
      onRetry: onRetry,
      retryButtonText: retryButtonText ?? '重试',
      icon: const Icon(
        Icons.wifi_off,
        size: 64,
        color: Colors.grey,
      ),
    );
  }

  /// 带图片的空状态
  factory EmptyStateWidget.withImage({
    required String message,
    String? subtitle,
    VoidCallback? onRetry,
    String? retryButtonText,
    Widget? image,
  }) {
    return EmptyStateWidget(
      message: message,
      subtitle: subtitle,
      onRetry: onRetry,
      retryButtonText: retryButtonText ?? '重试',
      image: image ?? const Icon(
        Icons.inbox,
        size: 64,
        color: Colors.grey,
      ),
    );
  }

  /// 加载状态
  factory EmptyStateWidget.loading({
    String message = '加载中...',
  }) {
    return EmptyStateWidget(
      message: message,
      icon: const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xffFF9027)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标或图片
            if (image != null) image!,
            if (icon != null) icon!,
            
            const SizedBox(height: 16),
            
            // 主消息
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xff333333),
              ),
              textAlign: TextAlign.center,
            ),
            
            // 副标题
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xff666666),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // 重试按钮
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffFF9027),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  retryButtonText ?? '重试',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
