import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/pages/order/components/order_module_widget.dart';
import 'package:order_app/pages/order/utils/order_page_utils.dart';
import 'package:lib_base/utils/navigation_manager.dart';
import 'package:order_app/components/skeleton_widget.dart';
import 'package:order_app/widgets/base_list_page_widget.dart';

class OrderedPage extends BaseListPageWidget {
  const OrderedPage({super.key});

  @override
  State<OrderedPage> createState() => _OrderedPageState();
}

class _OrderedPageState extends BaseListPageState<OrderedPage> {
  final OrderController controller = Get.find<OrderController>();

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
  Widget? getNetworkErrorAction() {
    return Obx(() => GestureDetector(
      onTap: controller.isLoadingOrdered.value ? null : () async {
        await _loadOrderedDataWithLoading();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: controller.isLoadingOrdered.value ? Colors.grey : Colors.orange,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          controller.isLoadingOrdered.value ? '加载中...' : '重新加载',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ));
  }

  @override
  bool get shouldShowSkeleton => isLoading && !hasData;

  @override
  Widget buildSkeletonWidget() {
    return const OrderedPageSkeleton();
  }

  @override
  Widget buildLoadingWidget() {
    return const OrderedPageSkeleton();
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

  /// 处理返回按钮点击
  void _handleBackPressed() async {
    await NavigationManager.backToTablePage();
  }

  /// 构建顶部导航
  Widget _buildTopNavigation() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 18,
      ),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => _handleBackPressed(),
            child: Container(
              width: 32,
              height: 32,
              padding: EdgeInsets.all(5),
              child: Image.asset(
                'assets/order_dish_back.webp',
                fit: BoxFit.contain,
                width: 20,
                height: 20,
              ),
            ),
          ),
          SizedBox(width: 12),
          // 中间导航按钮组
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildNavButton('点餐', false),
                SizedBox(width: 20),
                _buildNavButton('已点', true),
              ],
            ),
          ),
          // 右侧刷新按钮
          GestureDetector(
            onTap: () => _loadOrderedData(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '刷新',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建导航按钮
  Widget _buildNavButton(String text, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: isSelected ? null : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.orange : Colors.black,
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget buildDataContent() {
    final order = controller.currentOrder.value!;
    return ListView.builder(
      padding: EdgeInsets.all(16),
      physics: AlwaysScrollableScrollPhysics(),
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

  /// 构建主体内容
  @override
  Widget buildMainContent() {
    return Expanded(
      child: Obx(() {
        if (isLoading) {
          return buildLoadingWidget();
        }

        if (hasNetworkError) {
          return SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Container(
              height: MediaQuery.of(context).size.height - 200,
              child: Center(
                child: buildNetworkErrorState(),
              ),
            ),
          );
        }

        if (!hasData) {
          return SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Container(
              height: MediaQuery.of(context).size.height - 200,
              child: Center(
                child: buildEmptyState(),
              ),
            ),
          );
        }

        return buildDataContent();
      }),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // 顶部导航栏
          _buildTopNavigation(),
          // 主体内容区域
          buildMainContent(),
        ],
      ),
    );
  }
}
