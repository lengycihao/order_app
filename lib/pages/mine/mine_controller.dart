import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/login/login_page.dart';
import 'package:order_app/utils/l10n_utils.dart';
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
    // 延迟初始化，确保AuthService完全准备好
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserData();
    });
  }

  /// 初始化用户数据
  Future<void> _initializeUserData() async {
    try {
      // 等待一小段时间确保AuthService完全初始化
      await Future.delayed(const Duration(milliseconds: 100));
      
      _loadUserInfo();
      await _loadWaiterInfo(); // 加载服务员详细信息
      
      logDebug('✅ MineController 用户数据初始化完成', tag: 'MineController');
    } catch (e) {
      logError('❌ MineController 用户数据初始化失败: $e', tag: 'MineController');
    }
  }

  /// 加载用户信息（兼容性保持）
  void _loadUserInfo() {
    final user = _authService.currentUser;
    if (user != null) {
      // 设置兼容性字段
      loginId.value = user.waiterId?.toString() ?? '未知ID';
      
      // 始终更新用户信息，确保登录新账号时能正确显示
      nickname.value = user.waiterName ?? '未知用户';
      account.value = user.waiterId?.toString() ?? '未知ID';
      
      // 如果API还没有加载，先使用默认值
      if (storeName.value.isEmpty) {
        storeName.value = '未知餐馆';
        authExpireDate.value = '未知到期时间';
        surplusDays.value = 0;
      }
    } else {
      nickname.value = '未登录';
      loginId.value = '未登录';
      account.value = '未登录';
      storeName.value = '未登录';
      authExpireDate.value = '未登录';
      surplusDays.value = 0;
    }
  }

  /// 加载服务员详细信息
  Future<void> _loadWaiterInfo() async {
    try {
      isLoading.value = true;
      
      // 确保AuthService已准备好
      if (!_authService.isLoggedIn) {
        logDebug('⚠️ 用户未登录，跳过服务员信息加载', tag: 'MineController');
        return;
      }
      
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
        // 如果API失败，至少保持从AuthService获取的基本信息
        _ensureBasicUserInfo();
      }
    } catch (e) {
      logDebug('❌ 服务员信息加载异常: $e', tag: 'MineController');
      // 如果API异常，至少保持从AuthService获取的基本信息
      _ensureBasicUserInfo();
    } finally {
      isLoading.value = false;
    }
  }

  /// 确保基本用户信息不为空
  void _ensureBasicUserInfo() {
    final user = _authService.currentUser;
    if (user != null) {
      // 如果昵称为空，使用AuthService中的信息
      if (nickname.value.isEmpty) {
        nickname.value = user.waiterName ?? '未知用户';
      }
      if (account.value.isEmpty) {
        account.value = user.waiterId?.toString() ?? '未知ID';
      }
      logDebug('✅ 已确保基本用户信息: ${nickname.value}', tag: 'MineController');
    }
  }

  /// 刷新用户信息
  Future<void> refreshUserInfo() async {
    try {
      logDebug('🔄 开始刷新用户信息...', tag: 'MineController');
      
      // 先刷新AuthService中的用户信息
      await _authService.refreshUserInfo();
      
      // 重新加载用户信息
      _loadUserInfo();
      
      // 重新加载服务员详细信息
      await _loadWaiterInfo();
      
      logDebug('✅ 用户信息刷新完成', tag: 'MineController');
    } catch (e) {
      logError('❌ 刷新用户信息失败: $e', tag: 'MineController');
      // 即使刷新失败，也确保基本信息不为空
      _ensureBasicUserInfo();
    }
  }

  // 处理点击事件的业务逻辑
  void onTapLoginOut() async {
    try {
      // 显示确认对话框
      final confirm = await ModalUtils.showConfirmDialog(
        context: Get.context!,
        message: Get.context!.l10n.areYouSureToLogout,
        confirmText:  Get.context!.l10n.confirm,
        cancelText: Get.context!.l10n.cancel,
        confirmColor: Color(0xFFFF9027),
      );
      
      if (confirm != true) return;
      
      logDebug('🔓 开始退出登录...', tag: 'MineController');
      
      // 清理所有相关的Controller和缓存数据
      await _clearAllCacheData();
      
      // 清除登录信息缓存
      await _authService.logout();
      
      // 进入登录页面，不清除输入框内容
      Get.offAll(() => LoginPage());
      
      ToastUtils.showSuccess(Get.context!, Get.context!.l10n.success);
      
      logDebug('✅ 退出登录成功', tag: 'MineController');
      
    } catch (e) {
      // 关闭加载对话框
      Get.back();
      ToastUtils.showError(Get.context!, '${Get.context!.l10n.failed}: $e');
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
