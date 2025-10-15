# 语言设置优化总结

## 🎯 优化目标

1. **系统语言优先级**：用户没有设置过语言时，优先使用系统语言
2. **用户设置优先**：用户设置过语言后，不再使用系统语言
3. **网络请求头同步**：确保网络请求头中的Language字段正确更新

## 🔧 实现的优化

### 1. LanguageService 优化

#### 新增方法：
- `hasUserSetLanguage()`: 检查用户是否已经设置过语言
- `getNetworkLanguageCode()`: 获取网络请求头中的语言代码

#### 优化初始化逻辑：
```dart
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
    if (supportedLocales.any((locale) => locale.languageCode == systemLocale.languageCode)) {
      _currentLocale = Locale(systemLocale.languageCode);
      print('🌐 使用系统语言: ${systemLocale.languageCode}');
    } else {
      _currentLocale = const Locale('zh');
      print('🌐 系统语言不支持，使用默认语言: zh');
    }
  }
  
  Get.updateLocale(_currentLocale);
  notifyListeners();
}
```

### 2. 网络请求头优化

#### 简化语言头设置：
```dart
// 添加语言头
try {
  final languageService = getIt<LanguageService>();
  final serverLanguageCode = languageService.getNetworkLanguageCode();
  
  options.headers['Language'] = serverLanguageCode;
  print('🌐 添加语言头: ${languageService.currentLocale.languageCode} -> $serverLanguageCode');
} catch (e) {
  options.headers['Language'] = 'cn';
  print('🌐 无法获取LanguageService，使用默认语言: cn, 错误: $e');
}
```

### 3. 语言代码映射

| Flutter语言代码 | 网络请求头代码 | 说明 |
|----------------|---------------|------|
| zh             | cn            | 中文映射为cn |
| en             | en            | 英文保持不变 |
| it             | it            | 意大利文保持不变 |

## 🎯 工作流程

### 首次安装应用：
1. 检查本地存储是否有语言设置
2. 如果没有，获取系统语言
3. 如果系统语言在支持列表中，使用系统语言
4. 如果系统语言不支持，使用默认中文
5. 网络请求头使用对应的语言代码

### 用户设置语言后：
1. 保存用户选择的语言到本地存储
2. 更新当前语言设置
3. 同步更新GetX的locale
4. 网络请求头自动使用新的语言代码

### 应用重启后：
1. 从本地存储读取用户设置的语言
2. 不再使用系统语言，直接使用用户设置
3. 网络请求头使用保存的语言代码

## 🧪 测试页面

创建了 `LanguageTestPage` 用于测试语言设置逻辑：
- 显示当前语言状态
- 显示用户是否设置过语言
- 提供语言切换按钮
- 显示网络请求头语言代码

## ✅ 优化效果

1. **智能语言选择**：首次安装时自动使用系统语言
2. **用户设置优先**：设置过语言后不再受系统语言影响
3. **网络请求同步**：语言切换时网络请求头自动更新
4. **代码简化**：网络请求头设置逻辑更加简洁
5. **调试友好**：添加了详细的日志输出

## 🔍 关键特性

- ✅ 首次安装优先使用系统语言
- ✅ 用户设置后不再使用系统语言
- ✅ 网络请求头自动同步语言设置
- ✅ 中文正确映射为cn
- ✅ 支持中文、英文、意大利文
- ✅ 语言设置持久化存储
- ✅ 详细的调试日志
