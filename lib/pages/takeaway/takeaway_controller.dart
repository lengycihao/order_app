import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/takeaway/model/takeaway_order_model.dart';
import 'package:lib_domain/api/takeout_api.dart';
import 'package:lib_domain/api/base_api.dart';
import 'package:order_app/utils/l10n_utils.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:lib_base/lib_base.dart';
import 'package:order_app/utils/websocket_lifecycle_manager.dart';
import 'package:lib_base/logging/logging.dart';
import 'dart:async';

class TakeawayController extends GetxController {
  // 未结账订单列表
  var unpaidOrders = <TakeawayOrderModel>[].obs;
  
  // 已结账订单列表  
  var paidOrders = <TakeawayOrderModel>[].obs;
  
  // 每个 tab 是否在刷新
  var isRefreshingUnpaid = false.obs;
  var isRefreshingPaid = false.obs;
  
  // API服务
  final TakeoutApi _takeoutApi = TakeoutApi();
  
  // 分页参数
  int _unpaidPage = 1;
  int _paidPage = 1;
  final int _pageSize = 20;
  
  // 搜索相关
  final TextEditingController searchController = TextEditingController();
  String? _currentSearchCode;
  
  // 是否还有更多数据
  var hasMoreUnpaid = true.obs;
  var hasMorePaid = true.obs;
  
  // 网络错误状态
  var hasNetworkErrorUnpaid = false.obs;
  var hasNetworkErrorPaid = false.obs;
  
  // 是否正在加载更多
  var isLoadingMore = false.obs;
  
  // 虚拟开桌loading状态
  var isVirtualTableOpening = false.obs;
  
  // 自动刷新定时器
  Timer? _autoRefreshTimer;
  
  // 是否启用自动刷新
  var isAutoRefreshEnabled = true.obs;
  
  // 当前tab索引
  int _currentTabIndex = 0;
  
  // 搜索防抖定时器
  Timer? _searchDebounceTimer;

  @override
  void onInit() {
    super.onInit();
    // 设置页面类型并清理WebSocket连接
    wsLifecycleManager.setCurrentPageType(WebSocketLifecycleManager.PAGE_TAKEAWAY);
    loadInitialData();
    _startAutoRefresh();
  }

  @override
  void onClose() {
    // 清理WebSocket连接
    wsLifecycleManager.cleanupAllConnections();
    
    // 清理搜索防抖定时器
    _searchDebounceTimer?.cancel();
    
    // 清理自动刷新定时器
    _autoRefreshTimer?.cancel();
    
    // 安全地销毁searchController
    try {
      searchController.dispose();
    } catch (e) {
      // 如果已经销毁，忽略错误
      logError('SearchController already disposed: $e', tag: 'TakeawayController');
    }
    
    super.onClose();
  }

  Future<void> loadInitialData() async {
    // 初始化时同时加载两个tab的数据，确保数据可用
    logDebug('🚀 开始初始化加载外卖数据', tag: 'TakeawayController');
    try {
      await Future.wait([
        refreshData(0), // 未结账
        refreshData(1), // 已结账
      ]);
      logDebug('✅ 初始化加载完成 - 未结账: ${unpaidOrders.length}, 已结账: ${paidOrders.length}', tag: 'TakeawayController');
    } catch (e) {
      logDebug('❌ 初始化加载失败: $e', tag: 'TakeawayController');
    }
  }

  Future<void> refreshData(int tabIndex) async {
    // 网络错误状态会在请求成功后重置，这里不提前重置
    
    if (tabIndex == 0) {
      // 未结账 - query_type = 2
      await _loadUnpaidOrders(refresh: true);
    } else {
      // 已结账 - query_type = 1  
      await _loadPaidOrders(refresh: true);
    }
  }

