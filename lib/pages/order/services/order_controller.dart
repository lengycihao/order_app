// import 'package:get/get.dart';
// import 'package:lib_domain/entrity/order/current_order_model.dart';
// import 'package:lib_domain/api/order_api.dart';
// import 'package:lib_base/logging/logging.dart';

// /// 订单控制器
// /// 负责管理订单相关的操作
// class OrderController extends GetxController {
//   final String _logTag = 'OrderController';
//   final OrderApi _orderApi = OrderApi();
  
//   // 已点订单数据
//   var currentOrder = Rx<CurrentOrderModel?>(null);
//   final isLoadingOrdered = false.obs;
//   final hasNetworkErrorOrdered = false.obs;

//   /// 加载当前订单数据
//   Future<void> loadCurrentOrder({
//     required String tableId,
//     int retryCount = 0,
//     int maxRetries = 3,
//     bool showRetryDialog = false,
//     bool showLoading = true,
//   }) async {
//     try {
//       if (showLoading) {
//         isLoadingOrdered.value = true;
//         logDebug('📋 设置loading状态为true', tag: _logTag);
//       } else {
//         logDebug('📋 静默刷新，不设置loading状态 (当前状态: ${isLoadingOrdered.value})', tag: _logTag);
//       }
      
//       // 重置网络错误状态
//       hasNetworkErrorOrdered.value = false;
//       logDebug('📋 开始加载已点订单数据... (重试次数: $retryCount, 显示loading: $showLoading)', tag: _logTag);

//       final result = await _orderApi.getCurrentOrder(tableId: tableId);

//       if (result.isSuccess && result.data != null) {
//         currentOrder.value = result.data;
//         logDebug('✅ 已点订单数据加载成功: ${result.data?.details?.length ?? 0}个订单', tag: _logTag);
//       } else {
//         // 检查是否是真正的空数据（没有订单）还是服务器处理中
//         if (result.msg == '响应数据为空' || (result.code == 0 && result.msg == 'success' && result.data == null)) {
//           // 这是真正的空数据，直接显示空状态，不重试
//           logDebug('📭 当前桌台没有已点订单，显示空状态', tag: _logTag);
//           currentOrder.value = null;
//         } else if ((result.code == 210 || result.msg?.contains('数据处理中') == true) 
//             && retryCount < maxRetries) {
//           // 只有服务器明确表示数据处理中时才重试
//           logDebug('⚠️ 数据可能还在处理中，${2}秒后重试... (${retryCount + 1}/$maxRetries)', tag: _logTag);
          
//           // 延迟2秒后重试
//           await Future.delayed(Duration(seconds: 2));
//           return loadCurrentOrder(
//             tableId: tableId,
//             retryCount: retryCount + 1,
//             maxRetries: maxRetries,
//             showRetryDialog: showRetryDialog,
//             showLoading: showLoading,
//           );
//         } else {
//           logDebug('❌ 已点订单数据加载失败: ${result.msg} (状态码: ${result.code})', tag: _logTag);
//           currentOrder.value = null;
//         }
//       }
//     } catch (e, stackTrace) {
//       logError('❌ 已点订单数据加载异常: $e', tag: _logTag);
//       logError('❌ StackTrace: $stackTrace', tag: _logTag);
      
//       // 对于异常情况，如果还有重试机会，也进行重试
//       if (retryCount < maxRetries && (e.toString().contains('null') || e.toString().contains('NoSuchMethodError'))) {
//         logDebug('⚠️ 检测到空指针异常，${2}秒后重试... (${retryCount + 1}/$maxRetries)', tag: _logTag);
//         await Future.delayed(Duration(seconds: 2));
//         return loadCurrentOrder(
//           tableId: tableId,
//           retryCount: retryCount + 1,
//           maxRetries: maxRetries,
//           showRetryDialog: showRetryDialog,
//           showLoading: showLoading,
//         );
//       } else {
//         // 设置网络错误状态
//         hasNetworkErrorOrdered.value = true;
//         currentOrder.value = null;
//       }
//     } finally {
//       // 在以下情况下停止loading：
//       // 1. 达到最大重试次数
//       // 2. 有数据返回
//       // 3. 确认是空数据（不需要重试）
//       bool shouldStopLoading = retryCount >= maxRetries || 
//                                currentOrder.value != null ||
//                                (retryCount == 0); // 首次请求完成，无论结果如何都停止loading
      
//       if (shouldStopLoading) {
//         // 无论showLoading参数如何，都要确保loading状态被正确重置
//         logDebug('📋 停止loading状态 (之前状态: ${isLoadingOrdered.value})', tag: _logTag);
//         isLoadingOrdered.value = false;
//       } else {
//         logDebug('📋 继续loading状态，不停止 (重试次数: $retryCount)', tag: _logTag);
//       }
//     }
//   }

//   /// 提交订单
//   Future<Map<String, dynamic>> submitOrder({
//     required int tableId,
//   }) async {
//     try {
//       logDebug('📤 开始提交订单...', tag: _logTag);

//       final result = await _orderApi.submitOrder(tableId: tableId);

//       if (result.isSuccess) {
//         logDebug('✅ 订单提交成功', tag: _logTag);
        
//         return {
//           'success': true,
//           'message': '订单提交成功'
//         };
//       } else {
//         logDebug('❌ 订单提交失败: ${result.msg}', tag: _logTag);
//         return {
//           'success': false,
//           'message': result.msg ?? '订单提交失败'
//         };
//       }
//     } catch (e, stackTrace) {
//       logError('❌ 订单提交异常: $e', tag: _logTag);
//       logError('❌ StackTrace: $stackTrace', tag: _logTag);
//       return {
//         'success': false,
//         'message': '订单提交异常: $e'
//       };
//     }
//   }

//   /// 清空订单数据
//   void clearOrderData() {
//     currentOrder.value = null;
//     isLoadingOrdered.value = false;
//     hasNetworkErrorOrdered.value = false;
//     logDebug('🧹 订单数据已清空', tag: _logTag);
//   }

//   /// 检查是否有订单数据
//   bool get hasOrderData => currentOrder.value != null;

//   /// 获取订单数量
//   int get orderCount => currentOrder.value?.details?.length ?? 0;
// }
