import 'package:get/get.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:lib_base/logging/logging.dart';

/// 桌台页面状态管理类
/// 统一管理页面状态，减少重复代码
class TablePageState {
  final RxBool _shouldShowSkeleton = true.obs;
  final RxBool _isFromLogin = false.obs;
  final RxBool _isInitialized = false.obs;
  
  // Getters
  bool get shouldShowSkeleton => _shouldShowSkeleton.value;
  bool get isFromLogin => _isFromLogin.value;
  bool get isInitialized => _isInitialized.value;
  
  // 检查是否应该显示骨架图（不修改状态，只返回结果）
  bool shouldShowSkeletonForTab(List<RxList<TableListModel>> tabDataList, int selectedTab) {
    if (tabDataList.isNotEmpty && 
        selectedTab < tabDataList.length &&
        tabDataList[selectedTab].isNotEmpty) {
      logDebug('✅ 检测到现有数据，不显示骨架图', tag: 'TablePageState');
      return false;
    }
    logDebug('✅ 首次进入或从登录页进入，显示骨架图', tag: 'TablePageState');
    return true;
  }
  
  // 更新骨架图显示状态（在非构建时调用）
  void updateSkeletonState(List<RxList<TableListModel>> tabDataList, int selectedTab) {
    final shouldShow = shouldShowSkeletonForTab(tabDataList, selectedTab);
    if (_shouldShowSkeleton.value != shouldShow) {
      _shouldShowSkeleton.value = shouldShow;
    }
  }
  
  // 检查是否来自登录页面
  bool checkIfFromLogin(List<RxList<TableListModel>> tabDataList, dynamic lobbyListModel) {
    final isFromLogin = tabDataList.isEmpty || 
                       lobbyListModel.halls?.isEmpty == true;
    
    _isFromLogin.value = isFromLogin;
    
    if (isFromLogin) {
      logDebug('✅ 检测到需要刷新数据（新登录或数据为空）', tag: 'TablePageState');
    }
    
    return isFromLogin;
  }
  
  // 标记为已初始化
  void markAsInitialized() {
    _isInitialized.value = true;
  }
  
  // 重置状态
  void reset() {
    _shouldShowSkeleton.value = true;
    _isFromLogin.value = false;
    _isInitialized.value = false;
  }
}
