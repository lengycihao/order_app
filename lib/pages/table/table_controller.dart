import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:lib_domain/entrity/home/lobby_list_model/lobby_list_model.dart';
import 'package:lib_domain/api/base_api.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:order_app/cons/table_status.dart';
import 'package:lib_base/utils/websocket_manager.dart';
import 'package:order_app/pages/table/sub_page/merge_tables_page.dart';
import 'package:order_app/utils/toast_utils.dart';

class TableController extends GetxController {
  var selectedTab = 0.obs;
  final BaseApi _baseApi = BaseApi();
  // 动态 tab 数据
  var tabDataList = <RxList<TableListModel>>[].obs;

  var lobbyListModel = LobbyListModel(halls: []).obs;
  late List<TableMenuListModel> menuModelList = [];
  PageController pageController = PageController();
  ScrollController tabScrollController = ScrollController();
  var isLoading = false.obs;
  var isMergeMode = false.obs;
  var selectedTables = <String>[].obs; // 存储选中的桌台ID或编号
  var hasNetworkError = false.obs; // 网络错误状态
  
  // WebSocket管理器
  final WebSocketManager _wsManager = wsManager;
  final isWebSocketConnected = false.obs;
  
  // 轮询定时器
  Timer? _pollingTimer;
  bool _isPollingActive = false;
  
  // 预加载相关
  var _preloadedTabs = <int>{}.obs; // 已预加载的tab索引
  var _preloadingTabs = <int>{}.obs; // 正在预加载的tab索引
  final int _maxPreloadRange = 1; // 预加载范围：前后各1个tab

  @override
  void onInit() {
    super.onInit();
    getLobbyList();
    //获取菜单列表
    getMenuList();
    // 初始化WebSocket连接状态监听
    _initializeWebSocketStatus();
    // 启动轮询
    _startPolling();
  }

  Future<void> getLobbyList() async {
    final result = await _baseApi.getLobbyList();
    if (result.isSuccess && result.data != null) {
      lobbyListModel.value = result.data!;
      // 初始化 tabDataList
      tabDataList.value = List.generate(
        lobbyListModel.value.halls?.length ?? 0,
        (_) => <TableListModel>[].obs,
      );
      // 清空预加载状态
      _preloadedTabs.clear();
      _preloadingTabs.clear();
      // 获取第一个 tab 数据
      fetchDataForTab(0);
    }
  }

  Future<void> getMenuList() async {
    final result = await _baseApi.getTableMenuList();
    if (result.isSuccess && result.data != null) {
      menuModelList = result.data!;
    }
  }

  /// 强制重置所有数据（用于账号切换后的数据清理）
  Future<void> forceResetAllData() async {
    print('🔄 TableController: 开始强制重置所有数据...');
    
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
    
    print('✅ TableController: 强制重置所有数据完成');
  }

  Future<void> fetchDataForTab(int index) async {
    if (index >= tabDataList.length) return;
    isLoading.value = true;
    hasNetworkError.value = false;
    
    try {
      final result = await _baseApi.getTableList(
        hallId: lobbyListModel.value.halls!.isNotEmpty
            ? lobbyListModel.value.halls![index].hallId.toString()
            : "0",
      );
      if (result.isSuccess) {
        List<TableListModel> data = result.data!;
        tabDataList[index].value = data;
        hasNetworkError.value = false;
        // 标记为已预加载
        _preloadedTabs.add(index);
      } else {
        hasNetworkError.value = true;
      }
    } catch (e) {
      hasNetworkError.value = true;
    } finally {
      isLoading.value = false;
    }
    
    // 当前tab加载完成后，预加载相邻tab
    _preloadAdjacentTabs(index);
  }

  /// 隐式刷新数据（不显示加载状态）
  Future<void> refreshDataForTab(int index) async {
    if (index >= tabDataList.length) return;
    hasNetworkError.value = false;
    
    try {
      final result = await _baseApi.getTableList(
        hallId: lobbyListModel.value.halls!.isNotEmpty
            ? lobbyListModel.value.halls![index].hallId.toString()
            : "0",
      );
      if (result.isSuccess) {
        List<TableListModel> data = result.data!;
        tabDataList[index].value = data;
        hasNetworkError.value = false;
        // 标记为已预加载
        _preloadedTabs.add(index);
      } else {
        hasNetworkError.value = true;
      }
    } catch (e) {
      hasNetworkError.value = true;
    }
  }

