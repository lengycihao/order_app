import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/login/login_page.dart';
import 'package:order_app/utils/toast_component.dart';
import 'package:order_app/service/service_locator.dart';
import 'package:lib_base/network/interceptor/auth_service.dart';
// import '../../service/cart_cache_service.dart'; // 已泣释：不再需要缓存功能

class MineController extends GetxController {
  // 假设这些数据来自接口
  final nickname = '张三'.obs;
  final loginId = 'user_123456'.obs;
  final accountDate = DateTime(2020, 5, 10).obs;
  final remainMonth = 3.obs;
  final remainDay = 12.obs;
  final version = 'V1.0.0'.obs;

  final AuthService _authService = getIt<AuthService>();

  // 处理点击事件的业务逻辑
  void onTapLoginOut() async {
    try {
      // 显示确认对话框
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: Text('退出登录'),
          content: Text('是否退出当前登录？'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text('确认退出', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      
      if (confirm != true) return;
      
      print('🔓 开始退出登录...');
      
      // 清除登录信息缓存
      await _authService.logout();
      
      // 进入登录页面
      Get.offAll(() => LoginPage());
      
      ToastUtils.showSuccess(Get.context!, '退出登录成功');
      
      print('✅ 退出登录成功');
      
    } catch (e) {
      // 关闭加载对话框
      Get.back();
      ToastUtils.showError(Get.context!, '退出登录失败: $e');
      print('❌ 退出登录失败: $e');
    }
  }
}
