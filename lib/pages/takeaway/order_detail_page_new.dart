import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:order_app/utils/l10n_utils.dart';
import 'order_detail_controller_new.dart';
import 'model/takeaway_order_detail_model.dart';
import 'package:order_app/widgets/base_list_page_widget.dart';

class OrderDetailPageNew extends BaseDetailPageWidget {
  const OrderDetailPageNew({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrderDetailControllerNew());
    return _OrderDetailPageState(controller: controller).build(context);
  }
}

class _OrderDetailPageState extends BaseDetailPageState<OrderDetailPageNew> {
  final OrderDetailControllerNew controller;

  _OrderDetailPageState({required this.controller});

  @override
  bool get isLoading => controller.isLoading.value;

  @override
  bool get hasNetworkError => controller.orderDetail.value == null && !isLoading;

  @override
  bool get hasData => controller.orderDetail.value != null;

  @override
  Future<void> onRefresh() => controller.refreshOrderDetail();

  @override
  String getEmptyStateText() => Get.context!.l10n.noData;

  @override
  Widget buildDataContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 订单基本信息
        _buildOrderInfoCard(controller.orderDetail.value!),

        const SizedBox(height: 10),

        // 商品列表
        _buildOrderItemsCard(controller.orderDetail.value!),

        const SizedBox(height: 20), // 底部预留空间
      ],
    );
  }

  Widget build(BuildContext context) {
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
      ),
      body: Obx(() {
        if (isLoading && !hasData) {
          return buildLoadingWidget();
        }

        if (hasNetworkError) {
          return buildNetworkErrorState();
        }

        if (!hasData) {
          return buildEmptyState();
        }

        return buildDataContent();
      }),
      bottomNavigationBar: Obx(() => _buildBottomActions(controller)),
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
                Text(
                Get.context!.l10n.orderInformation,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 订单信息内容
          _buildInfoRow('${Get.context!.l10n.pickupCode}:', order.pickupCode ?? '1324'),
          const SizedBox(height: 8),
          _buildInfoRow('${Get.context!.l10n.remarks}：', order.remark ?? ''),
          const SizedBox(height: 8),
          _buildInfoRow('${Get.context!.l10n.orderNo}:', order.orderNo ?? ''),
          const SizedBox(height: 8),
          _buildInfoRow('${Get.context!.l10n.orderSourceNew}:', order.sourceName ?? ''),
          const SizedBox(height: 8),
          _buildInfoRow(
            '${Get.context!.l10n.orderPlacementTime}:',
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
               Text(
                Get.context!.l10n.productDetails,
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
                                  placeholder: (context, url) => Image.asset(
                                    'assets/order_minganwu_place.webp',
                                    width: 16,
                                    height: 16,
                                    fit: BoxFit.contain,
                                  ),
                                  errorWidget: (context, url, error) => Image.asset(
                                    'assets/order_minganwu_place.webp',
                                    width: 16,
                                    height: 16,
                                    fit: BoxFit.contain,
                                  ),
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
                              '${Get.context!.l10n.remarks}：${item.remark}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xff999999),
                              ),
                            ),
                          if (item.cookingStatusName != null &&
                              item.cookingStatusName!.isNotEmpty)
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
                                item.cookingStatusName,
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
                    width: 180,
                    height: 100,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '暂无详情',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF9027),
                    ),
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
          // 替换总份数文字为图标
          Image.asset(
            'assets/order_takeaway_price.webp',
            width: 36,
            height: 36,
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
            '${controller.totalAmount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xffFF1010)),
          ),
        ],
      ),
    );
  }

 
  /// 获取商品单价
  String _getItemUnitPrice(TakeawayOrderDetailItem item) {
    if (item.unitPrice != null && item.unitPrice!.isNotEmpty) {
      return item.unitPrice!;
    }
    return '0';
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
            // width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 12,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.black : Color(0xff666666),
              ),
            ),
          ),
          const SizedBox(width: 8),
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