  /// 加载未结账订单
  Future<void> _loadUnpaidOrders({bool refresh = false}) async {
    if (refresh) {
      _unpaidPage = 1;
      hasMoreUnpaid.value = true;
      // 刷新时不立即清空数据，避免UI闪烁
      // unpaidOrders.clear(); // 移除立即清空，改为在请求成功后替换
    }
    
    if (!hasMoreUnpaid.value) return;
    
    isRefreshingUnpaid.value = true;
    
    try {
      logDebug('🔄 开始请求未结账订单 - page: $_unpaidPage, pageSize: $_pageSize', tag: 'TakeawayController');
      
      final result = await _takeoutApi.getTakeoutList(
        queryType: 2, // 未结账
        page: _unpaidPage,
        pageSize: _pageSize,
        pickupCode: _currentSearchCode,
      );
      
      logDebug('📡 API响应 - isSuccess: ${result.isSuccess}, msg: ${result.msg}', tag: 'TakeawayController');
      logDebug('📡 API响应数据: ${result.dataJson}', tag: 'TakeawayController');
      
      if (result.isSuccess && result.dataJson != null) {
        final response = TakeawayOrderListResponse.fromJson(result.dataJson as Map<String, dynamic>);
        
        logDebug('📊 解析后的数据 - total: ${response.total}, data长度: ${response.data?.length}', tag: 'TakeawayController');
        
        // 请求成功，重置网络错误状态
        hasNetworkErrorUnpaid.value = false;
        
        if (response.data != null) {
          // 添加调试信息，显示每个订单的状态
          for (var order in response.data!) {
            logDebug('📋 未结账订单: ${order.debugStatusInfo}', tag: 'TakeawayController');
          }
          
          if (refresh) {
            // 刷新时替换全部数据，而不是追加
            unpaidOrders.assignAll(response.data!);
          } else {
            // 加载更多时追加数据
            unpaidOrders.addAll(response.data!);
          }
          logDebug('✅ 未结账订单数量: ${unpaidOrders.length}', tag: 'TakeawayController');
        } else {
          logDebug('⚠️ 未结账订单数据为空', tag: 'TakeawayController');
        }
        
        // 检查是否还有更多数据
        hasMoreUnpaid.value = !(response.isLastPage ?? true);
        
        if (hasMoreUnpaid.value) {
          _unpaidPage++;
        }
      } else {
        logDebug('❌ API请求失败: ${result.msg}', tag: 'TakeawayController');
        hasNetworkErrorUnpaid.value = true;
        // 只有在没有数据时才清空，避免已有数据时的闪烁
        if (refresh && unpaidOrders.isEmpty) {
          // 保持数据不变，让用户仍能看到之前的数据
        }
        GlobalToast.error(result.msg ?? '获取未结账订单失败');
      }
    } catch (e) {
      logDebug('❌ 加载未结账订单异常: $e', tag: 'TakeawayController');
      hasNetworkErrorUnpaid.value = true;
      GlobalToast.error(Get.context!.l10n.networkErrorPleaseTryAgain);
    } finally {
      isRefreshingUnpaid.value = false;
    }
  }

  /// 加载已结账订单
  Future<void> _loadPaidOrders({bool refresh = false}) async {
    if (refresh) {
      _paidPage = 1;
      hasMorePaid.value = true;
      // 刷新时不立即清空数据，避免UI闪烁
      // paidOrders.clear(); // 移除立即清空，改为在请求成功后替换
    }
    
    if (!hasMorePaid.value) return;
    
    isRefreshingPaid.value = true;
    
    try {
      logDebug('🔄 开始请求已结账订单 - page: $_paidPage, pageSize: $_pageSize', tag: 'TakeawayController');
      
      final result = await _takeoutApi.getTakeoutList(
        queryType: 1, // 已结账
        page: _paidPage,
        pageSize: _pageSize,
        pickupCode: _currentSearchCode,
      );
      
      logDebug('📡 已结账API响应 - isSuccess: ${result.isSuccess}, msg: ${result.msg}', tag: 'TakeawayController');
      logDebug('📡 已结账API响应数据: ${result.dataJson}', tag: 'TakeawayController');
      
      if (result.isSuccess && result.dataJson != null) {
        final response = TakeawayOrderListResponse.fromJson(result.dataJson as Map<String, dynamic>);
        
        logDebug('📊 已结账解析后的数据 - total: ${response.total}, data长度: ${response.data?.length}', tag: 'TakeawayController');
        
        // 请求成功，重置网络错误状态
        hasNetworkErrorPaid.value = false;
        
        if (response.data != null) {
          // 添加调试信息，显示每个订单的状态
          for (var order in response.data!) {
            logDebug('📋 已结账订单: ${order.debugStatusInfo}', tag: 'TakeawayController');
          }
          
          if (refresh) {
            // 刷新时替换全部数据，而不是追加
            paidOrders.assignAll(response.data!);
          } else {
            // 加载更多时追加数据
            paidOrders.addAll(response.data!);
          }
          logDebug('✅ 已结账订单数量: ${paidOrders.length}', tag: 'TakeawayController');
        } else {
          logDebug('⚠️ 已结账订单数据为空', tag: 'TakeawayController');
        }
        
        // 检查是否还有更多数据
        hasMorePaid.value = !(response.isLastPage ?? true);
        
        if (hasMorePaid.value) {
          _paidPage++;
        }
      } else {
        logDebug('❌ 已结账API请求失败: ${result.msg}', tag: 'TakeawayController');
        hasNetworkErrorPaid.value = true;
        // 只有在没有数据时才清空，避免已有数据时的闪烁
        if (refresh && paidOrders.isEmpty) {
          // 保持数据不变，让用户仍能看到之前的数据
        }
        GlobalToast.error(result.msg ?? Get.context!.l10n.networkErrorPleaseTryAgain);
      }
    } catch (e) {
      logDebug('❌ 加载已结账订单异常: $e', tag: 'TakeawayController');
      hasNetworkErrorPaid.value = true;
      GlobalToast.error(Get.context!.l10n.networkErrorPleaseTryAgain);
    } finally {
      isRefreshingPaid.value = false;
    }
  }

