import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/login/login_page.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:order_app/service/service_locator.dart';
import 'package:lib_base/network/interceptor/auth_service.dart';
import 'package:order_app/utils/modal_utils.dart';
import 'package:order_app/pages/table/table_controller.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/pages/order/order_main_page.dart';
import 'package:order_app/pages/takeaway/takeaway_controller.dart';
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
      
      // 清理所有相关的Controller和缓存数据
      await _clearAllCacheData();
      
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

  /// 清理所有缓存数据和Controller
  Future<void> _clearAllCacheData() async {
    try {
      print('🧹 开始清理所有缓存数据...');
      
      // 清理TableController及其数据
      if (Get.isRegistered<TableController>()) {
        Get.delete<TableController>();
        print('✅ TableController已清理');
      }
      
      // 清理OrderController及其WebSocket连接
      if (Get.isRegistered<OrderController>()) {
        Get.delete<OrderController>();
        print('✅ OrderController已清理');
      }
      
      // 清理OrderMainPageController
      if (Get.isRegistered<OrderMainPageController>()) {
        Get.delete<OrderMainPageController>();
        print('✅ OrderMainPageController已清理');
      }
      
      // 清理TakeawayController（如果存在）
      if (Get.isRegistered<TakeawayController>()) {
        Get.delete<TakeawayController>();
        print('✅ TakeawayController已清理');
      }
      
      print('✅ 所有缓存数据清理完成');
    } catch (e) {
      print('❌ 清理缓存数据时出现异常: $e');
    }
  }
}
