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
    ToastUtils.showError(
      context,
      message,
      duration: duration,
      position: ToastPosition.center,
    );
  }

  /// 显示成功提示
  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ToastUtils.showSuccess(
      context,
      message,
      duration: duration,
      position: ToastPosition.center,
    );
  }

  /// 显示信息提示
  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ToastUtils.showError(
      context,
      message,
      duration: duration,
      position: ToastPosition.center,
    );
  }

  /// 隐藏当前Toast
  static void hide() {
    ToastUtils.hide();
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
    if (_context != null) {
      Toast.error(_context!, message, duration: duration);
    }
  }

  /// 显示成功提示
  static void success(String message, {Duration duration = const Duration(seconds: 2)}) {
    if (_context != null) {
      Toast.success(_context!, message, duration: duration);
    }
  }

  /// 隐藏当前Toast
  static void hide() {
    ToastUtils.hide();
  }
}
