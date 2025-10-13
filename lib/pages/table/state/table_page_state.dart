import 'package:get/get.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:lib_base/logging/logging.dart';

/// 桌台页面状态管理类
/// 统一管理页面状态，减少重复代码
class TablePageState {
  final RxBool _shouldShowSkeleton = true.obs;
  final RxBool _isFromLogin = false.obs;
  final RxBool _isInitialized = false.obs;
  final RxBool _isLoginInitialLoading = false.obs; // 新增：登录后的初始加载状态
  
  // Getters
  bool get shouldShowSkeleton => _shouldShowSkeleton.value;
  bool get isFromLogin => _isFromLogin.value;
  bool get isInitialized => _isInitialized.value;
  bool get isLoginInitialLoading => _isLoginInitialLoading.value; // 新增getter
  
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
    // 检查是否是从点餐页面返回（通过检查是否有部分数据但结构不完整）
    final hasPartialData = tabDataList.isNotEmpty && 
                          lobbyListModel.halls != null && 
                          lobbyListModel.halls!.isNotEmpty;
    
    // 只有在完全没有数据时才认为是来自登录页面
    final isFromLogin = tabDataList.isEmpty && 
                       (lobbyListModel.halls == null || lobbyListModel.halls!.isEmpty);
    
    _isFromLogin.value = isFromLogin;
    
    // 如果是来自登录页面，设置初始加载状态
    if (isFromLogin) {
      _isLoginInitialLoading.value = true;
      logDebug('✅ 检测到需要刷新数据（新登录或数据为空）', tag: 'TablePageState');
    } else if (hasPartialData) {
      logDebug('✅ 检测到部分数据存在，可能是从点餐页面返回', tag: 'TablePageState');
    }
    
    return isFromLogin;
  }
  
  // 完成登录后的初始加载
  void completeLoginInitialLoading() {
    _isLoginInitialLoading.value = false;
    logDebug('✅ 登录后初始加载完成', tag: 'TablePageState');
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
    _isLoginInitialLoading.value = false;
  }
}
