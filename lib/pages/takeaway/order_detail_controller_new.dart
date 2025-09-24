import 'package:get/get.dart';
import 'package:order_app/pages/takeaway/model/takeaway_order_detail_model.dart';
import 'package:lib_domain/api/takeout_api.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:lib_base/lib_base.dart';

class OrderDetailControllerNew extends GetxController {
  // 订单详情数据
  final Rx<TakeawayOrderDetailResponse?> orderDetail = Rx<TakeawayOrderDetailResponse?>(null);
  
  // 加载状态
  final RxBool isLoading = false.obs;
  
  // API服务
  final TakeoutApi _takeoutApi = TakeoutApi();
  
  // 订单ID
  int? orderId;

  @override
  void onInit() {
    super.onInit();
    
    // 从路由参数获取订单ID
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments['orderId'] != null) {
      orderId = arguments['orderId'] as int;
      loadOrderDetail();
    } else {
      logDebug('❌ 订单ID不能为空', tag: 'OrderDetailControllerNew');
      // 延迟显示Toast，确保页面已经加载完成
      Future.delayed(const Duration(milliseconds: 100), () {
        if (Get.context != null) {
          Toast.error(Get.context!, '订单ID不能为空');
        }
      });
    }
  }

  /// 加载订单详情
  Future<void> loadOrderDetail() async {
    if (orderId == null) {
      logDebug('❌ 订单ID不能为空', tag: 'OrderDetailControllerNew');
      // 延迟显示Toast，确保页面已经加载完成
      Future.delayed(const Duration(milliseconds: 100), () {
        if (Get.context != null) {
          Toast.error(Get.context!, '订单ID不能为空');
        }
      });
      return;
    }
    
    isLoading.value = true;
    
    try {
      final result = await _takeoutApi.getTakeoutDetail(id: orderId!);
      
      logDebug('🔍 API返回结果: $result', tag: 'OrderDetailControllerNew');
      logDebug('🔍 API返回数据: ${result.data}', tag: 'OrderDetailControllerNew');
      logDebug('🔍 API返回数据类型: ${result.data.runtimeType}', tag: 'OrderDetailControllerNew');
      if (result.data != null) {
        logDebug('🔍 API返回数据键: ${(result.data as Map).keys.toList()}', tag: 'OrderDetailControllerNew');
      }
      
      if (result.isSuccess) {
        try {
          // 使用dataJson而不是data，因为API返回的数据在dataJson中
          final jsonData = result.getDataJson();
          logDebug('🔍 从dataJson获取的数据: $jsonData', tag: 'OrderDetailControllerNew');
          
          if (jsonData.isNotEmpty) {
            orderDetail.value = TakeawayOrderDetailResponse.fromJson(jsonData);
            logDebug('✅ 数据解析成功: ${orderDetail.value}', tag: 'OrderDetailControllerNew');
            logDebug('✅ 解析后的订单ID: ${orderDetail.value?.id}', tag: 'OrderDetailControllerNew');
            logDebug('✅ 解析后的订单号: ${orderDetail.value?.orderNo}', tag: 'OrderDetailControllerNew');
            logDebug('✅ 解析后的商品数量: ${orderDetail.value?.details?.length}', tag: 'OrderDetailControllerNew');
          } else {
            logDebug('❌ dataJson为空，无法解析数据', tag: 'OrderDetailControllerNew');
            if (Get.context != null) {
              Toast.error(Get.context!, '订单详情数据为空');
            }
          }
        } catch (parseError) {
          logDebug('❌ 数据解析失败: $parseError', tag: 'OrderDetailControllerNew');
          logDebug('❌ 解析错误堆栈: ${parseError.toString()}', tag: 'OrderDetailControllerNew');
          if (Get.context != null) {
            Toast.error(Get.context!, '数据解析失败: ${parseError.toString()}');
          }
        }
      } else {
        logDebug('❌ API请求失败: ${result.msg}', tag: 'OrderDetailControllerNew');
        if (Get.context != null) {
          Toast.error(Get.context!, result.msg ?? '获取订单详情失败');
        }
      }
    } catch (e) {
      logDebug('❌ 加载订单详情异常: $e', tag: 'OrderDetailControllerNew');
      if (Get.context != null) {
        Toast.error(Get.context!, '获取订单详情异常');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新订单详情
  Future<void> refreshOrderDetail() async {
    await loadOrderDetail();
  }

  /// 再来一单
  void reorder() {
    if (orderDetail.value?.details == null || orderDetail.value!.details!.isEmpty) {
      Toast.error(Get.context!, '订单商品信息不完整，无法再来一单');
      return;
    }
    
    // TODO: 实现再来一单逻辑
    // 1. 将订单中的商品添加到购物车
    // 2. 跳转到外卖页面或购物车页面
    
    Toast.success(Get.context!, '商品已添加到购物车');
    
    // 暂时跳转到外卖页面
    Get.back();
    Get.toNamed('/takeaway');
  }

  /// 联系商家
  void contactMerchant() {
    // TODO: 实现联系商家功能
    Toast.info(Get.context!, '联系商家功能暂未开放');
  }

  /// 申请退款
  void requestRefund() {
    if (orderDetail.value?.isPaid != true) {
      Toast.error(Get.context!, '只有已支付的订单才能申请退款');
      return;
    }
    
    // TODO: 实现申请退款功能
    Toast.info(Get.context!, '退款申请功能暂未开放');
  }

  /// 计算商品总价
  double get subtotal {
    if (orderDetail.value?.details == null) return 0.0;
    
    double total = 0.0;
    for (final item in orderDetail.value!.details!) {
      try {
        final price = double.parse(item.price ?? '0');
        final quantity = item.quantity ?? 1;
        total += price * quantity;
      } catch (e) {
        // 忽略解析错误
      }
    }
    return total;
  }

  /// 获取配送费
  double get deliveryFee {
    // TODO: 从订单详情API获取配送费
    return 5.00;
  }

  /// 获取包装费
  double get packagingFee {
    // TODO: 从订单详情API获取包装费
    return 2.00;
  }

  /// 获取总金额
  double get totalAmount {
    if (orderDetail.value?.totalAmount != null) {
      try {
        return double.parse(orderDetail.value!.totalAmount!);
      } catch (e) {
        // 解析失败时使用计算值
      }
    }
    return subtotal + deliveryFee + packagingFee;
  }

  /// 获取配送信息（模拟数据，实际应该从API获取）
  Map<String, String> get deliveryInfo {
    // TODO: 从订单详情API获取配送信息
    return {
      'name': '张三',
      'phone': '138****8888', 
      'address': '北京市朝阳区三里屯街道工体北路8号院',
      'time': orderDetail.value?.formattedEstimatePickupTime ?? '',
    };
  }
}
