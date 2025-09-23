import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/takeaway/items/takeaway_item.dart';
import 'package:order_app/utils/center_tabbar.dart';
import 'takeaway_controller.dart';

class TakeawayPage extends StatelessWidget {
  final TakeawayController controller = Get.put(TakeawayController());
  final List<String> tabs = ['未结账', '已结账'];

  TakeawayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: CenteredTabBar(tabs: ['未结账', '已结账']),
        body: TabBarView(
          children: [
            // 未结账 Tab
            _buildOrderList(0),
            // 已结账 Tab
            _buildOrderList(1),
          ],
        ),
      ),
    );
  }

  /// 构建订单列表
  Widget _buildOrderList(int tabIndex) {
    return Obx(() {
      final orders = tabIndex == 0 ? controller.unpaidOrders : controller.paidOrders;
      final isRefreshing = tabIndex == 0 ? controller.isRefreshingUnpaid.value : controller.isRefreshingPaid.value;
      final hasMore = tabIndex == 0 ? controller.hasMoreUnpaid.value : controller.hasMorePaid.value;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => controller.refreshData(tabIndex),
              child: orders.isEmpty && !isRefreshing
                  ? _buildEmptyView()
                  : ListView.separated(
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
            if (isRefreshing && orders.isEmpty)
              const Center(child: CircularProgressIndicator()),
            if (isRefreshing)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      );
    });
  }

  /// 构建空视图
  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            '暂无订单',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建加载更多指示器
  Widget _buildLoadMoreIndicator(int tabIndex) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: InkWell(
        onTap: () => controller.loadMore(tabIndex),
        child: const Text(
          '加载更多',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
