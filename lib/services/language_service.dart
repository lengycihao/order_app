import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

/// 语言管理服务
class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _currentLocale = const Locale('zh', '');
  
  Locale get currentLocale => _currentLocale;
  
  /// 支持的语言列表
  static const List<Locale> supportedLocales = [
    Locale('zh', ''), // 中文
    Locale('en', ''), // 英文
    Locale('it', ''), // 意大利文
  ];
  
  /// 语言名称映射
  static const Map<String, String> languageNames = {
    'zh': '中文(简体)',
    'en': 'English',
    'it': 'Italia',
  };
  
  /// 初始化语言设置
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);
    
    if (languageCode != null) {
      _currentLocale = Locale(languageCode);
    } else {
      // 默认使用系统语言，如果系统语言不在支持列表中则使用中文
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      if (supportedLocales.any((locale) => locale.languageCode == systemLocale.languageCode)) {
        _currentLocale = Locale(systemLocale.languageCode);
      }
    }
    
    // 初始化时也要同步 GetX 的 locale
    Get.updateLocale(_currentLocale);
    
    notifyListeners();
  }
  
  /// 切换语言
  Future<void> changeLanguage(Locale locale) async {
    if (_currentLocale == locale) return;
    
    _currentLocale = locale;
    
    // 同步更新 GetX 的 locale
    Get.updateLocale(locale);
    
    notifyListeners();
    
    // 保存到本地存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
  }
  
  /// 获取当前语言名称
  String get currentLanguageName {
    return languageNames[_currentLocale.languageCode] ?? '中文';
  }
  
  /// 检查是否为指定语言
  bool isLanguage(String languageCode) {
    return _currentLocale.languageCode == languageCode;
  }
}

