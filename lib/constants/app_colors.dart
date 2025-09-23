import 'package:flutter/material.dart';

/// 应用颜色配置
/// 统一管理应用中的所有颜色，方便后续修改和维护
class AppColors {
  // 私有构造函数，防止实例化
  AppColors._();

  /// 主背景颜色 - 浅灰色
  static const Color primaryBackground = Color(0xFFF9F9F9);
  
  /// 白色背景
  static const Color whiteBackground = Colors.white;
  
  /// 主色调 - 蓝色
  static const Color primary = Color(0xFF2196F3);
  
  /// 成功色 - 绿色
  static const Color success = Color(0xFF4CAF50);
  
  /// 警告色 - 橙色
  static const Color warning = Color(0xFFFF9800);
  
  /// 错误色 - 红色
  static const Color error = Color(0xFFF44336);
  
  /// 文字主色 - 深灰色
  static const Color textPrimary = Color(0xFF333333);
  
  /// 文字次色 - 中灰色
  static const Color textSecondary = Color(0xFF666666);
  
  /// 文字辅助色 - 浅灰色
  static const Color textHint = Color(0xFF999999);
  
  /// 分割线颜色
  static const Color divider = Color(0xFFE0E0E0);
  
  /// 卡片背景色
  static const Color cardBackground = Colors.white;
  
  /// 按钮禁用色
  static const Color buttonDisabled = Color(0xFFCCCCCC);
}
