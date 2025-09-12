import 'package:flutter/material.dart';
import 'package:order_app/pages/takeaway/model/tabelaway_item_model.dart';

class TakeawayItem extends StatelessWidget {
  final TabelawayItemModel order; // 直接接收订单模型对象

  const TakeawayItem({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                order.orderNumber,
                style: const TextStyle(
                  fontSize: 36,
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
                  style: TextStyle(fontSize: 14, color: _getStatusLabelColor()),
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
                  Text(
                    order.time,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xff333333),
                    ),
                  ),
                ],
              ),
              Text(
                order.price,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 0.4, color: Color(0x8d999999)),
          // 备注信息（如果存在则显示）
          if (order.remark != null && order.remark!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '备注：${order.remark}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xff666666),
                  // fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 根据状态返回不同的背景色
  Color _getStatusColor() {
    switch (order.status) {
      case 1:
        return Color(0xffFFE8DF);
      case 2:
        return Color(0xffE6FFDF);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusLabelColor() {
    switch (order.status) {
      case 1:
        return Color(0xffFF9027);
      case 2:
        return Color(0xff04BE02);
      default:
        return Colors.grey;
    }
  }

  String _getStatusString() {
    switch (order.status) {
      case 1:
        return '未结账';
      case 2:
        return '已结账';
      default:
        return '处理中';
    }
  }
}
