import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/login/login_page.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:order_app/service/service_locator.dart';
import 'package:lib_base/network/interceptor/auth_service.dart';
import 'package:order_app/utils/modal_utils.dart';
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
      final confirm = await ModalUtils.showConfirmDialog(
        context: Get.context!,
        message: '是否退出当前登录？',
        confirmText: '确认退出',
        cancelText: '取消',
        confirmColor: Colors.red,
      );
      
      if (confirm != true) return;
      
      print('🔓 开始退出登录...');
      
      // 清除登录信息缓存
      await _authService.logout();
      
      // 进入登录页面，不清除输入框内容
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
