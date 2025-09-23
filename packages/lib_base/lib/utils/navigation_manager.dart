import 'package:get/get.dart';
import 'package:order_app/pages/table/table_controller.dart';
import 'package:order_app/pages/nav/screen_nav_page.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/pages/order/order_main_page.dart';

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
    await Future.delayed(Duration(milliseconds: 300));
    
    // 不刷新数据，直接显示现有数据，避免骨架图闪烁
    // 如果需要刷新数据，可以在用户主动下拉刷新时进行
    print('✅ 返回桌台页面，保持现有数据显示');
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
