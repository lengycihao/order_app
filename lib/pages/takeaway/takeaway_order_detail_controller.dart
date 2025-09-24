import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:order_app/utils/toast_component.dart';

class TakeawayOrderDetailController extends GetxController {
  // 订单基本信息
  String orderNumber = 'TA202412010001';
  String orderTime = '2024-12-01 14:30:25';
  String paymentMethod = '微信支付';
  String orderStatus = '已完成';
  String orderRemark = '不要葱花香菜、清蒸鲈鱼不要鱼、柠檬茶不要柠檬、三分糖、少冰';

  // 订单商品
  List<Map<String, dynamic>> orderItems = [
    {
      'name': '宫保鸡丁',
      'price': 28.00,
      'quantity': 1,
      'remark': '不要花生',
      'imageUrl': null,
    },
    {
      'name': '清蒸鲈鱼',
      'price': 45.00,
      'quantity': 1,
      'remark': '不要鱼',
      'imageUrl': null,
    },
    {
      'name': '柠檬茶',
      'price': 12.00,
      'quantity': 2,
      'remark': '不要柠檬、三分糖、少冰',
      'imageUrl': null,
    },
  ];

  // 费用明细
  double subtotal = 97.00;
  double deliveryFee = 5.00;
  double packagingFee = 2.00;
  double totalAmount = 104.00;

  // 配送信息
  Map<String, String> deliveryInfo = {
    'name': '张三',
    'phone': '138****8888',
    'address': '北京市朝阳区三里屯街道工体北路8号院',
    'time': '2024-12-01 15:00-15:30',
  };

  @override
  void onInit() {
    super.onInit();
    // 初始化数据
    _loadOrderDetail();
  }

  void _loadOrderDetail() {
    // 这里可以从API加载订单详情数据
    // 目前使用模拟数据
    update();
  }

  // 再来一单
  void reorder() {
    ToastUtils.showSuccess(Get.context!, '已将商品加入购物车');
    
    // 跳转到外卖页面
    Get.back();
    Get.toNamed('/takeaway');
  }

  // 联系商家
  void contactMerchant() {
    Get.dialog(
      AlertDialog(
        title: const Text('联系商家'),
        content: const Text('是否拨打商家电话？\n400-123-4567'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // 这里可以调用拨号功能
              ToastUtils.showSuccess(Get.context!, '正在拨打电话...');
            },
            child: const Text('拨打'),
          ),
        ],
      ),
    );
  }

  // 分享订单
  void shareOrder() {
    ToastUtils.showSuccess(Get.context!, '订单分享功能开发中...');
  }

  // 申请退款
  void requestRefund() {
    Get.dialog(
      AlertDialog(
        title: const Text('申请退款'),
        content: const Text('确定要申请退款吗？\n退款将在1-3个工作日内处理。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              ToastUtils.showSuccess(Get.context!, '退款申请已提交');
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
