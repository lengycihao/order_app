import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/takeaway/items/takeaway_item.dart';
import 'package:order_app/utils/center_tabbar.dart';
import 'takeaway_controller.dart';

class TakeawayPage extends StatelessWidget {
  final TakeawayController controller = Get.put(TakeawayController());
  final List<String> tabs = ['未结账', '已结账'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: CenteredTabBar(tabs: ['未结账', '已结账']),
        body: TabBarView(
          children: [
            // 未结账 Tab
            Obx(
              () => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () => controller.refreshData(0),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: controller.allItems.length,
                        itemBuilder: (context, index) {
                          return TakeawayItem(
                            order: controller.allItems[index],
                          );
                        },
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 10), // item 间距
                      ),
                    ),
                    if (controller.isRefreshingAll.value)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            // 已结账 Tab
            Obx(
              () => Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () => controller.refreshData(1),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: controller.takeawayItems.length,
                      itemBuilder: (context, index) {
                        return TakeawayItem(
                          order: controller.takeawayItems[index],
                        );
                      },
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 10), // item 间距
                    ),
                  ),
                  if (controller.isRefreshingTakeaway.value)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Get.snackbar('提示', '点击了浮动按钮');
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
