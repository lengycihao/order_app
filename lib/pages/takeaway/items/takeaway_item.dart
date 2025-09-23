import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/takeaway/model/takeaway_order_model.dart';
import 'package:order_app/pages/takeaway/order_detail_page_new.dart';
 
class TakeawayItem extends StatelessWidget {
  final TakeawayOrderModel order; // 直接接收订单模型对象

  const TakeawayItem({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToOrderDetail(),
      child: Container(
      width: double.infinity,
      // margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 1),
      padding: const EdgeInsets.only(top: 6, left: 16, bottom: 20, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 订单号和状态行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.pickupCode ?? order.orderNo ?? 'N/A',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusString(),
                  style: TextStyle(fontSize: 15, color: _getStatusLabelColor()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 时间和价格行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/order_takeaway_time_icon.webp',
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.formattedOrderTime,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xff333333),
                    ),
                  ),
                ],
              ),
              Text(
                order.formattedTotalAmount,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff333333),
                ),
              ),
            ],
          ),
          
          // // 预计取餐时间（如果有�?
          // if (order.formattedEstimatePickupTime.isNotEmpty) ...[
          //   const SizedBox(height: 8),
          //   Row(
          //     children: [
          //       const Icon(Icons.access_time, size: 16, color: Colors.orange),
          //       const SizedBox(width: 4),
          //       Text(
          //         '预计取餐�?{order.formattedEstimatePickupTime}',
          //         style: const TextStyle(
          //           fontSize: context.adaptFontSize(),
          //           color: Colors.orange,
          //         ),
          //       ),
          //     ],
          //   ),
          // ],
          
          // const SizedBox(height: 8),
          // const Divider(height: 0.4, color: Color(0x8d999999)),
          
          // // 订单状态信�?
          // if (order.orderStatusName != null && order.orderStatusName!.isNotEmpty)
          //   Padding(
          //     padding: const EdgeInsets.only(top: 8),
          //     child: Row(
          //       children: [
          //         const Icon(Icons.restaurant, size: 16, color: Color(0xff666666)),
          //         const SizedBox(width: 4),
          //         Text(
          //           '状态：${order.orderStatusName}',
          //           style: const TextStyle(
          //             fontSize: context.adaptFontSize(),
          //             color: Color(0xff666666),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          
          // 备注信息（如果存在则显示�?
          if (order.remark != null && order.remark!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const Icon(Icons.note, size: 16, color: Color(0xff666666)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '备注${order.remark}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xff666666),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      ),
    );
  }

  /// 跳转到订单详情页面
  void _navigateToOrderDetail() {
    Get.to(
      () => const OrderDetailPageNew(),
      arguments: {
        'orderId': order.id, // 外卖订单ID
      },
    );
  }

  // 根据结账状态返回不同的背景�?
  Color _getStatusColor() {
    if (order.isPaid) {
      return const Color(0xffE6FFDF); // 已结�?- 绿色
    } else if (order.isUnpaid) {
      return const Color(0xffFFE8DF); // 未结�?- 橙色
    } else {
      return Colors.grey; // 其他状�?
    }
  }

  Color _getStatusLabelColor() {
    if (order.isPaid) {
      return const Color(0xff04BE02); // 已结�?- 绿色文字
    } else if (order.isUnpaid) {
      return const Color(0xffFF9027); // 未结�?- 橙色文字
    } else {
      return Colors.grey; // 其他状�?
    }
  }

  String _getStatusString() {
    if (order.isPaid) {
      return '已结账';
    } else if (order.isUnpaid) {
      return '未结账';
    } else {
      return order.checkoutStatusName ?? '处理中';
    }
  }
}
