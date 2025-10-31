import 'package:get/get.dart';
import 'package:lib_base/logging/logging.dart';
import 'package:lib_domain/api/base_api.dart';
import 'package:lib_domain/entrity/home/lobby_list_model/lobby_list_model.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:lib_domain/entrity/table/close_reason_model.dart';

/// 并桌/关桌/撤桌页面的业务逻辑控制器
/// 职责：数据获取、状态管理、业务逻辑处理
class MergeTablesController extends GetxController {
  final BaseApi _baseApi = BaseApi();
  
  // 操作类型
  String? operationType;

  // ==================== 状态变量 ====================
  
  // 大厅数据
  var lobbyListModel = LobbyListModel(halls: []).obs;
  
  // Tab 数据列表
  var tabDataList = <RxList<TableListModel>>[].obs;
  
  // 当前选中的 tab
  var selectedTab = 0.obs;
  
  // 加载状态
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;
  
  // 预加载相关
  var preloadedTabs = <int>{}.obs;
  var preloadingTabs = <int>{}.obs;
  final int maxPreloadRange = 1;
  
  // 关桌原因相关
  var closeReasonList = <CloseReasonModel>[].obs;
  var selectedCloseReason = Rx<CloseReasonModel?>(null);
  var isLoadingCloseReasons = false.obs;
  var isReasonDrawerVisible = false.obs;

  // ==================== 数据加载方法 ====================

