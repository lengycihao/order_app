import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:toast/toast.dart' as toast_plugin;

/// Toast类型枚举
enum ToastType {
  error,
  success,
  warning,
  info,
}

/// Toast位置枚举
enum ToastPosition {
  top,
  center, 
  bottom,
}

/// 统一的Toast工具类
class Toast {
  /// 显示成功提示
  static void success(
    BuildContext context,
    String message, {
    ToastPosition position = ToastPosition.bottom,
    Duration duration = const Duration(seconds: 2),
  }) {
    _showToast(
      context,
      message,
      position,
      duration,
      const Color(0xFF27AE60),
    );
  }

  /// 显示错误提示
  static void error(
    BuildContext context,
    String message, {
    ToastPosition position = ToastPosition.bottom,
    Duration duration = const Duration(seconds: 2),
  }) {
    _showToast(
      context,
      message,
      position,
      duration,
      const Color(0xFFE74C3C),
    );
  }

  /// 显示警告提示
  static void warning(
    BuildContext context,
    String message, {
    ToastPosition position = ToastPosition.bottom,
    Duration duration = const Duration(seconds: 2),
  }) {
    _showToast(
      context,
      message,
      position,
      duration,
      const Color(0xFFF39C12),
    );
  }

  /// 显示信息提示
  static void info(
    BuildContext context,
    String message, {
    ToastPosition position = ToastPosition.bottom,
    Duration duration = const Duration(seconds: 2),
  }) {
    _showToast(
      context,
      message,
      position,
      duration,
      const Color(0xFF3498DB),
    );
  }

  /// 隐藏当前Toast
  static void hide() {
    // toast 0.3.0 插件会自动管理队列，无需手动清除
  }

  // 私有方法：显示Toast
  static void _showToast(
    BuildContext context,
    String message,
    ToastPosition position,
    Duration duration,
    Color backgroundColor,
  ) {
    try {
      toast_plugin.Toast.show(
        message,
        duration: duration.inSeconds,
        gravity: _getToastGravity(position),
        backgroundColor: backgroundColor,
        backgroundRadius: 8.0,
      );
    } catch (e) {
      debugPrint('Toast显示失败: $e');
      }
  }

 

  // 转换位置枚举为Toast插件的gravity值
  static int _getToastGravity(ToastPosition position) {
    switch (position) {
      case ToastPosition.top:
        return toast_plugin.Toast.top;
      case ToastPosition.center:
        return toast_plugin.Toast.center;
      case ToastPosition.bottom:
        return toast_plugin.Toast.bottom;
    }
  }
}

/// 全局Toast工具类 - 无需传入Context
/// 
/// 这个类提供了更简单的API，不需要传入BuildContext
/// 它会自动使用Get.context或全局的navigator key来获取context
class GlobalToast {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// 显示成功消息
  static void success(String message) {
    _showWithRetry(message, ToastType.success);
  }

  /// 显示错误消息
  static void error(String message) {
    _showWithRetry(message, ToastType.error);
  }

  /// 显示警告消息
  static void warning(String message) {
    _showWithRetry(message, ToastType.warning);
  }

  /// 显示信息消息
  static void info(String message) {
    _showWithRetry(message, ToastType.info);
  }

  /// 显示普通消息（默认为信息类型）
  static void message(String message) {
    _showWithRetry(message, ToastType.info);
  }

  /// 隐藏当前Toast
  static void hide() {
    Toast.hide();
  }

  static void _showWithRetry(String message, ToastType type) {
    try {
      // 确保在调用前初始化有 Overlay 的上下文
      // 优先使用 GetX 提供的 overlayContext，其次使用 Get.context
      final BuildContext? usableContext = Get.overlayContext ?? Get.context;
      if (usableContext != null) {
        toast_plugin.ToastContext().init(usableContext);
      }

      // 使用自定义 Overlay Toast 以支持图标与自定义样式
      _showOverlayToast(
        context: usableContext,
        message: message,
        type: type,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('Toast显示失败: $e - $message');
      
      // 降级处理：尝试使用Get.context和SnackBar
      BuildContext? context = Get.overlayContext ?? Get.context;
      if (context != null && context.mounted) {
        try {
          final Color backgroundColor = _getBackgroundColor(type);
          final String iconAsset = _getIconAsset(type);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(iconAsset, width: 16, height: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: Color(0xFF333333), fontSize: 12),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: backgroundColor,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          );
        } catch (e2) {
          debugPrint('SnackBar降级处理也失败: $e2');
          // 最终降级：输出到控制台
          debugPrint('TOAST: [$type] $message');
        }
      } else {
        // 最终降级：输出到控制台
        debugPrint('TOAST: [$type] $message');
      }
    }
  }

  static void _showOverlayToast({
    required BuildContext? context,
    required String message,
    required ToastType type,
    required Duration duration,
  }) {
    final BuildContext? ctx = context ?? Get.overlayContext ?? Get.context;
    if (ctx == null || !ctx.mounted) {
      // 无上下文则直接放弃（调用方会进行降级）
      throw Exception('No overlay context');
    }

    // 若已有展示中的 Toast，则移除
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;

    final Color backgroundColor = _getBackgroundColor(type);
    final String iconAsset = _getIconAsset(type);

    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext context) {
        return IgnorePointer(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(iconAsset, width: 16, height: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        message,
                        style: const TextStyle(color: Color(0xFF333333), fontSize: 12),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    final OverlayState? overlay = Overlay.of(ctx, rootOverlay: true);
    if (overlay == null) {
      throw Exception('No overlay state');
    }
    overlay.insert(entry);
    _currentEntry = entry;

    _dismissTimer = Timer(duration, () {
      _currentEntry?.remove();
      _currentEntry = null;
      _dismissTimer = null;
    });
  }

  static Color _getBackgroundColor(ToastType type) {
    switch (type) {
      case ToastType.error:
        return const Color(0xFFFFF0F0);
      case ToastType.success:
        return const Color(0xFFE4F7F0);
      case ToastType.warning:
        return const Color(0xFFFFF4E5);
      case ToastType.info:
        return const Color(0xFFE6F7FF);
    }
  }

  static String _getIconAsset(ToastType type) {
    switch (type) {
      case ToastType.error:
        return 'assets/order_error.webp';
      case ToastType.success:
        return 'assets/order_success.webp';
      case ToastType.warning:
        return 'assets/order_warning_toast.webp';
      case ToastType.info:
        return 'assets/order_messgae_toast.webp';
    }
  }
}

/// 为了向后兼容，提供一个简单的ToastUtils类
class ToastUtils {
  /// 显示错误消息
  static void showError(BuildContext? context, String message) {
    GlobalToast.error(message);
  }

  /// 显示成功消息
  static void showSuccess(BuildContext? context, String message) {
    GlobalToast.success(message);
  }

  /// 显示警告消息
  static void showWarning(BuildContext? context, String message) {
    GlobalToast.warning(message);
  }

  /// 显示信息消息
  static void showInfo(BuildContext? context, String message) {
    GlobalToast.info(message);
  }
}