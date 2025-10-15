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
      // 用户已经设置过语言，使用保存的设置
      _currentLocale = Locale(languageCode);
      print('🌐 从本地存储加载用户设置的语言: $languageCode');
    } else {
      // 用户没有设置过语言，优先使用系统语言
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      print('🌐 系统语言: ${systemLocale.languageCode}');
      
      if (supportedLocales.any((locale) => locale.languageCode == systemLocale.languageCode)) {
        _currentLocale = Locale(systemLocale.languageCode);
        print('🌐 使用系统语言: ${systemLocale.languageCode}');
      } else {
        _currentLocale = const Locale('zh');
        print('🌐 系统语言不支持，使用默认语言: zh');
      }
    }
    
    // 初始化时也要同步 GetX 的 locale
    Get.updateLocale(_currentLocale);
    
    notifyListeners();
  }
  
  /// 切换语言
  Future<void> changeLanguage(Locale locale) async {
    if (_currentLocale == locale) return;
    
    print('🌐 切换语言从 ${_currentLocale.languageCode} 到 ${locale.languageCode}');
    
    _currentLocale = locale;
    
    // 同步更新 GetX 的 locale
    Get.updateLocale(locale);
    
    notifyListeners();
    
    // 保存到本地存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
    
    print('🌐 语言设置已保存到本地存储: ${locale.languageCode}');
  }
  
  /// 获取当前语言名称
  String get currentLanguageName {
    return languageNames[_currentLocale.languageCode] ?? '中文';
  }
  
  /// 检查是否为指定语言
  bool isLanguage(String languageCode) {
    return _currentLocale.languageCode == languageCode;
  }
  
  /// 检查用户是否已经设置过语言
  Future<bool> hasUserSetLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_languageKey);
  }
  
  /// 获取网络请求头中的语言代码
  String getNetworkLanguageCode() {
    switch (_currentLocale.languageCode) {
      case 'zh':
        return 'cn';  // 中文映射为cn
      case 'en':
        return 'en';  // 英文保持不变
      case 'it':
        return 'it';  // 意大利文保持不变
      default:
        return 'cn';  // 默认使用中文
    }
  }
}