  /// 搜索订单（根据取单码）
  Future<void> searchOrders(String pickupCode, int tabIndex) async {
    if (pickupCode.isEmpty) {
      // 如果搜索为空，重新加载数据
      refreshData(tabIndex);
      return;
    }
    
    if (tabIndex == 0) {
      isRefreshingUnpaid.value = true;
    } else {
      isRefreshingPaid.value = true;
    }
    
    try {
      final queryType = tabIndex == 0 ? 2 : 1; // 0=未结账(2), 1=已结账(1)
      final result = await _takeoutApi.getTakeoutList(
        queryType: queryType,
        page: 1,
        pageSize: _pageSize,
        pickupCode: pickupCode,
      );
      
      if (result.isSuccess && result.data != null) {
        final response = TakeawayOrderListResponse.fromJson(result.data!);
        
        if (tabIndex == 0) {
          // 使用assignAll替换数据，而不是先清空再添加
          if (response.data != null) {
            unpaidOrders.assignAll(response.data!);
          } else {
            unpaidOrders.clear();
          }
        } else {
          // 使用assignAll替换数据，而不是先清空再添加
          if (response.data != null) {
            paidOrders.assignAll(response.data!);
          } else {
            paidOrders.clear();
          }
        }
      } else {
        GlobalToast.error(result.msg ?? Get.context!.l10n.failed);
      }
    } catch (e) {
      logDebug('❌ 搜索订单异常: $e', tag: 'TakeawayController');
      GlobalToast.error(Get.context!.l10n.networkErrorPleaseTryAgain);
    } finally {
      if (tabIndex == 0) {
        isRefreshingUnpaid.value = false;
      } else {
        isRefreshingPaid.value = false;
      }
    }
  }