  /// 预加载相邻tab的数据
  void _preloadAdjacentTabs(int currentIndex) {
    final totalTabs = lobbyListModel.value.halls?.length ?? 0;
    if (totalTabs <= 1) return; // 只有一个tab时不需要预加载
    
    // 计算需要预加载的tab范围
    final startIndex = (currentIndex - _maxPreloadRange).clamp(0, totalTabs - 1);
    final endIndex = (currentIndex + _maxPreloadRange).clamp(0, totalTabs - 1);
    
    // 预加载范围内的tab（排除当前tab）
    for (int i = startIndex; i <= endIndex; i++) {
      if (i != currentIndex && 
          i < tabDataList.length && 
          !_preloadedTabs.contains(i) && 
          !_preloadingTabs.contains(i)) {
        _preloadTabData(i);
      }
    }
  }

  /// 预加载指定tab的数据
  Future<void> _preloadTabData(int index) async {
    if (index >= tabDataList.length) return;
    
    _preloadingTabs.add(index);
    
    try {
      final result = await _baseApi.getTableList(
        hallId: lobbyListModel.value.halls!.isNotEmpty
            ? lobbyListModel.value.halls![index].hallId.toString()
            : "0",
      );
      
      if (result.isSuccess) {
        List<TableListModel> data = result.data!;
        tabDataList[index].value = data;
        _preloadedTabs.add(index);
        print('✅ 预加载tab $index 数据成功，桌台数量: ${data.length}');
      } else {
        print('❌ 预加载tab $index 数据失败: ${result.msg}');
      }
    } catch (e) {
      print('❌ 预加载tab $index 数据异常: $e');
    } finally {
      _preloadingTabs.remove(index);
    }
  }

  // Future<List<TableModel>> fetchHallData(int index) async {
  //   await Future.delayed(Duration(milliseconds: 500));
  //   return List.generate(5, (i) => demoTable(i));
  // }

  // TableModel demoTable(int index) {
  //   return TableModel(
  //     name: '桌台-${index + 1}',
  //     people: 3,
  //     seats: 4,
  //     amount: 2,
  //     time: '1h23m',
  //     status: TableStatus.Empty,
  //   );
  // }

  void onTabTapped(int index) {
    selectedTab.value = index;
    pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _handleTabSwitch(index);
  }

  void onPageChanged(int index) {
    selectedTab.value = index;
    _handleTabSwitch(index);
    // 滚动tab到可视区域
    _scrollToTab(index);
  }

  /// 处理tab切换逻辑
  void _handleTabSwitch(int index) {
    // 如果该tab已经预加载过，直接显示数据，不需要重新加载
    if (_preloadedTabs.contains(index)) {
      print('✅ Tab $index 已预加载，直接显示数据');
      // 预加载相邻tab
      _preloadAdjacentTabs(index);
    } else {
      // 如果该tab没有预加载过，正常加载
      print('🔄 Tab $index 未预加载，开始加载数据');
      fetchDataForTab(index);
    }
  }

  void toggleMergeMode() {
    if (!isMergeMode.value) {
      // 进入并桌模式，跳转到并桌页面
      _navigateToMergePage();
    } else {
      // 退出并桌模式
      isMergeMode.value = false;
      selectedTables.clear();
    }
  }

