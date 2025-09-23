import 'package:flutter/material.dart';

/// 全局颜色配置
/// 通过全局类，让所有页面都能直接使用 GlobalColors 而不需要导入
class GlobalColors {
  // 私有构造函数，防止实例化
  GlobalColors._();

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
  static const Color divider = Color(0xFF999999);
  
  /// 卡片背景色
  static const Color cardBackground = Colors.white;
  
  /// 按钮禁用色
  static const Color buttonDisabled = Color(0xFFCCCCCC);
  
  /// 输入框背景色
  static const Color inputBackground = Color(0xFFEAF6FF);
}

/// 全局颜色常量，可以直接使用而不需要类名前缀
/// 这样所有页面都可以直接使用 primaryBackground 而不需要导入
const Color primaryBackground = GlobalColors.primaryBackground;
const Color whiteBackground = GlobalColors.whiteBackground;
const Color primary = GlobalColors.primary;
const Color success = GlobalColors.success;
const Color warning = GlobalColors.warning;
const Color error = GlobalColors.error;
const Color textPrimary = GlobalColors.textPrimary;
const Color textSecondary = GlobalColors.textSecondary;
const Color textHint = GlobalColors.textHint;
const Color divider = GlobalColors.divider;
const Color cardBackground = GlobalColors.cardBackground;
const Color buttonDisabled = GlobalColors.buttonDisabled;
const Color inputBackground = GlobalColors.inputBackground;
