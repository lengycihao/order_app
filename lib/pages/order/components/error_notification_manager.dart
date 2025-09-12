import 'package:flutter/material.dart';
import 'modal_utils.dart';

/// 错误提示管理器 - 防止重复提示
class ErrorNotificationManager {
  static final ErrorNotificationManager _instance = ErrorNotificationManager._internal();
  factory ErrorNotificationManager() => _instance;
  ErrorNotificationManager._internal();

  /// 已提示的错误消息集合（用于防重复）
  final Set<String> _shownErrors = <String>{};
  
  /// 错误提示的冷却时间（毫秒）
  static const int _cooldownMs = 3000;
  
  /// 错误提示记录（包含时间戳）
  final Map<String, int> _errorTimestamps = <String, int>{};

  /// 显示错误提示（防重复）
  void showErrorNotification({
    required String title,
    required String message,
    String? errorCode,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    // 生成错误标识符
    final errorKey = _generateErrorKey(title, message, errorCode);
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    // 检查是否在冷却时间内
    if (_errorTimestamps.containsKey(errorKey)) {
      final lastShownTime = _errorTimestamps[errorKey]!;
      if (currentTime - lastShownTime < _cooldownMs) {
        debugPrint('🚫 错误提示在冷却时间内，跳过: $message');
        return;
      }
    }
    
    // 检查是否已经显示过相同的错误
    if (_shownErrors.contains(errorKey)) {
      debugPrint('🚫 错误提示已显示过，跳过: $message');
      return;
    }
    
    // 显示错误提示
    ModalUtils.showSnackBar(
      title: title,
      message: message,
      backgroundColor: backgroundColor ?? Colors.red.withOpacity(0.1),
      textColor: textColor ?? Colors.red,
      duration: duration,
    );
    
    // 记录已显示的错误
    _shownErrors.add(errorKey);
    _errorTimestamps[errorKey] = currentTime;
    
    debugPrint('✅ 显示错误提示: $message');
    
    // 清理过期的错误记录（避免内存泄漏）
    _cleanupExpiredErrors(currentTime);
  }

  /// 显示成功提示（防重复）
  void showSuccessNotification({
    required String title,
    required String message,
    String? successCode,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    // 生成成功标识符
    final successKey = _generateErrorKey(title, message, successCode);
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    // 检查是否在冷却时间内
    if (_errorTimestamps.containsKey(successKey)) {
      final lastShownTime = _errorTimestamps[successKey]!;
      if (currentTime - lastShownTime < _cooldownMs) {
        debugPrint('🚫 成功提示在冷却时间内，跳过: $message');
        return;
      }
    }
    
    // 检查是否已经显示过相同的成功消息
    if (_shownErrors.contains(successKey)) {
      debugPrint('🚫 成功提示已显示过，跳过: $message');
      return;
    }
    
    // 显示成功提示
    ModalUtils.showSnackBar(
      title: title,
      message: message,
      backgroundColor: backgroundColor ?? Colors.green.withOpacity(0.1),
      textColor: textColor ?? Colors.green,
      duration: duration,
    );
    
    // 记录已显示的成功消息
    _shownErrors.add(successKey);
    _errorTimestamps[successKey] = currentTime;
    
    debugPrint('✅ 显示成功提示: $message');
    
    // 清理过期的记录
    _cleanupExpiredErrors(currentTime);
  }

  /// 显示警告提示（防重复）
  void showWarningNotification({
    required String title,
    required String message,
    String? warningCode,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    // 生成警告标识符
    final warningKey = _generateErrorKey(title, message, warningCode);
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    // 检查是否在冷却时间内
    if (_errorTimestamps.containsKey(warningKey)) {
      final lastShownTime = _errorTimestamps[warningKey]!;
      if (currentTime - lastShownTime < _cooldownMs) {
        debugPrint('🚫 警告提示在冷却时间内，跳过: $message');
        return;
      }
    }
    
    // 检查是否已经显示过相同的警告
    if (_shownErrors.contains(warningKey)) {
      debugPrint('🚫 警告提示已显示过，跳过: $message');
      return;
    }
    
    // 显示警告提示
    ModalUtils.showSnackBar(
      title: title,
      message: message,
      backgroundColor: backgroundColor ?? Colors.orange.withOpacity(0.1),
      textColor: textColor ?? Colors.orange,
      duration: duration,
    );
    
    // 记录已显示的警告
    _shownErrors.add(warningKey);
    _errorTimestamps[warningKey] = currentTime;
    
    debugPrint('✅ 显示警告提示: $message');
    
    // 清理过期的记录
    _cleanupExpiredErrors(currentTime);
  }

  /// 生成错误标识符
  String _generateErrorKey(String title, String message, String? code) {
    return '${title}_${message}_${code ?? ''}';
  }

  /// 清理过期的错误记录
  void _cleanupExpiredErrors(int currentTime) {
    final expiredKeys = <String>[];
    
    for (final entry in _errorTimestamps.entries) {
      if (currentTime - entry.value > _cooldownMs * 2) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _errorTimestamps.remove(key);
      _shownErrors.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      debugPrint('🧹 清理了 ${expiredKeys.length} 个过期的提示记录');
    }
  }

  /// 清除所有记录（用于测试或重置）
  void clearAllRecords() {
    _shownErrors.clear();
    _errorTimestamps.clear();
    debugPrint('🧹 清除了所有提示记录');
  }

  /// 强制显示提示（忽略防重复机制）
  void forceShowNotification({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    ModalUtils.showSnackBar(
      title: title,
      message: message,
      backgroundColor: backgroundColor,
      textColor: textColor,
      duration: duration,
    );
    
    debugPrint('🔓 强制显示提示: $message');
  }
}
