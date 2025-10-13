import 'package:get/get.dart';
import 'package:order_app/pages/nav/screen_nav_page.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/pages/order/order_main_page.dart';
import 'package:order_app/pages/table/table_controller.dart';

/// 导航管理器 - 统一管理页面导航和返回逻辑
class NavigationManager {
  static NavigationManager? _instance;
  static NavigationManager get instance => _instance ??= NavigationManager._();
  
  NavigationManager._();
  
  /// 从点餐页面返回到桌台页面
  /// 返回到主页面（包含底部导航栏），并切换到桌台页面
  static Future<void> backToTablePage() async {
    try {
      // 清理OrderController及其WebSocket连接
      if (Get.isRegistered<OrderController>()) {
        // OrderController的onClose方法会自动处理WebSocket清理
        Get.delete<OrderController>();
        print('✅ OrderController已清理，WebSocket连接已断开');
      }
      
      // 清理OrderMainPageController
      if (Get.isRegistered<OrderMainPageController>()) {
        Get.delete<OrderMainPageController>();
        print('✅ OrderMainPageController已清理');
      }
    } catch (e) {
      print('⚠️ 清理Controller时出现异常: $e');
    }
    
    // 返回到主页面（包含底部导航栏）- 添加过渡动画
    Get.offAll(
      () => ScreenNavPage(),
      transition: Transition.fadeIn,
      duration: Duration(milliseconds: 300),
    );
    
    // 等待页面构建完成
    await Future.delayed(Duration(milliseconds: 500));
    
    // 执行隐式刷新，不显示骨架图
    await _performImplicitRefresh();
    
    print('✅ 返回桌台页面，执行隐式刷新完成');
  }
  
  /// 执行隐式刷新桌台数据
  /// 不显示加载状态和骨架图，静默更新数据
  static Future<void> _performImplicitRefresh() async {
    try {
      // 等待TableController初始化完成 - 增加等待时间和重试次数
      int retryCount = 0;
      const maxRetries = 20; // 增加重试次数
      
      while (retryCount < maxRetries) {
        try {
          final tableController = Get.find<TableControllerRefactored>();
          
          // 检查控制器是否已初始化且有数据
          if (tableController.lobbyListModel.value.halls != null && 
              tableController.lobbyListModel.value.halls!.isNotEmpty) {
            print('✅ TableController已初始化且有大厅数据，开始隐式刷新');
            break;
          }
        } catch (e) {
          // TableController还未初始化，继续等待
        }
        
        await Future.delayed(Duration(milliseconds: 200)); // 增加等待间隔
        retryCount++;
      }
      
      if (retryCount >= maxRetries) {
        print('⚠️ TableController初始化超时，尝试强制刷新');
        // 即使超时也尝试获取控制器并强制刷新
        try {
          final tableController = Get.find<TableControllerRefactored>();
          await tableController.forceResetAllData();
          print('✅ 强制刷新完成');
          return;
        } catch (e) {
          print('❌ 强制刷新也失败: $e');
          return;
        }
      }
      
      // 获取TableController
      final tableController = Get.find<TableControllerRefactored>();
      
      // 检查是否需要重新加载数据（数据为空时）
      final halls = tableController.lobbyListModel.value.halls ?? [];
      if (halls.isEmpty) {
        print('🔄 检测到大厅数据为空，开始重新加载...');
        await tableController.getLobbyList();
        
        // 重新获取大厅数据
        final updatedHalls = tableController.lobbyListModel.value.halls ?? [];
        if (updatedHalls.isEmpty) {
          print('⚠️ 重新加载后大厅数据仍为空');
          return;
        }
      }
      
      // 获取当前选中的tab索引
      final currentTabIndex = tableController.selectedTab.value;
      final updatedHalls = tableController.lobbyListModel.value.halls ?? [];
      
      // 确保tab索引有效
      if (currentTabIndex >= updatedHalls.length) {
        print('⚠️ Tab索引无效: $currentTabIndex >= ${updatedHalls.length}，重置为0');
        tableController.selectedTab.value = 0;
      }
      
      // 检查当前tab的数据是否为空
      final finalTabIndex = tableController.selectedTab.value;
      if (finalTabIndex < tableController.tabDataList.length) {
        final currentTabData = tableController.tabDataList[finalTabIndex];
        if (currentTabData.isEmpty) {
          print('🔄 检测到当前tab数据为空，开始加载...');
          await tableController.fetchDataForTab(finalTabIndex);
        } else {
          print('🔄 当前tab已有数据，执行隐式刷新...');
          await tableController.refreshDataForTab(finalTabIndex);
        }
      } else {
        print('🔄 Tab数据结构不匹配，开始加载当前tab...');
        await tableController.fetchDataForTab(finalTabIndex);
      }
      
      // 启动轮询功能
      try {
        tableController.startPolling();
        print('🔄 轮询已启动');
      } catch (e) {
        print('⚠️ 启动轮询失败: $e');
      }
      
      print('✅ 桌台数据隐式刷新完成 - Tab: $finalTabIndex');
    } catch (e) {
      print('⚠️ 隐式刷新桌台数据失败: $e');
      // 如果TableController不存在，说明是首次进入，不需要刷新
    }
  }
  
  /// 从选择菜单页面跳转到点餐页面
  /// 替换当前页面，避免导航栈堆积
  static void goToOrderPage(dynamic page, {Map<String, dynamic>? arguments}) {
    // 先清理可能存在的OrderController实例，确保使用新的数据
    if (Get.isRegistered<OrderController>()) {
      Get.delete<OrderController>();
      print('✅ 清理旧的OrderController实例');
    }
    
    // 清理OrderMainPageController
    if (Get.isRegistered<OrderMainPageController>()) {
      Get.delete<OrderMainPageController>();
      print('✅ 清理旧的OrderMainPageController实例');
    }
    
    // 等待清理完成后再跳转
    Future.delayed(Duration(milliseconds: 100), () {
      Get.off(page, arguments: arguments);
    });
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
  
  /// 刷新桌台数据（用于外卖订单提交成功后）
  static Future<void> refreshTableData() async {
    try {
      // 检查TableController是否存在
      if (Get.isRegistered<TableControllerRefactored>()) {
        final tableController = Get.find<TableControllerRefactored>();
        
        // 首先确保大厅数据是最新的
        await tableController.getLobbyList();
        
        // 检查大厅数据是否有效
        final halls = tableController.lobbyListModel.value.halls ?? [];
        if (halls.isEmpty) {
          print('⚠️ 大厅数据为空，跳过桌台数据刷新');
          return;
        }
        
        // 获取当前选中的tab索引
        final currentTabIndex = tableController.selectedTab.value;
        
        // 确保tab索引有效
        if (currentTabIndex >= halls.length) {
          print('⚠️ Tab索引无效: $currentTabIndex >= ${halls.length}');
          return;
        }
        
        // 执行隐式刷新当前tab的数据
        await tableController.refreshDataForTab(currentTabIndex);
        
        print('✅ 桌台数据刷新完成 - Tab: $currentTabIndex');
      } else {
        print('⚠️ TableController不存在，跳过数据刷新');
      }
    } catch (e) {
      print('⚠️ 刷新桌台数据失败: $e');
    }
  }
}
