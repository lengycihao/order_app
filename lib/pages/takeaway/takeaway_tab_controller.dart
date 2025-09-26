import 'package:get/get.dart';
import 'package:lib_base/logging/logging.dart';

/// 外卖页面Tab控制器
/// 用于管理外卖页面的tab切换状态
class TakeawayTabController extends GetxController {
  // 当前选中的tab索引
  final RxInt currentTabIndex = 0.obs;
  
  // 是否正在切换tab
  final RxBool isSwitching = false.obs;
  
  /// 切换到指定tab
  /// [tabIndex] 0: 未结账, 1: 已结账
  void switchToTab(int tabIndex) {
    if (tabIndex >= 0 && tabIndex <= 1) {
      isSwitching.value = true;
      currentTabIndex.value = tabIndex;
      
      // 延迟重置切换状态
      Future.delayed(const Duration(milliseconds: 100), () {
        isSwitching.value = false;
      });
      
      logDebug('外卖页面切换到tab: $tabIndex', tag: 'TakeawayTabController');
    }
  }
  
  /// 切换到未结账tab
  void switchToPendingTab() {
    switchToTab(0);
  }
  
  /// 切换到已结账tab
  void switchToConfirmedTab() {
    switchToTab(1);
  }
}
