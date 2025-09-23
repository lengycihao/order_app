import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// 扩展方法，让BuildContext直接支持l10n
extension L10nExtension on BuildContext {
  AppLocalizations get l10n => L10nUtils.of(this);
}

/// 多语言工具类
class L10nUtils {
  /// 获取当前语言环境
  static AppLocalizations of(BuildContext context) {
    return AppLocalizations.of(context)!;
  }
  
  /// 获取当前语言代码
  static String getCurrentLanguageCode(BuildContext context) {
    return Localizations.localeOf(context).languageCode;
  }
  
  /// 检查是否为中文
  static bool isChinese(BuildContext context) {
    return getCurrentLanguageCode(context) == 'zh';
  }
  
  /// 检查是否为英文
  static bool isEnglish(BuildContext context) {
    return getCurrentLanguageCode(context) == 'en';
  }
  
  /// 检查是否为意大利文
  static bool isItalian(BuildContext context) {
    return getCurrentLanguageCode(context) == 'it';
  }
  
  /// 根据语言环境获取不同的文本
  static String getLocalizedText(
    BuildContext context, {
    required String zh,
    required String en,
    required String it,
  }) {
    final languageCode = getCurrentLanguageCode(context);
    switch (languageCode) {
      case 'zh':
        return zh;
      case 'en':
        return en;
      case 'it':
        return it;
      default:
        return zh;
    }
  }
  
  /// 获取本地化的数字格式
  static String formatNumber(BuildContext context, num number) {
    final languageCode = getCurrentLanguageCode(context);
    switch (languageCode) {
      case 'zh':
        return number.toString();
      case 'en':
        return number.toString();
      case 'it':
        return number.toString().replaceAll('.', ',');
      default:
        return number.toString();
    }
  }
  
  /// 获取本地化的货币格式
  static String formatCurrency(BuildContext context, num amount, {String symbol = '€'}) {
    final languageCode = getCurrentLanguageCode(context);
    switch (languageCode) {
      case 'zh':
        return '¥${formatNumber(context, amount)}';
      case 'en':
        return '$symbol${formatNumber(context, amount)}';
      case 'it':
        return '${formatNumber(context, amount)} $symbol';
      default:
        return '$symbol${formatNumber(context, amount)}';
    }
  }
  
  /// 获取本地化的日期格式
  static String formatDate(BuildContext context, DateTime date) {
    final languageCode = getCurrentLanguageCode(context);
    switch (languageCode) {
      case 'zh':
        return '${date.year}年${date.month}月${date.day}日';
      case 'en':
        return '${date.month}/${date.day}/${date.year}';
      case 'it':
        return '${date.day}/${date.month}/${date.year}';
      default:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
  
  /// 获取本地化的时间格式
  static String formatTime(BuildContext context, DateTime time) {
    final languageCode = getCurrentLanguageCode(context);
    switch (languageCode) {
      case 'zh':
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      case 'en':
        final period = time.hour >= 12 ? 'PM' : 'AM';
        final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
        return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
      case 'it':
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      default:
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
