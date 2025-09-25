import 'package:flutter/material.dart';
import 'package:lib_domain/entrity/order/order_detail_model.dart';
import 'package:order_app/pages/order/components/ordered_dish_item_widget.dart';

class OrderModuleWidget extends StatelessWidget {
  final OrderDetailModel orderDetail;
  final bool isLast;

  const OrderModuleWidget({
    Key? key,
    required this.orderDetail,
    this.isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      decoration: BoxDecoration(
        color: Color(0xffffffff),
        borderRadius: BorderRadius.circular(12),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.05),
        //     blurRadius: 8,
        //     offset: Offset(0, 2),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 模块头部
          _buildModuleHeader(),
          // 菜品列表
          if (orderDetail.dishes != null && orderDetail.dishes!.isNotEmpty)
            _buildDishList(),
        ],
      ),
    );
  }

  /// 构建模块头部
  Widget _buildModuleHeader() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // 柱状条
          _buildProgressBar(),
          SizedBox(width: 10),
          // 下单次数
          Text(
            orderDetail.timesStr ?? '第${orderDetail.times ?? 0}次下单',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Spacer(),
          // 轮次和数量信息
          _buildOrderInfo(),
        ],
      ),
    );
  }

  /// 构建进度条
  Widget _buildProgressBar() {
    // final times = orderDetail.times ?? 1;
    // final progress = (times - 1) / 6.0; // 假设最多6次下单
    
    return Container(
      width: 2,
      height: 10,
      decoration: BoxDecoration(
        color: Color(0xffFF9027),
        borderRadius: BorderRadius.circular(2),
      ),
      // child: FractionallySizedBox(
      //   alignment: Alignment.bottomCenter,
      //   heightFactor: progress.clamp(0.0, 1.0),
      //   child: Container(
      //     decoration: BoxDecoration(
      //       color: Colors.orange,
      //       borderRadius: BorderRadius.circular(2),
      //     ),
      //   ),
      // ),
    );
  }

  /// 构建订单信息
  Widget _buildOrderInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 轮次信息
        Text(
         "轮次：${orderDetail.roundStr ?? ''}",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(width: 6),
        // 数量信息
        Text(
          "数量：${orderDetail.quantityStr ?? ''}",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 构建菜品列表
  Widget _buildDishList() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: orderDetail.dishes!.map((dish) {
          return OrderedDishItemWidget(
            dish: dish,
            isLast: dish == orderDetail.dishes!.last,
          );
        }).toList(),
      ),
    );
  }
}