  /// 初始化数据
  Future<void> initializeData() async {
    // 根据操作类型设置 query_type：
    // 1=可合并的列表, 2=可换桌的列表, 3=合并的桌台列表, 4=待结账, 5=可关桌
    String? queryType;
    if (operationType == 'merge') {
      queryType = "1"; // 并桌：可合并的列表
    } else if (operationType == 'remove') {
      queryType = "3"; // 撤桌：合并的桌台列表
    } else if (operationType == 'close') {
      queryType = "5"; // 关桌：可关桌
    }
    
    // 获取大厅列表
    isLoading.value = true;
    try {
      final result = await _baseApi.getLobbyList(queryType: queryType);
      if (result.isSuccess && result.data != null) {
        lobbyListModel.value = result.data!;
        final halls = lobbyListModel.value.halls ?? [];
        
        // 初始化tabDataList
        tabDataList.value = List.generate(
          halls.length,
          (_) => <TableListModel>[].obs,
        );
        
        logDebug('✅ 大厅列表获取成功: ${halls.length} 个大厅, queryType=$queryType');
      } else {
        hasError.value = true;
        errorMessage.value = result.msg ?? '获取大厅列表失败';
        logError('❌ 大厅列表获取失败: ${result.msg}');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = '网络连接异常，请检查网络后重试';
      logError('❌ 大厅列表获取异常: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 获取指定tab的数据
  Future<void> fetchDataForTab(int index) async {
    if (index >= tabDataList.length) return;

    // 检查大厅数据是否有效
    if (lobbyListModel.value.halls == null ||
        lobbyListModel.value.halls!.isEmpty ||
        index >= lobbyListModel.value.halls!.length) {
      hasError.value = true;
      errorMessage.value = '大厅数据无效或索引越界';
      tabDataList[index].value = [];
      return;
    }

    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final hallId = lobbyListModel.value.halls![index].hallId.toString();
      // 根据操作类型设置 query_type：并桌=1, 撤桌=3, 关桌=5
      String queryType = "1"; // 默认为并桌
      if (operationType == 'close') {
        queryType = "5"; // 关桌：可关桌
      } else if (operationType == 'remove') {
        queryType = "3"; // 撤桌：合并的桌台列表
      }
      logDebug('🔄 合并桌台页面获取tab $index 数据: hallId=$hallId, queryType=$queryType');

      final result = await _baseApi.getTableList(
        hallId: hallId,
        queryType: queryType,
      );

      if (result.isSuccess) {
        List<TableListModel> data = result.data!;
        tabDataList[index].value = data;
        hasError.value = false;
        preloadedTabs.add(index);
      } else {
        hasError.value = true;
        errorMessage.value = result.msg ?? '数据加载失败';
        tabDataList[index].value = [];
        preloadedTabs.remove(index);
        logError('❌ 合并桌台页面Tab $index 数据获取失败: ${result.msg}');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = '网络连接异常，请检查网络后重试';
      tabDataList[index].value = [];
      preloadedTabs.remove(index);
      logError('❌ 合并桌台页面Tab $index 数据获取异常: $e');
    }

    isLoading.value = false;

    // 当前tab加载完成后，预加载相邻tab
    preloadAdjacentTabs(index);
  }

  /// 预加载相邻tab的数据
  void preloadAdjacentTabs(int currentIndex) {
    final totalTabs = lobbyListModel.value.halls?.length ?? 0;
    if (totalTabs <= 1) return;

    final startIndex = (currentIndex - maxPreloadRange).clamp(0, totalTabs - 1);
    final endIndex = (currentIndex + maxPreloadRange).clamp(0, totalTabs - 1);

    for (int i = startIndex; i <= endIndex; i++) {
      if (i != currentIndex &&
          i < tabDataList.length &&
          !preloadedTabs.contains(i) &&
          !preloadingTabs.contains(i)) {
        _preloadTabData(i);
      }
    }
  }

  /// 预加载指定tab的数据
  Future<void> _preloadTabData(int index) async {
    if (index >= tabDataList.length) return;

    if (lobbyListModel.value.halls == null ||
        lobbyListModel.value.halls!.isEmpty ||
        index >= lobbyListModel.value.halls!.length) {
      logError('❌ 合并桌台页面预加载tab $index 失败: 大厅数据无效或索引越界');
      return;
    }

    preloadingTabs.add(index);

    try {
      final hallId = lobbyListModel.value.halls![index].hallId.toString();
      // 根据操作类型设置 query_type：并桌=1, 撤桌=3, 关桌=5
      String queryType = "1"; // 默认为并桌
      if (operationType == 'close') {
        queryType = "5"; // 关桌：可关桌
      } else if (operationType == 'remove') {
        queryType = "3"; // 撤桌：合并的桌台列表
      }
      logDebug('🔄 合并桌台页面预加载tab $index 数据: hallId=$hallId, queryType=$queryType');

      final result = await _baseApi.getTableList(
        hallId: hallId,
        queryType: queryType,
      );

      if (result.isSuccess) {
        List<TableListModel> data = result.data!;
        tabDataList[index].value = data;
        preloadedTabs.add(index);
        logDebug('✅ 合并桌台页面预加载tab $index 数据成功，桌台数量: ${data.length}');
      } else {
        logError('❌ 合并桌台页面预加载tab $index 数据失败: ${result.msg}');
      }
    } catch (e) {
      logError('❌ 合并桌台页面预加载tab $index 数据异常: $e');
    } finally {
      preloadingTabs.remove(index);
    }
  }

  /// 处理tab切换
  void handleTabSwitch(int index) {
    selectedTab.value = index;
    
    if (preloadedTabs.contains(index)) {
      logDebug('并桌页面Tab $index 已预加载，直接显示数据');
      preloadAdjacentTabs(index);
    } else {
      logDebug('并桌页面Tab $index 未预加载，开始加载数据');
      fetchDataForTab(index);
    }
  }

  // ==================== 关桌原因相关 ====================

  /// 加载关桌原因列表
  Future<void> loadCloseReasons() async {
    isLoadingCloseReasons.value = true;
    try {
      final result = await _baseApi.getCloseReasonOptions();
      if (result.isSuccess && result.data != null) {
        closeReasonList.value = result.data!;
        // 默认选中第一个原因
        if (closeReasonList.isNotEmpty) {
          selectedCloseReason.value = closeReasonList.first;
        }
        logDebug('✅ 关桌原因列表加载成功: ${result.data!.length} 条');
      } else {
        logError('❌ 关桌原因列表加载失败: ${result.msg}');
      }
    } catch (e) {
      logError('❌ 关桌原因列表加载异常: $e');
    } finally {
      isLoadingCloseReasons.value = false;
    }
  }

  /// 切换原因选择抽屉显示/隐藏
  void toggleReasonDrawer() {
    isReasonDrawerVisible.value = !isReasonDrawerVisible.value;
  }

  /// 隐藏原因选择抽屉
  void hideReasonDrawer() {
    isReasonDrawerVisible.value = false;
  }

  // ==================== 辅助方法 ====================

  /// 判断是否有数据
  bool get hasData {
    final currentTabIndex = selectedTab.value;
    if (currentTabIndex < tabDataList.length) {
      return tabDataList[currentTabIndex].isNotEmpty;
    }
    return false;
  }

  /// 判断是否应该显示骨架屏
  bool get shouldShowSkeleton => !hasData;
}

