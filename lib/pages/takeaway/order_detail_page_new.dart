import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'order_detail_controller_new.dart';

class OrderDetailPageNew extends StatelessWidget {
  const OrderDetailPageNew({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderDetailControllerNew>(
      init: OrderDetailControllerNew(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('订单详情'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: controller.refreshOrderDetail,
              ),
            ],
          ),
          body: Obx(() {
            if (controller.isLoading.value && controller.orderDetail.value == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final order = controller.orderDetail.value;
            if (order == null) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('订单详情加载失败', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.refreshOrderDetail,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 订单状态
                    _buildOrderStatusCard(order),
                    
                    const SizedBox(height: 20),
                    
                    // 订单基本信息
                    _buildOrderInfoCard(order),
                    
                    const SizedBox(height: 20),
                    
                    // 商品列表
                    _buildOrderItemsCard(order),
                    
                    const SizedBox(height: 20),
                    
                    // 费用明细
                    _buildCostDetailsCard(controller),
                    
                    const SizedBox(height: 20),
                    
                    // 配送信息
                    _buildDeliveryInfoCard(controller),
                    
                    const SizedBox(height: 20),
                    
                    // 备注信息
                    if (order.remark != null && order.remark!.isNotEmpty)
                      _buildRemarkCard(order),
                    
                    const SizedBox(height: 100), // 底部按钮预留空间
                  ],
                ),
              ),
            );
          }),
          bottomNavigationBar: _buildBottomActions(controller),
        );
      },
    );
  }

  /// 构建订单状态卡片
  Widget _buildOrderStatusCard(order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '订单状态',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: order.isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.isPaid ? '已结账' : '未结账',
                  style: TextStyle(
                    color: order.isPaid ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (order.orderStatusName != null)
            Text(
              '处理状态：${order.orderStatusName}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  /// 构建订单基本信息卡片
  Widget _buildOrderInfoCard(order) {
    return _buildInfoCard([
      _buildInfoRow('订单号', order.orderNo ?? 'N/A'),
      _buildInfoRow('下单时间', order.formattedOrderTime),
      _buildInfoRow('预计取餐时间', order.formattedEstimatePickupTime),
      if (order.pickupCode != null)
        _buildInfoRow('取单码', order.pickupCode!),
      _buildInfoRow('订单来源', order.sourceName ?? '未知'),
    ]);
  }

  /// 构建商品列表卡片
  Widget _buildOrderItemsCard(order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          _buildSectionTitle('商品明细'),
          const SizedBox(height: 12),
          if (order.details != null && order.details!.isNotEmpty)
            ...order.details!.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 商品图片
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.image != null && item.image!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.image!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: const Icon(Icons.fastfood, color: Colors.grey),
                            ),
                    ),
                    const SizedBox(width: 12),
                    // 商品信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name ?? '未知商品',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (item.optionsStr != null && item.optionsStr!.isNotEmpty)
                            Text(
                              item.optionsStr!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          const SizedBox(height: 4),
                          if (item.remark != null && item.remark!.isNotEmpty)
                            Text(
                              '备注：${item.remark}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // 数量和价格
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.quantityText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.formattedPrice,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList()
          else
            const Text('暂无商品信息', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  /// 构建费用明细卡片
  Widget _buildCostDetailsCard(OrderDetailControllerNew controller) {
    return _buildInfoCard([
      _buildInfoRow('商品总价', '€${controller.subtotal.toStringAsFixed(2)}'),
      _buildInfoRow('配送费', '€${controller.deliveryFee.toStringAsFixed(2)}'),
      _buildInfoRow('包装费', '€${controller.packagingFee.toStringAsFixed(2)}'),
      const Divider(),
      _buildInfoRow(
        '实付金额',
        '€${controller.totalAmount.toStringAsFixed(2)}',
        isTotal: true,
      ),
    ]);
  }

  /// 构建配送信息卡片
  Widget _buildDeliveryInfoCard(OrderDetailControllerNew controller) {
    final deliveryInfo = controller.deliveryInfo;
    return _buildInfoCard([
      _buildInfoRow('收货人', deliveryInfo['name'] ?? ''),
      _buildInfoRow('联系电话', deliveryInfo['phone'] ?? ''),
      _buildInfoRow('配送地址', deliveryInfo['address'] ?? ''),
      _buildInfoRow('配送时间', deliveryInfo['time'] ?? ''),
    ]);
  }

  /// 构建备注卡片
  Widget _buildRemarkCard(order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          _buildSectionTitle('备注信息'),
          const SizedBox(height: 8),
          Text(
            order.remark!,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部操作按钮
  Widget _buildBottomActions(OrderDetailControllerNew controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: controller.contactMerchant,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Colors.grey),
              ),
              child: const Text('联系商家'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: controller.reorder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9027),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                '再来一单',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建通用信息卡片
  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        children: children,
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建章节标题
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
