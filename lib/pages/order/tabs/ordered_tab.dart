import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';
import 'package:order_app/pages/order/components/order_module_widget.dart';
import 'package:order_app/pages/order/components/custom_refresh_indicator.dart';
import 'package:order_app/pages/order/order_main_page.dart';

class OrderedTab extends StatefulWidget {
  const OrderedTab({super.key});

  @override
  State<OrderedTab> createState() => _OrderedTabState();
}

class _OrderedTabState extends State<OrderedTab> with AutomaticKeepAliveClientMixin {
  final OrderController controller = Get.find<OrderController>();

  @override
  bool get wantKeepAlive => true; // 保持页面状态

  @override
  void initState() {
    super.initState();
    // 加载已点订单数据（首次加载显示loading）
    _loadOrderedDataWithLoading();
    
    // 页面首次显示后再刷新一次数据，确保数据是最新的（不显示loading）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderedData();
    });
  }

  /// 加载已点订单数据（显示loading）
  Future<void> _loadOrderedDataWithLoading() async {
    if (controller.table.value?.tableId != null) {
      await controller.loadCurrentOrder(showLoading: true);
    }
  }

  /// 加载已点订单数据
  Future<void> _loadOrderedData() async {
    if (controller.table.value?.tableId != null) {
      await controller.loadCurrentOrder(showLoading: false);
    }
  }


  /// 构建主体内容
  Widget _buildMainContent() {
    return Expanded(
      child: Obx(() {
        if (controller.isLoadingOrdered.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RestaurantLoadingWidget(size: 40),
                // SizedBox(height: 16),
                // Text(
                //   '加载中...',
                //   style: TextStyle(
                //     fontSize: 16,
                //     color: Colors.grey[600],
                //   ),
                // ),
              ],
            ),
          );
        }

        if (controller.currentOrder.value == null) {
          return _buildEmptyState();
        }

        final order = controller.currentOrder.value!;
        if (order.details == null || order.details!.isEmpty) {
          return _buildEmptyState();
        }

        return CustomRefreshIndicator(
          onRefresh: _loadOrderedData,
          displacement: 50.0,
          color: Colors.orange,
          backgroundColor: Colors.white,
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: order.details!.length,
            itemBuilder: (context, index) {
              final orderDetail = order.details![index];
              return OrderModuleWidget(
                orderDetail: orderDetail,
                isLast: index == order.details!.length - 1,
              );
            },
          ),
        );
      }),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            '暂无已点订单',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '请先点餐',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          // 添加一个去点餐按钮
          GestureDetector(
            onTap: () {
              // 切换到点餐页面
              try {
                Get.find<OrderMainPageController>().switchToOrderTab();
              } catch (e) {
                print('❌ 切换到点餐页面失败: $e');
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '去点餐',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部汇总信息
  Widget _buildBottomSummary() {
    return Obx(() {
      final order = controller.currentOrder.value;
      if (order == null) return SizedBox.shrink();
      
      final quantity = order.quantity ?? 0;
      final totalAmount = order.totalAmount ?? 0.0;
      
      if (quantity == 0) return SizedBox.shrink();
      
      return Container(
        height: 70,
        padding: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              
              children: [
                Image.asset(
                  'assets/order_takeaway_price.webp',
                  width: 33,
                  height: 33,
                ),
                SizedBox(width: 8),
                Text(
                  '$quantity',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row( 
              children: [
                Text(
                  '￥',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，因为使用了AutomaticKeepAliveClientMixin
    
    return Container(
      color: Color(0xffF9F9F9),
      child: Column(
        children: [
          // 主体内容区域
          _buildMainContent(),
          // 底部汇总信息
          _buildBottomSummary(),
        ],
      ),
    );
  }
}