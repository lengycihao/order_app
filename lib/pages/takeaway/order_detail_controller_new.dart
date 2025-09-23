import 'package:get/get.dart';
import 'package:order_app/pages/takeaway/model/takeaway_order_detail_model.dart';
import 'package:lib_domain/api/takeout_api.dart';
import 'package:order_app/utils/snackbar_utils.dart';
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
      SnackbarUtils.showError(Get.context!, '订单ID不能为空');
    }
  }

  /// 加载订单详情
  Future<void> loadOrderDetail() async {
    if (orderId == null) {
      SnackbarUtils.showError(Get.context!, '订单ID不能为空');
      return;
    }
    
    isLoading.value = true;
    
    try {
      final result = await _takeoutApi.getTakeoutDetail(id: orderId!);
      
      if (result.isSuccess && result.data != null) {
        orderDetail.value = TakeawayOrderDetailResponse.fromJson(result.data!);
      } else {
        SnackbarUtils.showError(Get.context!, result.msg ?? '获取订单详情失败');
      }
    } catch (e) {
      logDebug('❌ 加载订单详情异常: $e', tag: 'OrderDetailControllerNew');
      SnackbarUtils.showError(Get.context!, '获取订单详情异常');
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
      SnackbarUtils.showError(Get.context!, '订单商品信息不完整，无法再来一单');
      return;
    }
    
    // TODO: 实现再来一单逻辑
    // 1. 将订单中的商品添加到购物车
    // 2. 跳转到外卖页面或购物车页面
    
    SnackbarUtils.showSuccess(Get.context!, '商品已添加到购物车');
    
    // 暂时跳转到外卖页面
    Get.back();
    Get.toNamed('/takeaway');
  }

  /// 联系商家
  void contactMerchant() {
    // TODO: 实现联系商家功能
    SnackbarUtils.showInfo(Get.context!, '联系商家功能暂未开放');
  }

  /// 申请退款
  void requestRefund() {
    if (orderDetail.value?.isPaid != true) {
      SnackbarUtils.showError(Get.context!, '只有已支付的订单才能申请退款');
      return;
    }
    
    // TODO: 实现申请退款功能
    SnackbarUtils.showInfo(Get.context!, '退款申请功能暂未开放');
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
