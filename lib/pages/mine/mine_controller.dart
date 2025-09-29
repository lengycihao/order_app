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
import 'package:order_app/pages/table/sub_page/select_menu_controller.dart';
import 'package:lib_base/logging/logging.dart';
import 'package:lib_domain/api/base_api.dart';
// import '../../service/cart_cache_service.dart'; // 已泣释：不再需要缓存功能

class MineController extends GetxController {
  // 用户信息
  final nickname = ''.obs;
  final account = ''.obs; // 使用API的account字段，而不是loginId
  final storeName = ''.obs; // 餐馆名字
  final authExpireDate = ''.obs; // 到期时间 YYYY-MM-DD 格式
  final surplusDays = 0.obs; // 剩余天数
  final version = 'V1.0.0'.obs;
  final isLoading = false.obs; // 加载状态

  // 保持兼容性
  final loginId = ''.obs; // 兼容性字段
  final accountDate = DateTime.now().obs; // 兼容性字段
  final remainMonth = 0.obs; // 兼容性字段
  final remainDay = 0.obs; // 兼容性字段

  final AuthService _authService = getIt<AuthService>();
  final BaseApi _baseApi = BaseApi();

  @override
  void onInit() {
    super.onInit();
    _loadUserInfo();
    _loadWaiterInfo(); // 加载服务员详细信息
  }

  /// 加载用户信息（兼容性保持）
  void _loadUserInfo() {
    final user = _authService.currentUser;
    if (user != null) {
      // 设置兼容性字段
      loginId.value = user.waiterId?.toString() ?? '未知ID';
      
      // 如果API还没有加载，先使用现有数据
      if (nickname.value.isEmpty) {
        nickname.value = user.waiterName ?? user.waiterName.toString()  ;
        account.value = user.waiterId?.toString() ?? '未知ID';
        storeName.value = '未知餐馆';
        authExpireDate.value = '未知到期时间';
        surplusDays.value = 0;
      }
    } else {
      nickname.value = '未登录';
      loginId.value = '未登录';
      account.value = '未登录';
    }
  }

  /// 加载服务员详细信息
  Future<void> _loadWaiterInfo() async {
    try {
      isLoading.value = true;
      
      final result = await _baseApi.getWaiterInfo();
      
      if (result.isSuccess && result.data != null) {
        final waiterInfo = result.data!;
        
        // 更新UI显示的字段
        nickname.value = waiterInfo.name;
        account.value = waiterInfo.account;
        storeName.value = waiterInfo.storeName;
        authExpireDate.value = waiterInfo.formattedExpireDate;
        surplusDays.value = waiterInfo.surplusDays;
        
        logDebug('✅ 服务员信息加载成功: ${waiterInfo.name}', tag: 'MineController');
      } else {
        logDebug('❌ 服务员信息加载失败: ${result.msg}', tag: 'MineController');
        // 保持现有信息，不显示错误
      }
    } catch (e) {
      logDebug('❌ 服务员信息加载异常: $e', tag: 'MineController');
      // 保持现有信息，不显示错误
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新用户信息
  Future<void> refreshUserInfo() async {
    await _authService.refreshUserInfo();
    _loadUserInfo();
    await _loadWaiterInfo(); // 同时刷新服务员信息
  }

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
      
      logDebug('🔓 开始退出登录...', tag: 'MineController');
      
      // 清理所有相关的Controller和缓存数据
      await _clearAllCacheData();
      
      // 清除登录信息缓存
      await _authService.logout();
      
      // 进入登录页面，不清除输入框内容
      Get.offAll(() => LoginPage());
      
      ToastUtils.showSuccess(Get.context!, '退出登录成功');
      
      logDebug('✅ 退出登录成功', tag: 'MineController');
      
    } catch (e) {
      // 关闭加载对话框
      Get.back();
      ToastUtils.showError(Get.context!, '退出登录失败: $e');
      logError('❌ 退出登录失败: $e', tag: 'MineController');
    }
  }

  /// 清理所有缓存数据和Controller
  Future<void> _clearAllCacheData() async {
    try {
      logDebug('开始清理所有缓存数据...', tag: 'MineController');
      
      // 清理TableController及其数据
      if (Get.isRegistered<TableControllerRefactored>()) {
        Get.delete<TableControllerRefactored>();
        logDebug('TableController已清理', tag: 'MineController');
      }
      
      // 清理OrderController及其WebSocket连接
      if (Get.isRegistered<OrderController>()) {
        Get.delete<OrderController>();
        logDebug('OrderController已清理', tag: 'MineController');
      }
      
      // 清理OrderMainPageController
      if (Get.isRegistered<OrderMainPageController>()) {
        Get.delete<OrderMainPageController>();
        logDebug('OrderMainPageController已清理', tag: 'MineController');
      }
      
      // 清理TakeawayController（如果存在）
      if (Get.isRegistered<TakeawayController>(tag: 'takeaway_page')) {
        Get.delete<TakeawayController>(tag: 'takeaway_page');
        logDebug('TakeawayController已清理', tag: 'MineController');
      }
      
      // 清理SelectMenuController（如果存在）
      if (Get.isRegistered<SelectMenuController>(tag: 'select_menu_page')) {
        Get.delete<SelectMenuController>(tag: 'select_menu_page');
        logDebug('SelectMenuController已清理', tag: 'MineController');
      }
      
      logDebug('所有缓存数据清理完成', tag: 'MineController');
    } catch (e) {
      logError('清理缓存数据时出现异常: $e', tag: 'MineController');
    }
  }
}
