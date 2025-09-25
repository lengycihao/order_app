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
  var isLoading = false.obs;
  var isMergeMode = false.obs;
  var selectedTables = <String>[].obs; // 存储选中的桌台ID或编号
  var hasNetworkError = false.obs; // 网络错误状态
  
  // WebSocket管理器
  final WebSocketManager _wsManager = wsManager;
  final isWebSocketConnected = false.obs;

  @override
  void onInit() {
    super.onInit();
    getLobbyList();
    //获取菜单列表
    getMenuList();
    // 初始化WebSocket连接状态监听
    _initializeWebSocketStatus();
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
      } else {
        hasNetworkError.value = true;
      }
    } catch (e) {
      hasNetworkError.value = true;
    } finally {
      isLoading.value = false;
    }
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
      } else {
        hasNetworkError.value = true;
      }
    } catch (e) {
      hasNetworkError.value = true;
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
    fetchDataForTab(index);
  }

  void onPageChanged(int index) {
    selectedTab.value = index;
    fetchDataForTab(index);
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

  @override
  void onClose() {
    // 清理WebSocket连接
    _wsManager.disconnectAll();
    super.onClose();
  }
}