  /// 跳转到并桌页面
  void _navigateToMergePage() {
    // 准备所有tab的桌台数据
    List<List<TableListModel>> allTabTables = [];
    for (var tabData in tabDataList) {
      allTabTables.add(tabData);
    }

    // 跳转到并桌页面
    Get.to(
      () => MergeTablesPage(
        allTabTables: allTabTables,
        menuModelList: menuModelList,
        lobbyListModel: lobbyListModel.value,
      ),
    );
  }

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
      final result = await _baseApi.changeTableStatus(
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

  /// 初始化WebSocket连接状态监听
  void _initializeWebSocketStatus() {
    // 定期检查WebSocket连接状态
    Timer.periodic(Duration(seconds: 3), (timer) {
      final stats = _wsManager.connectionStats;
      isWebSocketConnected.value = stats['total_connections'] > 0;
    });
  }

  /// 获取WebSocket连接统计信息
  Map<String, dynamic> getWebSocketStats() {
    return _wsManager.connectionStats;
  }

  /// 启动轮询
  void _startPolling() {
    if (_isPollingActive) return;
    
    _isPollingActive = true;
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _performPollingRefresh();
    });
  }

  /// 停止轮询
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPollingActive = false;
  }

  /// 公开的启动轮询方法（供页面调用）
  void startPolling() {
    _startPolling();
  }

  /// 公开的停止轮询方法（供页面调用）
  void stopPolling() {
    _stopPolling();
  }

  /// 执行轮询刷新
  Future<void> _performPollingRefresh() async {
    // 如果当前正在加载，跳过本次轮询
    if (isLoading.value) return;
    
    // 刷新当前选中的tab数据
    await refreshDataForTab(selectedTab.value);
    
    // 同时刷新已预加载的相邻tab数据
    _refreshPreloadedTabs();
  }

  /// 刷新已预加载的tab数据
  void _refreshPreloadedTabs() {
    final currentIndex = selectedTab.value;
    final totalTabs = lobbyListModel.value.halls?.length ?? 0;
    
    // 计算需要刷新的tab范围
    final startIndex = (currentIndex - _maxPreloadRange).clamp(0, totalTabs - 1);
    final endIndex = (currentIndex + _maxPreloadRange).clamp(0, totalTabs - 1);
    
    // 刷新范围内的已预加载tab（排除当前tab）
    for (int i = startIndex; i <= endIndex; i++) {
      if (i != currentIndex && 
          i < tabDataList.length && 
          _preloadedTabs.contains(i) &&
          !_preloadingTabs.contains(i)) {
        _preloadTabData(i); // 重新预加载，会更新数据
      }
    }
  }

  /// 暂停轮询（页面不可见时调用）
  void pausePolling() {
    _stopPolling();
  }

  /// 恢复轮询（页面可见时调用）
  void resumePolling() {
    if (!_isPollingActive) {
      _startPolling();
    }
  }

  /// 获取预加载状态信息
  Map<String, dynamic> getPreloadStatus() {
    return {
      'preloadedTabs': _preloadedTabs.toList(),
      'preloadingTabs': _preloadingTabs.toList(),
      'maxPreloadRange': _maxPreloadRange,
    };
  }

  /// 检查指定tab是否已预加载
  bool isTabPreloaded(int index) {
    return _preloadedTabs.contains(index);
  }

  /// 检查指定tab是否正在预加载
  bool isTabPreloading(int index) {
    return _preloadingTabs.contains(index);
  }

  /// 手动触发预加载（用于测试或特殊场景）
  void triggerPreload(int index) {
    if (index >= 0 && index < tabDataList.length && !_preloadedTabs.contains(index)) {
      _preloadTabData(index);
    }
  }

  /// 滚动tab到屏幕中间
  void _scrollToTab(int index) {
    if (!tabScrollController.hasClients) return;
    
    // 由于tab宽度是自适应的，我们使用一个更简单的方法
    // 根据tab的索引比例来滚动，让选中的tab显示在屏幕中央
    
    // 获取总tab数量
    int totalTabs = lobbyListModel.value.halls?.length ?? 0;
    if (totalTabs == 0) return;
    
    // 计算目标tab在总宽度中的比例位置
    double tabRatio = index / (totalTabs - 1).clamp(1, double.infinity);
    
    // 计算目标滚动位置，让选中的tab显示在屏幕中央
    double maxScrollPosition = tabScrollController.position.maxScrollExtent;
    
    // 使用更简单的计算方式，直接根据比例滚动到对应位置
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
    // 清理轮询定时器
    _stopPolling();
    // 清理WebSocket连接
    _wsManager.disconnectAll();
    // 清理ScrollController
    tabScrollController.dispose();
    super.onClose();
  }
}
