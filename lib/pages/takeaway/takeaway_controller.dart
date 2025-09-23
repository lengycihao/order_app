import 'package:get/get.dart';
import 'package:order_app/pages/takeaway/model/takeaway_order_model.dart';
import 'package:lib_domain/api/takeout_api.dart';
import 'package:order_app/utils/snackbar_utils.dart';
import 'package:lib_base/lib_base.dart';

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
  
  // 是否还有更多数据
  var hasMoreUnpaid = true.obs;
  var hasMorePaid = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  void loadInitialData() {
    // 加载两个tab的数据
    refreshData(0); // 未结账
    refreshData(1); // 已结账
  }

  Future<void> refreshData(int tabIndex) async {
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
    }
    
    if (!hasMoreUnpaid.value) return;
    
    isRefreshingUnpaid.value = true;
    
    try {
      final result = await _takeoutApi.getTakeoutList(
        queryType: 2, // 未结账
        page: _unpaidPage,
        pageSize: _pageSize,
      );
      
      if (result.isSuccess && result.data != null) {
        final response = TakeawayOrderListResponse.fromJson(result.data!);
        
        if (refresh) {
          unpaidOrders.clear();
        }
        
        if (response.data != null) {
          unpaidOrders.addAll(response.data!);
        }
        
        // 检查是否还有更多数据
        hasMoreUnpaid.value = !(response.isLastPage ?? true);
        
        if (hasMoreUnpaid.value) {
          _unpaidPage++;
        }
      } else {
        SnackbarUtils.showError(Get.context!, result.msg ?? '获取未结账订单失败');
      }
    } catch (e) {
      logDebug('❌ 加载未结账订单异常: $e', tag: 'TakeawayController');
      SnackbarUtils.showError(Get.context!, '获取未结账订单异常');
    } finally {
      isRefreshingUnpaid.value = false;
    }
  }

  /// 加载已结账订单
  Future<void> _loadPaidOrders({bool refresh = false}) async {
    if (refresh) {
      _paidPage = 1;
      hasMorePaid.value = true;
    }
    
    if (!hasMorePaid.value) return;
    
    isRefreshingPaid.value = true;
    
    try {
      final result = await _takeoutApi.getTakeoutList(
        queryType: 1, // 已结账
        page: _paidPage,
        pageSize: _pageSize,
      );
      
      if (result.isSuccess && result.data != null) {
        final response = TakeawayOrderListResponse.fromJson(result.data!);
        
        if (refresh) {
          paidOrders.clear();
        }
        
        if (response.data != null) {
          paidOrders.addAll(response.data!);
        }
        
        // 检查是否还有更多数据
        hasMorePaid.value = !(response.isLastPage ?? true);
        
        if (hasMorePaid.value) {
          _paidPage++;
        }
      } else {
        SnackbarUtils.showError(Get.context!, result.msg ?? '获取已结账订单失败');
      }
    } catch (e) {
      logDebug('❌ 加载已结账订单异常: $e', tag: 'TakeawayController');
      SnackbarUtils.showError(Get.context!, '获取已结账订单异常');
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
        SnackbarUtils.showError(Get.context!, result.msg ?? '搜索订单失败');
      }
    } catch (e) {
      logDebug('❌ 搜索订单异常: $e', tag: 'TakeawayController');
      SnackbarUtils.showError(Get.context!, '搜索订单异常');
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
    if (tabIndex == 0) {
      await _loadUnpaidOrders(refresh: false);
    } else {
      await _loadPaidOrders(refresh: false);
    }
  }
}