  /// 加载更多数据
  Future<void> loadMore(int tabIndex) async {
    isLoadingMore.value = true;
    try {
      if (tabIndex == 0) {
        await _loadUnpaidOrders(refresh: false);
      } else {
        await _loadPaidOrders(refresh: false);
      }
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// 处理tab切换
  void onTabChanged(int tabIndex) {
    logDebug('🔄 Tab切换到: $tabIndex', tag: 'TakeawayController');
    _currentTabIndex = tabIndex;
    
    // 检查当前tab的数据状态并刷新
    if (tabIndex == 0) {
      logDebug('📊 未结账tab - 订单数量: ${unpaidOrders.length}, 正在加载: ${isRefreshingUnpaid.value}', tag: 'TakeawayController');
      // 如果没在加载，则刷新数据（无论是否有数据都刷新，保证数据最新）
      if (!isRefreshingUnpaid.value) {
        logDebug('🔄 刷新未结账数据', tag: 'TakeawayController');
        refreshData(0);
      }
    } else {
      logDebug('📊 已结账tab - 订单数量: ${paidOrders.length}, 正在加载: ${isRefreshingPaid.value}', tag: 'TakeawayController');
      // 如果没在加载，则刷新数据（无论是否有数据都刷新，保证数据最新）
      if (!isRefreshingPaid.value) {
        logDebug('🔄 刷新已结账数据', tag: 'TakeawayController');
        refreshData(1);
      }
    }
  }

  /// 根据取餐码搜索
  Future<void> searchByPickupCode(String pickupCode) async {
    if (pickupCode.isEmpty) {
      clearSearch();
      return;
    }
    
    _currentSearchCode = pickupCode;
    logDebug('🔍 开始搜索取餐码: $pickupCode', tag: 'TakeawayController');
    
    // 重置分页状态，但不清空数据避免闪烁
    _unpaidPage = 1;
    _paidPage = 1;
    hasMoreUnpaid.value = true;
    hasMorePaid.value = true;
    
    // 同时搜索未结账和已结账订单，使用refresh参数确保替换数据
    await Future.wait([
      _loadUnpaidOrders(refresh: true),
      _loadPaidOrders(refresh: true),
    ]);
  }

  /// 防抖搜索方法
  void debouncedSearch(String pickupCode) {
    // 取消之前的定时器
    _searchDebounceTimer?.cancel();
    
    // 设置新的定时器，500毫秒后执行搜索
    _searchDebounceTimer = Timer(Duration(milliseconds: 500), () {
      searchByPickupCode(pickupCode);
    });
  }

  /// 清除搜索
  void clearSearch() {
    // 取消防抖定时器，避免清空后仍触发搜索
    _searchDebounceTimer?.cancel();
    
    if (_currentSearchCode != null) {
      _currentSearchCode = null;
      logDebug('🔍 清除搜索', tag: 'TakeawayController');
      
      // 重新加载数据
      refreshData(0);
      refreshData(1);
    } else {
      // 即使没有当前搜索代码，也要确保取消定时器
      logDebug('🔍 取消搜索防抖定时器', tag: 'TakeawayController');
    }
  }

  /// 保持搜索框状态
  void preserveSearchState() {
    // 确保搜索框文本与当前搜索代码同步
    if (_currentSearchCode != null && searchController.text != _currentSearchCode) {
      searchController.text = _currentSearchCode!;
    }
  }

  /// 启动自动刷新
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (isAutoRefreshEnabled.value && !isRefreshingUnpaid.value && !isRefreshingPaid.value) {
        logDebug('🔄 自动刷新外卖订单数据', tag: 'TakeawayController');
        // 静默刷新当前tab的数据
        refreshData(_currentTabIndex);
      }
    });
  }

  /// 停止自动刷新
  void stopAutoRefresh() {
    isAutoRefreshEnabled.value = false;
    _autoRefreshTimer?.cancel();
    logDebug('⏹️ 停止自动刷新', tag: 'TakeawayController');
  }

  /// 恢复自动刷新
  void resumeAutoRefresh() {
    isAutoRefreshEnabled.value = true;
    _startAutoRefresh();
    logDebug('▶️ 恢复自动刷新', tag: 'TakeawayController');
  }

  /// 手动触发刷新（用于订单状态变更后）
  Future<void> forceRefresh() async {
    logDebug('🔄 强制刷新外卖订单数据', tag: 'TakeawayController');
    await Future.wait([
      refreshData(0), // 刷新未结账
      refreshData(1), // 刷新已结账
    ]);
  }

  /// 虚拟开桌
  Future<Map<String, dynamic>?> performVirtualTableOpen() async {
    if (isVirtualTableOpening.value) {
      logDebug('⚠️ 虚拟开桌正在进行中，忽略重复请求', tag: 'TakeawayController');
      return null;
    }
    
    isVirtualTableOpening.value = true;
    
    try {
      logDebug('🍽️ 开始虚拟开桌', tag: 'TakeawayController');
      
      final result = await BaseApi().openVirtualTable();
      
      if (result.isSuccess && result.data != null) {
        logDebug('✅ 虚拟开桌成功', tag: 'TakeawayController');
        return {
          'success': true,
          'data': result.data,
        };
      } else {
        logDebug('❌ 虚拟开桌失败: ${result.msg}', tag: 'TakeawayController');
        GlobalToast.error(result.msg ?? Get.context!.l10n.failed);
        // 失败时明确返回不包含data的结果
        return {
          'success': false,
          'message': result.msg ?? Get.context!.l10n.failed,
          'data': null, // 明确设置为null
        };
      }
    } catch (e) {
      logDebug('❌ 虚拟开桌异常: $e', tag: 'TakeawayController');
      GlobalToast.error(Get.context!.l10n.networkErrorPleaseTryAgain);
      // 网络异常时明确返回不包含data的结果
      return {
        'success': false,
        'message': Get.context!.l10n.networkErrorPleaseTryAgain,
        'data': null, // 明确设置为null
      };
    } finally {
      isVirtualTableOpening.value = false;
    }
  }
}
