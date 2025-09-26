import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lib_domain/entrity/order/current_order_model.dart';
import 'package:lib_base/logging/logging.dart';

/// 订单页面工具类
/// 提取通用的页面逻辑，减少重复代码
class OrderPageUtils {
  
  /// 检查是否有订单数据
  static bool hasOrderData(CurrentOrderModel? order) {
    return order != null && 
           order.details != null && 
           order.details!.isNotEmpty;
  }
  
  /// 加载订单数据的通用方法
  static Future<void> loadOrderData({
    required dynamic controller,
    required String tableId,
    bool showLoading = false,
  }) async {
    if (tableId.isNotEmpty) {
      await controller.loadCurrentOrder(showLoading: showLoading);
    }
  }
  
  /// 构建通用的加载状态检查
  static bool shouldShowSkeleton({
    required bool isLoading,
    required bool hasData,
    required bool shouldShowSkeleton,
  }) {
    return shouldShowSkeleton && isLoading && !hasData;
  }
  
  /// 构建通用的状态检查
  static Widget buildStateWidget({
    required bool isLoading,
    required bool hasNetworkError,
    required bool hasData,
    required bool shouldShowSkeleton,
    required Widget Function() buildSkeletonWidget,
    required Widget Function() buildLoadingWidget,
    required Widget Function() buildNetworkErrorState,
    required Widget Function() buildEmptyState,
    required Widget Function() buildDataContent,
  }) {
    if (shouldShowSkeleton && isLoading && !hasData) {
      return buildSkeletonWidget();
    }
    
    if (isLoading && !hasData) {
      return buildLoadingWidget();
    }
    
    if (hasNetworkError) {
      return buildNetworkErrorState();
    }
    
    if (!hasData) {
      return buildEmptyState();
    }
    
    return buildDataContent();
  }
  
  /// 安全的控制器获取
  static T? getControllerSafely<T>() {
    try {
      return Get.find<T>();
    } catch (e) {
      logError('❌ 获取控制器失败: $e', tag: 'OrderPageUtils');
      return null;
    }
  }
}
