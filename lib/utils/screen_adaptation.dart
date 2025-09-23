import 'package:flutter/material.dart';

/// 屏幕适配工具类
/// 以375*812为基准进行屏幕适配
class ScreenAdaptation {
  // 基准屏幕尺寸 (iPhone X/11/12/13/14 标准尺寸)
  static const double _baseWidth = 375.0;
  static const double _baseHeight = 812.0;
  
  /// 获取屏幕宽度适配比例
  static double getWidthScale(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth / _baseWidth;
  }
  
  /// 获取屏幕高度适配比例
  static double getHeightScale(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight / _baseHeight;
  }
  
  /// 获取屏幕宽度适配比例（基于宽度）
  static double getScale(BuildContext context) {
    return getWidthScale(context);
  }
  
  /// 适配宽度
  static double adaptWidth(BuildContext context, double width) {
    return width * getWidthScale(context);
  }
  
  /// 适配高度
  static double adaptHeight(BuildContext context, double height) {
    return height * getHeightScale(context);
  }
  
  /// 适配尺寸（基于宽度比例）
  static double adaptSize(BuildContext context, double size) {
    return size * getScale(context);
  }
  
  /// 适配字体大小
  static double adaptFontSize(BuildContext context, double fontSize) {
    return fontSize * getScale(context);
  }
  
  /// 适配间距
  static double adaptSpacing(BuildContext context, double spacing) {
    return spacing * getScale(context);
  }
  
  /// 适配圆角
  static double adaptRadius(BuildContext context, double radius) {
    return radius * getScale(context);
  }
  
  /// 获取屏幕宽度
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  /// 获取屏幕高度
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  /// 获取状态栏高度
  static double getStatusBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }
  
  /// 获取底部安全区域高度
  static double getBottomSafeHeight(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }
  
  /// 获取安全区域高度（去除状态栏和底部安全区域）
  static double getSafeHeight(BuildContext context) {
    return getScreenHeight(context) - getStatusBarHeight(context) - getBottomSafeHeight(context);
  }
  
  /// 检查是否为小屏幕设备
  static bool isSmallScreen(BuildContext context) {
    return getScreenWidth(context) < 375;
  }
  
  /// 检查是否为大屏幕设备
  static bool isLargeScreen(BuildContext context) {
    return getScreenWidth(context) > 414;
  }
  
  /// 检查是否为超大屏幕设备
  static bool isExtraLargeScreen(BuildContext context) {
    return getScreenWidth(context) > 768;
  }
}

/// 屏幕适配扩展方法
extension ScreenAdaptationExtension on BuildContext {
  /// 适配宽度
  double adaptWidth(double width) => ScreenAdaptation.adaptWidth(this, width);
  
  /// 适配高度
  double adaptHeight(double height) => ScreenAdaptation.adaptHeight(this, height);
  
  /// 适配尺寸
  double adaptSize(double size) => ScreenAdaptation.adaptSize(this, size);
  
  /// 适配字体大小
  double adaptFontSize(double fontSize) => ScreenAdaptation.adaptFontSize(this, fontSize);
  
  /// 适配间距
  double adaptSpacing(double spacing) => ScreenAdaptation.adaptSpacing(this, spacing);
  
  /// 适配圆角
  double adaptRadius(double radius) => ScreenAdaptation.adaptRadius(this, radius);
  
  /// 获取屏幕宽度
  double get screenWidth => ScreenAdaptation.getScreenWidth(this);
  
  /// 获取屏幕高度
  double get screenHeight => ScreenAdaptation.getScreenHeight(this);
  
  /// 获取状态栏高度
  double get statusBarHeight => ScreenAdaptation.getStatusBarHeight(this);
  
  /// 获取底部安全区域高度
  double get bottomSafeHeight => ScreenAdaptation.getBottomSafeHeight(this);
  
  /// 获取安全区域高度
  double get safeHeight => ScreenAdaptation.getSafeHeight(this);
  
  /// 是否为小屏幕
  bool get isSmallScreen => ScreenAdaptation.isSmallScreen(this);
  
  /// 是否为大屏幕
  bool get isLargeScreen => ScreenAdaptation.isLargeScreen(this);
  
  /// 是否为超大屏幕
  bool get isExtraLargeScreen => ScreenAdaptation.isExtraLargeScreen(this);
}
