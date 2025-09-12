import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/table/table_page.dart';
import 'package:order_app/pages/table/table_controller.dart';

/// 导航管理器 - 统一管理页面导航和返回逻辑
class NavigationManager {
  static NavigationManager? _instance;
  static NavigationManager get instance => _instance ??= NavigationManager._();
  
  NavigationManager._();
  
  /// 从点餐页面返回到桌台页面
  /// 使用Get.offAll清空导航栈，确保返回到桌台页面
  static Future<void> backToTablePage() async {
    // 保存当前Controller状态
    final currentController = Get.find<TableController>();
    
    // 清空导航栈并返回到桌台页面
    Get.offAll(() => TablePage());
    
    // 等待页面构建完成
    await Future.delayed(Duration(milliseconds: 100));
    
    // 刷新数据
    final newController = Get.find<TableController>();
    await newController.fetchDataForTab(newController.selectedTab.value);
  }
  
  /// 从选择菜单页面跳转到点餐页面
  /// 替换当前页面，避免导航栈堆积
  static void goToOrderPage(dynamic page, {Map<String, dynamic>? arguments}) {
    Get.off(page, arguments: arguments);
  }
  
  /// 从桌台页面进入其他页面（正常导航）
  static void goToPage(dynamic page, {Map<String, dynamic>? arguments}) {
    Get.to(page, arguments: arguments);
  }
  
  /// 检查导航栈深度，防止过深的导航栈
  static void checkNavigationStack() {
    final routeCount = Get.routing.current.length;
    if (routeCount > 5) {
      print('⚠️ 导航栈过深: $routeCount 层，建议优化导航逻辑');
    }
  }
}
