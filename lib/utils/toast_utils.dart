import 'package:flutter/material.dart';
import 'toast_component.dart';

/// 简化的Toast工具类
class Toast {
  /// 显示错误提示
  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (context.mounted) {
      ToastUtils.showError(
        context,
        message,
        duration: duration,
        position: ToastPosition.center,
      );
    }
  }

  /// 显示成功提示
  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (context.mounted) {
      ToastUtils.showSuccess(
        context,
        message,
        duration: duration,
        position: ToastPosition.center,
      );
    }
  }

  /// 显示信息提示
  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (context.mounted) {
      ToastUtils.showError(
        context,
        message,
        duration: duration,
        position: ToastPosition.center,
      );
    }
  }

  /// 显示警告提示
  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (context.mounted) {
      ToastUtils.showWarning(
        context,
        message,
        duration: duration,
        position: ToastPosition.center,
      );
    }
  }

  /// 显示消息提示
  static void message(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (context.mounted) {
      ToastUtils.showMessage(
        context,
        message,
        duration: duration,
        position: ToastPosition.center,
      );
    }
  }

  /// 隐藏当前Toast
  static void hide() {
    ToastUtils.hide();
  }

  /// 清除Toast队列
  static void clearQueue() {
    ToastUtils.clearQueue();
  }
}

/// 全局Toast工具类（不依赖Context）
class GlobalToast {
  static BuildContext? _context;

  /// 设置全局Context
  static void setContext(BuildContext context) {
    _context = context;
  }

  /// 显示错误提示
  static void error(String message, {Duration duration = const Duration(seconds: 2)}) {
    if (_context != null && _context!.mounted) {
      Toast.error(_context!, message, duration: duration);
    }
  }

  /// 显示成功提示
  static void success(String message, {Duration duration = const Duration(seconds: 2)}) {
    if (_context != null && _context!.mounted) {
      Toast.success(_context!, message, duration: duration);
    }
  }

  /// 显示警告提示
  static void warning(String message, {Duration duration = const Duration(seconds: 2)}) {
    if (_context != null && _context!.mounted) {
      Toast.warning(_context!, message, duration: duration);
    }
  }

  /// 显示消息提示
  static void message(String message, {Duration duration = const Duration(seconds: 2)}) {
    if (_context != null && _context!.mounted) {
      Toast.message(_context!, message, duration: duration);
    }
  }

  /// 隐藏当前Toast
  static void hide() {
    ToastUtils.hide();
  }

  /// 清除Toast队列
  static void clearQueue() {
    ToastUtils.clearQueue();
  }
}
