import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'order_detail_controller_new.dart';
import 'model/takeaway_order_detail_model.dart';

class OrderDetailPageNew extends StatelessWidget {
  const OrderDetailPageNew({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderDetailControllerNew>(
      init: OrderDetailControllerNew(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xfff9f9f9),
          appBar: AppBar(
            title: const Text(''),
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Get.back(),
            ),
            // actions: [
            //   IconButton(
            //     icon: const Icon(Icons.refresh),
            //     onPressed: controller.refreshOrderDetail,
            //   ),
            // ],
          ),
          body: Obx(() {
            if (controller.isLoading.value &&
                controller.orderDetail.value == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final order = controller.orderDetail.value;
            if (order == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/order_nonet.webp',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '加载失败',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
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
                    // _buildOrderStatusCard(order),

                    // const SizedBox(height: 20),

                    // 订单基本信息
                    _buildOrderInfoCard(order),

                    const SizedBox(height: 10),

                    // 商品列表
                    _buildOrderItemsCard(order), 

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


  /// 构建订单基本信息卡片
  Widget _buildOrderInfoCard(order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 订单信息标题
          Row(
            children: [
              Container(
                width: 2,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '订单信息',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 订单信息内容
          _buildInfoRow('取餐码:', order.pickupCode ?? '1324'),
          const SizedBox(height: 8),
          _buildInfoRow(
            '取餐时间:',
            order.formattedEstimatePickupTime ?? '9999-99-99 00:00:00',
          ),
          const SizedBox(height: 8),
          _buildInfoRow('备注:', order.remark ?? '海鲜过敏、小份、不要香菜、不要葱姜蒜'),
          const SizedBox(height: 8),
          _buildInfoRow('订单编号:', order.orderNo ?? '132805345879601452014'),
          const SizedBox(height: 8),
          _buildInfoRow('单据来源:', order.sourceName ?? '点餐机/服务员/收银端'),
          const SizedBox(height: 8),
          _buildInfoRow(
            '下单时间:',
            order.formattedOrderTime ?? '9999-99-99 00:00:00',
          ),
        ],
      ),
    );
  }

  /// 构建商品列表卡片
  Widget _buildOrderItemsCard(order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 商品信息标题
          Row(
            children: [
              Container(
                width: 2,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '商品详情',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.fastfood,
                                color: Colors.grey,
                              ),
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
                          // 敏感物图片显示在商品名字下方
                          if (item.allergens != null && item.allergens!.isNotEmpty)
                            Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: item.allergens!.map<Widget>((allergen) {
                                return CachedNetworkImage(
                                  imageUrl: allergen.icon!,
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => SizedBox.shrink(),
                                  errorWidget: (context, url, error) => SizedBox.shrink(),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 4),
                          if (item.optionsStr != null &&
                              item.optionsStr!.isNotEmpty)
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
                                fontSize: 10,
                                color: Color(0xff999999),
                              ),
                            ),
                          if (item.processStatusName != null &&
                              item.processStatusName!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0x33FF9027),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item.processStatusName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xffFF9027),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // 数量和价格
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          '¥${_getItemUnitPrice(item)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.quantityText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xff999999),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList()
          else
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Image.asset(
                    'assets/order_empty.webp',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '暂无详情',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '总份数 ',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xffFF1010),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
             _getTotalQuantity(controller.orderDetail.value?.details).toString(),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xffFF1010)),
          ),
          Spacer(),
          Text(
            '€',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xffFF1010)),
          ),
          Text(
            controller.totalAmount.toStringAsFixed(0),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xffFF1010)),
          ),
        ],
      ),
    );
  }

 
  /// 获取商品单价
  String _getItemUnitPrice(TakeawayOrderDetailItem item) {
    if (item.unitPrice != null && item.unitPrice!.isNotEmpty) {
      final price = double.tryParse(item.unitPrice!) ?? 0.0;
      return price.toStringAsFixed(0);
    }
    return item.unitPrice ?? '0';
  }

  /// 获取总数量
  int _getTotalQuantity(List<TakeawayOrderDetailItem>? items) {
    if (items == null || items.isEmpty) return 0;
    return items.fold<int>(0, (sum, item) => sum + (item.quantity ?? 0));
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 12,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.black : Color(0xff666666),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 16 : 12,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.red : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  
}
