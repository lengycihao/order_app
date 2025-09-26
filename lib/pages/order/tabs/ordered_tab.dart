import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/pages/order/components/order_module_widget.dart';
import 'package:order_app/pages/order/order_main_page.dart';
import 'package:order_app/pages/order/utils/order_page_utils.dart';
import 'package:order_app/widgets/base_list_page_widget.dart';

class OrderedTab extends BaseListPageWidget {
  const OrderedTab({super.key});

  @override
  State<OrderedTab> createState() => _OrderedTabState();
}

class _OrderedTabState extends BaseListPageState<OrderedTab> with AutomaticKeepAliveClientMixin {
  final OrderController controller = Get.find<OrderController>();

  @override
  bool get wantKeepAlive => true; // 保持页面状态

  // 实现基类抽象方法
  @override
  bool get isLoading => controller.isLoadingOrdered.value;

  @override
  bool get hasNetworkError => controller.hasNetworkErrorOrdered.value;

  @override
  bool get hasData => OrderPageUtils.hasOrderData(controller.currentOrder.value);

  @override
  Future<void> onRefresh() async {
    // 不需要下拉刷新功能
  }

  @override
  String getEmptyStateText() => '暂无已点订单';

  @override
  bool get shouldShowSkeleton => isLoading && !hasData;

  @override
  Widget buildSkeletonWidget() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 3, // 显示3个骨架项
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 菜品名称骨架
              Container(
                height: 20,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 8),
              // 价格和数量骨架
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 16,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 16,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget? getEmptyStateAction() {
    return GestureDetector(
      onTap: () {
        // 切换到点餐页面
        final mainPageController = OrderPageUtils.getControllerSafely<OrderMainPageController>();
        if (mainPageController != null) {
          mainPageController.switchToOrderTab();
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
    );
  }

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
    await OrderPageUtils.loadOrderData(
      controller: controller,
      tableId: controller.table.value?.tableId.toString() ?? '',
      showLoading: true,
    );
  }

  /// 加载已点订单数据
  Future<void> _loadOrderedData() async {
    await OrderPageUtils.loadOrderData(
      controller: controller,
      tableId: controller.table.value?.tableId.toString() ?? '',
      showLoading: false,
    );
  }


  @override
  Widget buildDataContent() {
    final order = controller.currentOrder.value!;
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: order.details!.length,
      itemBuilder: (context, index) {
        final orderDetail = order.details![index];
        return OrderModuleWidget(
          orderDetail: orderDetail,
          isLast: index == order.details!.length - 1,
        );
      },
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
              color: Colors.black.withValues(alpha: 0.05),
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
                  '$totalAmount',
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
          Expanded(
            child: _buildOrderedTabContent(),
          ),
          // 底部汇总信息
          _buildBottomSummary(),
        ],
      ),
    );
  }

  /// 构建已点订单页面内容
  Widget _buildOrderedTabContent() {
    return Obx(() {
      // 如果应该显示骨架图且正在加载且没有数据，显示骨架图
      if (shouldShowSkeleton && isLoading && !hasData) {
        return buildSkeletonWidget();
      }

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
    });
  }
}