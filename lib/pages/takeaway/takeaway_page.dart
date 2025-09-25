import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/takeaway/items/takeaway_item.dart';
import 'package:order_app/utils/center_tabbar.dart';
import 'package:order_app/pages/order/order_main_page.dart';
import 'package:order_app/pages/takeaway/components/menu_selection_modal_widget.dart';
import 'package:lib_domain/api/base_api.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:order_app/components/skeleton_widget.dart';
import 'takeaway_controller.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:order_app/utils/restaurant_refresh_indicator.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';
import 'package:order_app/utils/keyboard_utils.dart';

class TakeawayPage extends StatelessWidget {
  final TakeawayController controller = Get.put(TakeawayController());
  final List<String> tabs = ['未结账', '已结账'];

  TakeawayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Color(0xFFF9F9F9),
        appBar: CenteredTabBar(tabs: ['未结账', '已结账']),
        body: KeyboardUtils.buildDismissiblePage(
          child: Column(
            children: [
              // 搜索框
              _buildSearchBar(),
              // Tab内容
              Expanded(
                child: TabBarView(
                  children: [
                    // 未结账 Tab
                    _buildOrderList(0),
                    // 已结账 Tab
                    _buildOrderList(1),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  /// 构建搜索框
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: Color(0xffF5F5F5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: TextField(
          controller: controller.searchController,
          textAlignVertical: TextAlignVertical.center,
          textInputAction: TextInputAction.done,
          style: TextStyle(
            fontSize: 14,
            height: 1.0, // 设置行高为1.0确保文字垂直居中
          ),
          decoration: InputDecoration(
            hintText: "请输入取餐码",
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              height: 1.0, // 占位文字也设置行高为1.0
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.all(8.0), // 给图标添加内边距
              child: Image(
                image: AssetImage("assets/order_allergen_search.webp"),
                width: 16,
                height: 16,
              ),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 0, // 垂直内边距设为0，让textAlignVertical.center生效
            ),
            isDense: true, // 减少内部间距
            
          ),
          onChanged: (value) {
            try {
              if (value.isEmpty) {
                controller.clearSearch();
              }
            } catch (e) {
              print('Controller disposed during onChanged: $e');
            }
          },
          onSubmitted: (value) {
            try {
              if (value.isNotEmpty) {
                controller.searchByPickupCode(value);
              }
            } catch (e) {
              print('Controller disposed during onSubmitted: $e');
            }
          },
        ),
      ),
    );
  }

  /// 构建浮动按钮
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        // 显示菜单选择弹窗
        _showMenuSelectionModal();
      },
      backgroundColor: Color(0xFFFF9027),
      child: Icon(
        Icons.add,
        color: Colors.white,
        size: 36,
      ),
      mini: false,
      elevation: 4,
      shape: CircleBorder(),
    );
  }

  /// 显示菜单选择弹窗
  void _showMenuSelectionModal() async {
    final selectedMenu = await MenuSelectionModalWidget.showMenuSelectionModal(
      Get.context!,
    );
    
    if (selectedMenu != null) {
      // 执行开桌操作，传递完整的菜单信息
      _performOpenTable(selectedMenu);
    }
  }
  
  /// 执行开桌操作
  Future<void> _performOpenTable(TableMenuListModel selectedMenu) async {
    try {
      // 调用开桌接口
      final result = await BaseApi().openVirtualTable(menuId: selectedMenu.menuId!);

      if (result.isSuccess && result.data != null) {
        // 开桌成功，跳转到点餐页面，传递完整的菜单信息
        Get.to(
          () => OrderMainPage(),
          arguments: {
            'fromTakeaway': true,
            'table': result.data,
            'menu': selectedMenu,  // 传递完整的菜单信息
            'menu_id': selectedMenu.menuId,  // 保留menu_id用于兼容性
            'adult_count': (result.data?.currentAdult ?? 0) > 0 ? result.data!.currentAdult : result.data?.standardAdult ?? 1,
            'child_count': result.data?.currentChild ?? 0,
          },
        );
      } else {
        GlobalToast.error(result.msg ?? '未知错误');
      }
    } catch (e) {
      GlobalToast.error('网络错误: $e');
    }
  }

  /// 构建订单列表
  Widget _buildOrderList(int tabIndex) {
    return Obx(() {
      final orders = tabIndex == 0 ? controller.unpaidOrders : controller.paidOrders;
      final isRefreshing = tabIndex == 0 ? controller.isRefreshingUnpaid.value : controller.isRefreshingPaid.value;
      final hasMore = tabIndex == 0 ? controller.hasMoreUnpaid.value : controller.hasMorePaid.value;
      final hasNetworkError = tabIndex == 0 ? controller.hasNetworkErrorUnpaid.value : controller.hasNetworkErrorPaid.value;

      // 如果是首次加载且没有数据，显示骨架图（仅对未结账页面）
      if (orders.isEmpty && !isRefreshing && !hasNetworkError && tabIndex == 0) {
        return const TakeawayPageSkeleton();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: RestaurantRefreshIndicator(
          onRefresh: () => controller.refreshData(tabIndex),
          loadingColor: const Color(0xFFFF9027),
          child: orders.isEmpty && !isRefreshing
              ? (hasNetworkError ? _buildNetworkErrorView() : _buildEmptyView())
              : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    // 当滚动到底部时自动加载更多
                    if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                        hasMore && 
                        !controller.isLoadingMore.value) {
                      controller.loadMore(tabIndex);
                    }
                    return false;
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: orders.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == orders.length) {
                        // 加载更多指示器
                        return _buildLoadMoreIndicator(tabIndex);
                      }
                      return TakeawayItem(order: orders[index]);
                    },
                    separatorBuilder: (context, index) => 
                        const SizedBox(height: 10),
                  ),
                ),
        ),
      );
    });
  }

  /// 构建空视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/order_empty.webp',
            width: 180,
            height: 100,
          ),
          SizedBox(height: 8),
          Text(
            '暂无订单',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFFF9027),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建网络错误视图
  Widget _buildNetworkErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/order_nonet.webp',
            width: 180,
            height: 100,
          ),
          SizedBox(height: 8),
          Text(
            '暂无网络',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFFF9027),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建加载更多指示器
  Widget _buildLoadMoreIndicator(int tabIndex) {
    return Obx(() {
      final isLoadingMore = controller.isLoadingMore.value;
      
      if (isLoadingMore) {
        return Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: const RestaurantLoadingWidget(
            size: 30,
            color: Color(0xFFFF9027),
          ),
        );
      } else {
        return const SizedBox.shrink(); // 不显示任何内容
      }
    });
  }
}

