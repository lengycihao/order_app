import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/nav/screen_nav_page.dart';
import 'package:lib_base/network/interceptor/auth_service.dart';
import 'package:order_app/service/service_locator.dart';
import 'package:order_app/utils/toast_utils.dart';

class LoginController extends GetxController {
  // 使用 TextEditingController 管理输入框
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = getIt<AuthService>();
  var isExpanded = false.obs;
  var obscurePassword = true.obs; // 密码是否明文显示

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void login() {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      Toast.error(Get.context!, '账号或密码不能为空');
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
        Toast.success(Get.context!, '登录成功');
        Get.offAll(() => ScreenNavPage());
      } else {
        Toast.error(Get.context!, result.msg ?? '登录失败');
      }
    } catch (e) {
      Toast.error(Get.context!, '登录失败: $e');
    }
  }
}
