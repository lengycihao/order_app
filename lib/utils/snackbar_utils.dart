import 'package:flutter/material.dart';

class SnackbarUtils {
  // 存储当前显示的SnackBar
  static ScaffoldMessengerState? _currentMessenger;

  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.green);
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.red);
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.blue);
  }

  static void showWarning(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.orange);
  }

  // 兼容原有的 Get.snackbar 调用方式
  static void show(BuildContext context, String title, String message, {String? type}) {
    Color backgroundColor;
    switch (type?.toLowerCase()) {
      case 'success':
        backgroundColor = Colors.green;
        break;
      case 'error':
        backgroundColor = Colors.red;
        break;
      case 'warning':
        backgroundColor = Colors.orange;
        break;
      default:
        backgroundColor = Colors.blue;
    }

    _showSnackBar(context, '$title: $message', backgroundColor);
  }

  // 显示临时提示（会自动取消之前的提示）
  static void showTemporary(BuildContext context, String message, {Color? color}) {
    _showSnackBar(context, message, color ?? Colors.blue, isTemporary: true);
  }

  // 取消当前显示的SnackBar
  static void dismissCurrent() {
    if (_currentMessenger != null) {
      try {
        _currentMessenger!.hideCurrentSnackBar();
      } catch (e) {
        // 忽略dismiss时的错误，可能是context已经被移除
        print('SnackBar dismiss error (ignored): $e');
      } finally {
        _currentMessenger = null;
      }
    }
  }

  // 安全地取消当前显示的SnackBar（带页面状态检查）
  static void dismissCurrentSafely(BuildContext context) {
    if (context.mounted && _currentMessenger != null) {
      try {
        _currentMessenger!.hideCurrentSnackBar();
      } catch (e) {
        // 忽略dismiss时的错误，可能是context已经被移除
        print('SnackBar dismiss error (ignored): $e');
      } finally {
        _currentMessenger = null;
      }
    }
  }

  // 私有方法：显示SnackBar
  static void _showSnackBar(BuildContext context, String message, Color color, {bool isTemporary = false}) {
    // 如果是临时提示，先取消之前的提示
    if (isTemporary) {
      dismissCurrent();
    }

    _currentMessenger = ScaffoldMessenger.of(context);
    _currentMessenger!.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: color,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
