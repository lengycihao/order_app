import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/nav/screen_nav_page.dart';
import 'package:lib_base/network/interceptor/auth_service.dart';
import 'package:order_app/service/service_locator.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:order_app/services/language_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lib_base/logging/logging.dart';

class LoginController extends GetxController {
  // 使用 TextEditingController 管理输入框
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = getIt<AuthService>();
  final languageService = getIt<LanguageService>();
  var isExpanded = false.obs;
  var obscurePassword = true.obs; // 密码是否明文显示
  var selectedLanguageIndex = 0.obs; // 当前选中的语言索引
  var isAccountDropdownExpanded = false.obs; // 账号下拉框是否展开
  var recentAccounts = <String>[].obs; // 近期登录账号列表
  var recentPasswords = <String>[].obs; // 近期登录密码列表

  final List<Map<String, String>> languages = [
    {'code': 'zh', 'name': '中文(简体)', 'flag': 'assets/order_login_china.webp'},
    {'code': 'en', 'name': 'English', 'flag': 'assets/order_login_english.webp'},
    {'code': 'it', 'name': 'Italia', 'flag': 'assets/order_login_italiano.webp'},
  ];

  @override
  void onInit() {
    super.onInit();
    // 初始化当前语言选择
    final currentLang = languageService.currentLocale.languageCode;
    selectedLanguageIndex.value = languages.indexWhere((lang) => lang['code'] == currentLang);
    if (selectedLanguageIndex.value == -1) selectedLanguageIndex.value = 0;
    
    // 加载近期登录账号
    _loadRecentAccounts();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  // 切换账号下拉框
  void toggleAccountDropdown() {
    isAccountDropdownExpanded.value = !isAccountDropdownExpanded.value;
  }

  // 选择账号
  void selectAccount(String account) {
    usernameController.text = account;
    
    // 查找对应的密码并填充
    final accountIndex = recentAccounts.indexOf(account);
    if (accountIndex != -1 && accountIndex < recentPasswords.length) {
      passwordController.text = recentPasswords[accountIndex];
    }
    
    isAccountDropdownExpanded.value = false;
  }

  // 加载近期登录账号
  Future<void> _loadRecentAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accounts = prefs.getStringList('recent_accounts') ?? [];
      final passwords = prefs.getStringList('recent_passwords') ?? [];
      
      recentAccounts.value = accounts;
      recentPasswords.value = passwords;
      
      // 如果有最近登录的账号，自动填充到输入框
      if (accounts.isNotEmpty) {
        usernameController.text = accounts.first;
        // 如果有对应的密码，也自动填充
        if (passwords.isNotEmpty) {
          passwordController.text = passwords.first;
        }
      }
    } catch (e) {
      logError('加载近期账号失败: $e', tag: 'LoginController');
    }
  }

  // 保存账号和密码到近期列表
  Future<void> _saveRecentAccount(String account, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> accounts = prefs.getStringList('recent_accounts') ?? [];
      List<String> passwords = prefs.getStringList('recent_passwords') ?? [];
      
      // 移除重复的账号和对应的密码
      final accountIndex = accounts.indexOf(account);
      if (accountIndex != -1) {
        accounts.removeAt(accountIndex);
        if (accountIndex < passwords.length) {
          passwords.removeAt(accountIndex);
        }
      }
      
      // 添加到列表开头
      accounts.insert(0, account);
      passwords.insert(0, password);
      
      // 最多保存5个账号和密码
      if (accounts.length > 5) {
        accounts = accounts.take(5).toList();
        passwords = passwords.take(5).toList();
      }
      
      await prefs.setStringList('recent_accounts', accounts);
      await prefs.setStringList('recent_passwords', passwords);
      recentAccounts.value = accounts;
      recentPasswords.value = passwords;
    } catch (e) {
      logError('保存近期账号失败: $e', tag: 'LoginController');
    }
  }

  // 切换语言
  void selectLanguage(int index) async {
    if (index >= 0 && index < languages.length) {
      selectedLanguageIndex.value = index;
      final selectedLang = languages[index];
      final newLocale = Locale(selectedLang['code']!);
      
      try {
        await languageService.changeLanguage(newLocale);
        isExpanded.value = false; // 切换后收起
      } catch (e) {
        logError('语言切换失败: $e', tag: 'LoginController');
      }
    }
  }

  // 获取当前选中语言的显示名称
  String get currentLanguageName {
    return languages[selectedLanguageIndex.value]['name'] ?? '中文(简体)';
  }

  // 显示Toast消息
  void _showToast(String message, {required bool isError}) {
    try {
      // 首先尝试使用GlobalToast
      if (isError) {
        GlobalToast.error(message);
      } else {
        GlobalToast.success(message);
      }
    } catch (e) {
      // 如果GlobalToast失败，使用Get.snackbar作为备选方案
      Get.snackbar(
        '',
        message,
        backgroundColor: isError ? Colors.red : Colors.green,
        colorText: Colors.white,
        icon: Icon(
          isError ? Icons.error : Icons.check_circle,
          color: Colors.white,
        ),
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        forwardAnimationCurve: Curves.easeOutBack,
        reverseAnimationCurve: Curves.easeInBack,
        animationDuration: const Duration(milliseconds: 300),
      );
    }
  }

  void login() {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showToast('账号或密码不能为空', isError: true);
      return;
    }
    _loginWithApi(name: username, psw: password);
  }

  Future<void> _loginWithApi({
    required String name,
    required String psw,
  }) async {
    try {
      // ✅ 通过 getIt 获取 AuthService 单例

      final result = await authService.loginWithPassword(
        phoneNumber: name,
        password: psw,
      );

      if (result.isSuccess) {
        // 登录成功后保存账号和密码
        await _saveRecentAccount(name, psw);
        _showToast('登录成功', isError: false);
        Get.offAll(() => ScreenNavPage());
      } else {
        _showToast(result.msg ?? '登录失败', isError: true);
      }
    } catch (e) {
      _showToast('登录失败: $e', isError: true);
    }
  }
}
