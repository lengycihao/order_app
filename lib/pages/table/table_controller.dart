import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:lib_domain/entrity/home/lobby_list_model/lobby_list_model.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:order_app/cons/table_status.dart';
import 'package:lib_base/utils/websocket_manager.dart';
import 'package:order_app/pages/table/sub_page/merge_tables_page.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:lib_base/logging/logging.dart';

// 导入服务模块
import 'services/table_data_service.dart';
import 'services/table_preload_manager.dart';
import 'services/table_polling_manager.dart';
import 'services/table_websocket_manager.dart';

/// 重构后的桌台控制器
/// 使用服务模块进行职责分离
class TableControllerRefactored extends GetxController {
  final String _logTag = 'TableControllerRefactored';
  
  // 基础状态
  var selectedTab = 0.obs;
  var tabDataList = <RxList<TableListModel>>[].obs;
  var lobbyListModel = LobbyListModel(halls: []).obs;
  late List<TableMenuListModel> menuModelList = [];
  PageController pageController = PageController();
  ScrollController tabScrollController = ScrollController();
  var isLoading = false.obs;
  var isMergeMode = false.obs;
  var selectedTables = <String>[].obs;
  var hasNetworkError = false.obs;
  
  // 服务模块
  late final TableDataService _dataService;
  late final TablePreloadManager _preloadManager;
  late final TablePollingManager _pollingManager;
  late final TableWebSocketManager _wsManager;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _loadInitialData();
  }

  /// 初始化服务模块
  void _initializeServices() {
    _dataService = TableDataService();
    _preloadManager = TablePreloadManager(dataService: _dataService);
    _pollingManager = TablePollingManager();
    _wsManager = TableWebSocketManager(wsManager: wsManager);
    
    // 设置轮询回调
    _pollingManager.startPolling(onPolling: _performPollingRefresh);
    
    // 初始化WebSocket状态监控
    _wsManager.initializeStatusMonitoring();
    
    logDebug('✅ 服务模块初始化完成', tag: _logTag);
  }

  /// 加载初始数据
  Future<void> _loadInitialData() async {
    await getLobbyList();
    await getMenuList();
  }

  /// 获取大厅列表
  Future<void> getLobbyList() async {
    // 保存之前的网络错误状态，用于判断是否需要保持网络错误显示
    final hadPreviousError = hasNetworkError.value;
    
    try {
      final result = await _dataService.getLobbyList();
      if (result.isSuccess && result.data != null) {
        lobbyListModel.value = result.data!;
        // 初始化 tabDataList
        tabDataList.value = List.generate(
          lobbyListModel.value.halls?.length ?? 0,
          (_) => <TableListModel>[].obs,
        );
        // 清空预加载状态
        _preloadManager.clearPreloadStatus();
        
        // 只有当确实有大厅数据时，才清除网络错误状态
        if (lobbyListModel.value.halls?.isNotEmpty == true) {
          hasNetworkError.value = false;
          // 获取第一个 tab 数据
          fetchDataForTab(0);
          logDebug('✅ 大厅数据获取成功', tag: _logTag);
        } else {
          // 如果之前有网络错误，且现在返回空数据，保持网络错误状态
          // 这通常表示网络问题导致的数据缺失，而不是真的没有数据
          if (hadPreviousError) {
            hasNetworkError.value = true;
            logError('❌ 大厅数据为空，可能是网络问题导致', tag: _logTag);
          } else {
            hasNetworkError.value = false;
            logDebug('✅ 大厅数据获取成功，但暂无大厅', tag: _logTag);
          }
        }
      } else {
        hasNetworkError.value = true;
        logError('❌ 大厅数据获取失败: ${result.msg}', tag: _logTag);
      }
    } catch (e) {
      hasNetworkError.value = true;
      logError('❌ 大厅数据获取异常: $e', tag: _logTag);
    }
  }

  /// 获取菜单列表
  Future<void> getMenuList() async {
    final result = await _dataService.getMenuList();
    if (result.isSuccess && result.data != null) {
      menuModelList = result.data!;
      logDebug('✅ 菜单数据已更新: ${menuModelList.length} 个菜单', tag: _logTag);
    } else {
      logDebug('❌ 获取菜单数据失败: ${result.msg}', tag: _logTag);
    }
  }
  
  /// 强制刷新菜单数据
  Future<void> refreshMenuList() async {
    logDebug('🔄 强制刷新菜单数据...', tag: _logTag);
    await getMenuList();
  }

  /// 强制重置所有数据（用于账号切换后的数据清理）
  Future<void> forceResetAllData() async {
    logDebug('🔄 TableController: 开始强制重置所有数据...', tag: _logTag);
    
    // 清空所有数据
    tabDataList.clear();
    lobbyListModel.value = LobbyListModel(halls: []);
    menuModelList.clear();
    selectedTab.value = 0;
    isLoading.value = false;
    hasNetworkError.value = false;
    
    // 重新加载数据
    await getLobbyList();
    await getMenuList();
    
    logDebug('✅ TableController: 强制重置所有数据完成', tag: _logTag);
  }

  /// 获取指定tab的数据
  Future<void> fetchDataForTab(int index) async {
    if (index >= tabDataList.length) return;
    
    // 检查大厅数据是否有效
    if (lobbyListModel.value.halls == null || 
        lobbyListModel.value.halls!.isEmpty || 
        index >= lobbyListModel.value.halls!.length) {
      logError('❌ 获取tab $index 数据失败: 大厅数据无效或索引越界', tag: _logTag);
      hasNetworkError.value = true;
      return;
    }
    
    isLoading.value = true;
    hasNetworkError.value = false;
    
    try {
      final hallId = lobbyListModel.value.halls![index].hallId.toString();
      logDebug('🔄 获取tab $index 数据: hallId=$hallId', tag: _logTag);
          
      final result = await _dataService.getTableList(hallId);
      if (result.isSuccess) {
        List<TableListModel> data = result.data!;
        tabDataList[index].value = data;
        hasNetworkError.value = false;
        // 标记为已预加载
        _preloadManager.preloadedTabs.add(index);
        logDebug('✅ Tab $index 数据获取成功，桌台数量: ${data.length}', tag: _logTag);
      } else {
        hasNetworkError.value = true;
        logError('❌ Tab $index 数据获取失败: ${result.msg}', tag: _logTag);
      }
    } catch (e) {
      hasNetworkError.value = true;
      logError('❌ Tab $index 数据获取异常: $e', tag: _logTag);
    } finally {
      isLoading.value = false;
    }
    
    // 当前tab加载完成后，预加载相邻tab
    _preloadManager.preloadAdjacentTabs(
      currentIndex: index,
      totalTabs: lobbyListModel.value.halls?.length ?? 0,
      lobbyListModel: lobbyListModel.value,
      tabDataList: tabDataList,
      onDataLoaded: (loadedIndex) {
        logDebug('✅ Tab $loadedIndex 数据加载完成', tag: _logTag);
      },
    );
  }

  /// 隐式刷新数据（不显示加载状态）
  Future<void> refreshDataForTab(int index) async {
    if (index >= tabDataList.length) return;
    
    // 检查大厅数据是否有效
    if (lobbyListModel.value.halls == null || 
        lobbyListModel.value.halls!.isEmpty || 
        index >= lobbyListModel.value.halls!.length) {
      logError('❌ 刷新tab $index 数据失败: 大厅数据无效或索引越界', tag: _logTag);
      hasNetworkError.value = true;
      return;
    }
    
    hasNetworkError.value = false;
    
    try {
      final hallId = lobbyListModel.value.halls![index].hallId.toString();
      logDebug('🔄 刷新tab $index 数据: hallId=$hallId', tag: _logTag);
          
      final result = await _dataService.getTableList(hallId);
      if (result.isSuccess) {
        List<TableListModel> data = result.data!;
        tabDataList[index].value = data;
        hasNetworkError.value = false;
        // 标记为已预加载
        _preloadManager.preloadedTabs.add(index);
        logDebug('✅ Tab $index 数据刷新成功，桌台数量: ${data.length}', tag: _logTag);
      } else {
        hasNetworkError.value = true;
        logError('❌ Tab $index 数据刷新失败: ${result.msg}', tag: _logTag);
      }
    } catch (e) {
      hasNetworkError.value = true;
      logError('❌ Tab $index 数据刷新异常: $e', tag: _logTag);
    }
  }

  /// Tab点击事件
  void onTabTapped(int index) {
    selectedTab.value = index;
    pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _handleTabSwitch(index);
  }

  /// 页面变化事件
  void onPageChanged(int index) {
    selectedTab.value = index;
    _handleTabSwitch(index);
    // 滚动tab到可视区域
    _scrollToTab(index);
  }

  /// 处理tab切换逻辑
  void _handleTabSwitch(int index) {
    // 如果该tab已经预加载过，直接显示数据，不需要重新加载
    if (_preloadManager.isTabPreloaded(index)) {
      logDebug('✅ Tab $index 已预加载，直接显示数据', tag: _logTag);
      // 预加载相邻tab
      _preloadManager.preloadAdjacentTabs(
        currentIndex: index,
        totalTabs: lobbyListModel.value.halls?.length ?? 0,
        lobbyListModel: lobbyListModel.value,
        tabDataList: tabDataList,
        onDataLoaded: (loadedIndex) {
          logDebug('✅ Tab $loadedIndex 数据加载完成', tag: _logTag);
        },
      );
    } else {
      // 如果该tab没有预加载过，正常加载
      logDebug('🔄 Tab $index 未预加载，开始加载数据', tag: _logTag);
      fetchDataForTab(index);
    }
  }

  /// 切换并桌模式
  void toggleMergeMode() {
    if (!isMergeMode.value) {
      // 进入并桌模式，跳转到并桌页面
      _navigateToMergePage().then((_) {
        // 导航完成后的处理
      });
    } else {
      // 退出并桌模式
      isMergeMode.value = false;
      selectedTables.clear();
    }
  }

  /// 跳转到并桌页面
  Future<void> _navigateToMergePage() async {
    // 准备所有tab的桌台数据
    List<List<TableListModel>> allTabTables = [];
    for (var tabData in tabDataList) {
      allTabTables.add(tabData);
    }

    // 跳转到并桌页面
    final result = await Get.to(
      () => MergeTablesPage(
        allTabTables: allTabTables,
        menuModelList: menuModelList,
        lobbyListModel: lobbyListModel.value,
        hasInitialNetworkError: hasNetworkError.value,
      ),
    );
    
    // 如果返回值为true，表示需要重新加载数据
    if (result == true) {
      logDebug('并桌页面返回，需要重新加载数据', tag: _logTag);
      await getLobbyList();
    }
  }

  /// 切换桌台选中状态
  void toggleTableSelected(String tableId) {
    if (selectedTables.contains(tableId)) {
      selectedTables.remove(tableId);
    } else {
      selectedTables.add(tableId);
    }
  }

  /// 更改桌台状态
  Future<void> changeTableStatus({
    required int tableId,
    required TableStatus newStatus,
  }) async {
    try {
      final result = await _dataService.changeTableStatus(
        tableId: tableId,
        status: newStatus.index,
      );

      if (result.isSuccess) {
        GlobalToast.success('桌台状态更新成功');
        // 刷新当前tab的桌台数据
        await fetchDataForTab(selectedTab.value);
      } else {
        GlobalToast.error(result.msg ?? '状态更新失败');
      }
    } catch (e) {
      // 关闭加载对话框
      Get.back();
      GlobalToast.error('网络错误: $e');
    }
  }

  /// 执行轮询刷新
  Future<void> _performPollingRefresh() async {
    // 如果当前正在加载，跳过本次轮询
    if (isLoading.value) return;
    
    // 检查大厅数据是否有效
    if (lobbyListModel.value.halls == null || 
        lobbyListModel.value.halls!.isEmpty) {
      logDebug('⚠️ 轮询刷新跳过: 大厅数据无效', tag: _logTag);
      return;
    }
    
    // 确保选中的tab索引有效
    final currentTabIndex = selectedTab.value.clamp(0, lobbyListModel.value.halls!.length - 1);
    if (currentTabIndex != selectedTab.value) {
      selectedTab.value = currentTabIndex;
      logDebug('🔄 轮询刷新: 调整选中tab索引为 $currentTabIndex', tag: _logTag);
    }
    
    // 刷新当前选中的tab数据
    await refreshDataForTab(currentTabIndex);
    
    // 同时刷新已预加载的相邻tab数据
    _preloadManager.refreshPreloadedTabs(
      currentIndex: currentTabIndex,
      totalTabs: lobbyListModel.value.halls!.length,
      lobbyListModel: lobbyListModel.value,
      tabDataList: tabDataList,
      onDataLoaded: (loadedIndex) {
        logDebug('✅ Tab $loadedIndex 轮询刷新完成', tag: _logTag);
      },
    );
  }

  /// 启动轮询
  void startPolling() {
    _pollingManager.resumePolling(onPolling: _performPollingRefresh);
  }

  /// 停止轮询
  void stopPolling() {
    _pollingManager.pausePolling();
  }

  /// 暂停轮询（页面不可见时调用）
  void pausePolling() {
    _pollingManager.pausePolling();
  }

  /// 恢复轮询（页面可见时调用）
  void resumePolling() {
    _pollingManager.resumePolling(onPolling: _performPollingRefresh);
  }

  /// 获取WebSocket连接统计信息
  Map<String, dynamic> getWebSocketStats() {
    return _wsManager.getConnectionStats();
  }

  /// 获取预加载状态信息
  Map<String, dynamic> getPreloadStatus() {
    return _preloadManager.getPreloadStatus();
  }

  /// 检查指定tab是否已预加载
  bool isTabPreloaded(int index) {
    return _preloadManager.isTabPreloaded(index);
  }

  /// 检查指定tab是否正在预加载
  bool isTabPreloading(int index) {
    return _preloadManager.isTabPreloading(index);
  }

  /// 手动触发预加载（用于测试或特殊场景）
  void triggerPreload(int index) {
    _preloadManager.triggerPreload(
      index: index,
      lobbyListModel: lobbyListModel.value,
      tabDataList: tabDataList,
      onDataLoaded: (loadedIndex) {
        logDebug('✅ 手动预加载 Tab $loadedIndex 完成', tag: _logTag);
      },
    );
  }

  /// 滚动tab到屏幕中间
  void _scrollToTab(int index) {
    if (!tabScrollController.hasClients) return;
    
    // 获取总tab数量
    int totalTabs = lobbyListModel.value.halls?.length ?? 0;
    if (totalTabs == 0) return;
    
    // 计算目标tab在总宽度中的比例位置
    double tabRatio = index / (totalTabs - 1).clamp(1, double.infinity);
    
    // 计算目标滚动位置，让选中的tab显示在屏幕中央
    double maxScrollPosition = tabScrollController.position.maxScrollExtent;
    double targetScrollPosition = maxScrollPosition * tabRatio;
    
    // 确保滚动位置在有效范围内
    targetScrollPosition = targetScrollPosition.clamp(0.0, maxScrollPosition);
    
    // 执行滚动动画
    tabScrollController.animateTo(
      targetScrollPosition,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void onClose() {
    // 清理服务模块
    _pollingManager.dispose();
    _preloadManager.dispose();
    _wsManager.dispose();
    
    // 清理ScrollController
    tabScrollController.dispose();
    
    logDebug('✅ TableControllerRefactored 已销毁', tag: _logTag);
    super.onClose();
  }
}
