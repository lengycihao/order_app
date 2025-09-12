import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';
import 'package:order_app/pages/order/components/order_module_widget.dart';
import 'package:order_app/pages/order/components/custom_refresh_indicator.dart';
import 'package:lib_base/utils/navigation_manager.dart';

class OrderedPage extends StatefulWidget {
  const OrderedPage({super.key});

  @override
  State<OrderedPage> createState() => _OrderedPageState();
}

class _OrderedPageState extends State<OrderedPage> {
  final OrderController controller = Get.find<OrderController>();

  @override
  void initState() {
    super.initState();
    // 加载已点订单数据
    _loadOrderedData();
    
    // 页面首次显示后再刷新一次数据，确保数据是最新的
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderedData();
    });
  }

  /// 加载已点订单数据
  Future<void> _loadOrderedData() async {
    if (controller.table.value?.tableId != null) {
      await controller.loadCurrentOrder();
    }
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
                SizedBox(height: 16),
                Text(
                  '加载中...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.currentOrder.value == null) {
          return CustomRefreshIndicator(
            onRefresh: _loadOrderedData,
            color: Colors.orange,
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height - 200,
                child: Center(
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
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final order = controller.currentOrder.value!;
        if (order.details == null || order.details!.isEmpty) {
          return CustomRefreshIndicator(
            onRefresh: _loadOrderedData,
            color: Colors.orange,
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height - 200,
                child: Center(
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
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return CustomRefreshIndicator(
          onRefresh: _loadOrderedData,
          color: Colors.orange,
          backgroundColor: Colors.white,
          child: ListView.builder(
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
          ),
        );
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
          _buildMainContent(),
        ],
      ),
    );
  }
}
