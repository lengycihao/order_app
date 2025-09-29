import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/takeaway/model/takeaway_order_model.dart';
import 'package:lib_domain/api/takeout_api.dart';
import 'package:lib_domain/api/base_api.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:lib_base/lib_base.dart';
import 'package:order_app/utils/websocket_lifecycle_manager.dart';
import 'package:lib_base/logging/logging.dart';

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

  @override
  void onInit() {
    super.onInit();
    // 设置页面类型并清理WebSocket连接
    wsLifecycleManager.setCurrentPageType(WebSocketLifecycleManager.PAGE_TAKEAWAY);
    loadInitialData();
  }

  @override
  void onClose() {
    // 清理WebSocket连接
    wsLifecycleManager.cleanupAllConnections();
    
    // 安全地销毁searchController
    try {
      searchController.dispose();
    } catch (e) {
      // 如果已经销毁，忽略错误
      logError('SearchController already disposed: $e', tag: 'TakeawayController');
    }
    
    super.onClose();
  }

  void loadInitialData() {
    // 只加载未结账订单，已结账订单在用户切换到对应tab时再加载
    refreshData(0); // 未结账
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
          if (refresh) {
            // 刷新时替换全部数据，而不是追加
            unpaidOrders.assignAll(response.data!);
          } else {
            // 加载更多时追加数据
            unpaidOrders.addAll(response.data!);
          }
          logDebug('✅ 未结账订单数量: ${unpaidOrders.length}', tag: 'TakeawayController');
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
      GlobalToast.error('获取未结账订单异常');
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
          if (refresh) {
            // 刷新时替换全部数据，而不是追加
            paidOrders.assignAll(response.data!);
          } else {
            // 加载更多时追加数据
            paidOrders.addAll(response.data!);
          }
          logDebug('✅ 已结账订单数量: ${paidOrders.length}', tag: 'TakeawayController');
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
        GlobalToast.error(result.msg ?? '获取已结账订单失败');
      }
    } catch (e) {
      logDebug('❌ 加载已结账订单异常: $e', tag: 'TakeawayController');
      hasNetworkErrorPaid.value = true;
      GlobalToast.error('获取已结账订单异常');
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
          unpaidOrders.clear();
          if (response.data != null) {
            unpaidOrders.addAll(response.data!);
          }
        } else {
          paidOrders.clear();
          if (response.data != null) {
            paidOrders.addAll(response.data!);
          }
        }
      } else {
        GlobalToast.error(result.msg ?? '搜索订单失败');
      }
    } catch (e) {
      logDebug('❌ 搜索订单异常: $e', tag: 'TakeawayController');
      GlobalToast.error('搜索订单异常');
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
    
    // 如果切换到已结账tab且还没有数据，则加载数据
    if (tabIndex == 1 && paidOrders.isEmpty) {
      refreshData(1);
    }
  }

  /// 根据取餐码搜索
  Future<void> searchByPickupCode(String pickupCode) async {
    if (pickupCode.isEmpty) return;
    
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

  /// 清除搜索
  void clearSearch() {
    if (_currentSearchCode != null) {
      _currentSearchCode = null;
      logDebug('🔍 清除搜索', tag: 'TakeawayController');
      
      // 重新加载数据
      refreshData(0);
      refreshData(1);
    }
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
        GlobalToast.error(result.msg ?? '虚拟开桌失败');
        // 失败时明确返回不包含data的结果
        return {
          'success': false,
          'message': result.msg ?? '虚拟开桌失败',
          'data': null, // 明确设置为null
        };
      }
    } catch (e) {
      logDebug('❌ 虚拟开桌异常: $e', tag: 'TakeawayController');
      GlobalToast.error('网络异常，请检查网络连接');
      // 网络异常时明确返回不包含data的结果
      return {
        'success': false,
        'message': '网络异常: $e',
        'data': null, // 明确设置为null
      };
    } finally {
      isVirtualTableOpening.value = false;
    }
  }
}
