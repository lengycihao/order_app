import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/takeaway/model/takeaway_order_model.dart';
import 'package:order_app/pages/takeaway/order_detail_page_new.dart';
import 'package:order_app/utils/l10n_utils.dart';
 
class TakeawayItem extends StatefulWidget {
  final TakeawayOrderModel order; // 直接接收订单模型对象

  const TakeawayItem({super.key, required this.order});

  @override
  State<TakeawayItem> createState() => _TakeawayItemState();
}

class _TakeawayItemState extends State<TakeawayItem> {
  bool _isRemarkExpanded = false;

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 订单号和状态行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.order.pickupCode ?? widget.order.orderNo ?? 'N/A',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff333333),
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
                    widget.order.formattedOrderTime,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xff333333),
                    ),
                  ),
                ],
              ),
              Text(
                widget.order.formattedTotalAmount,
                style: const TextStyle(
                  fontSize: 16,
                  // fontWeight: FontWeight.w500,
                  color: Color(0xff333333),
                ),
              ),
            ],
          ),
          
          
          // 备注信息（如果存在则显示?
          if (widget.order.remark != null && widget.order.remark!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xffE5E5E5)),
            const SizedBox(height: 8),
            _buildRemarkWidget(),
          ],
        ],
      ),
      ),
    );
  }

  /// 构建备注组件
  Widget _buildRemarkWidget() {
    final remark = widget.order.remark!;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // 使用 TextPainter 计算文本是否超过一行
        final textPainter = TextPainter(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${context.l10n.remarks}：',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xff666666),
                ),
              ),
              TextSpan(
                text: remark,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xff666666),
                ),
              ),
            ],
          ),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: constraints.maxWidth - 32); // 减去箭头和间距的宽度
        final isMultiLine = textPainter.didExceedMaxLines;
        
        return GestureDetector(
          onTap: isMultiLine ? () {
            setState(() {
              _isRemarkExpanded = !_isRemarkExpanded;
            });
          } : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 4),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${context.l10n.remarks}：',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xff666666),
                        ),
                      ),
                      TextSpan(
                        text: remark,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xff666666),
                        ),
                      ),
                    ],
                  ),
                  maxLines: _isRemarkExpanded ? null : 1,
                  overflow: _isRemarkExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
              ),
              if (isMultiLine) ...[
                const SizedBox(width: 8),
                Image.asset(
                  _isRemarkExpanded 
                      ? 'assets/order_login_arrowD.webp'
                      : 'assets/order_login_arrowR.webp',
                  width: 16,
                  height: 16,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// 跳转到订单详情页面
  void _navigateToOrderDetail() {
    Get.to(
      () => const OrderDetailPageNew(),
      arguments: {
        'orderId': widget.order.id, // 外卖订单ID
      },
    );
  }

  // 根据结账状态返回不同的背景?
  Color _getStatusColor() {
    if (widget.order.isPaid) {
      return const Color(0xffE6FFDF); // 已结?- 绿色
    } else if (widget.order.isUnpaid) {
      return const Color(0xffFFE8DF); // 未结?- 橙色
    } else {
      return Colors.grey; // 其他状?
    }
  }

  Color _getStatusLabelColor() {
    if (widget.order.isPaid) {
      return const Color(0xff04BE02); // 已结?- 绿色文字
    } else if (widget.order.isUnpaid) {
      return const Color(0xffFF9027); // 未结?- 橙色文字
    } else {
      return Colors.grey; // 其他状?
    }
  }

  String _getStatusString() {
    if (widget.order.isPaid) {
      return context.l10n.paid;
    } else if (widget.order.isUnpaid) {
      return context.l10n.unpaid;
    } else {
      return widget.order.checkoutStatusName ?? '处理中';
    }
  }
}