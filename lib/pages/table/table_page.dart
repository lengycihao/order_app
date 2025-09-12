import 'package:flutter/material.dart';
import 'package:order_app/pages/table/card/table_card.dart';
import 'package:order_app/pages/table/table_controller.dart';
import 'package:get/get.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';

class TablePage extends StatelessWidget {
  final TableController controller = Get.put(TableController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 禁用自动返回按钮
        title: Text('桌台'),
        backgroundColor: Colors.white,
        centerTitle: true,
        shadowColor: Colors.grey.withOpacity(0.3),
        actions: [
          // WebSocket连接状态指示器
          Obx(() => Container(
            margin: EdgeInsets.only(right: 10),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: controller.isWebSocketConnected.value 
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: controller.isWebSocketConnected.value 
                      ? Colors.green 
                      : Colors.red,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  controller.isWebSocketConnected.value ? '在线' : '离线',
                  style: TextStyle(
                    fontSize: 12,
                    color: controller.isWebSocketConnected.value 
                      ? Colors.green 
                      : Colors.red,
                  ),
                ),
              ],
            ),
          )),
          GestureDetector(
            onTap: () => controller.toggleMergeMode(),
            child: Container(
              margin: EdgeInsets.only(right: 15),
              width: 48,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Color(0xffFF9027),
              ),
              alignment: Alignment.center,
              child: Text(
                '并桌',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        final halls = controller.lobbyListModel.value.halls ?? [];

        // 保证 tabDataList 与 halls 对齐
        while (controller.tabDataList.length < halls.length) {
          controller.tabDataList.add(<TableListModel>[].obs);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tab Row
            Container(
              color: Colors.transparent,

              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(halls.length, (index) {
                    final hallName = halls[index].hallName ?? '未知';
                    return Row(
                      children: [
                        SizedBox(width: 12),
                        tabButton(
                          hallName,
                          index,
                          halls[index].tableCount ?? 0,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            // PageView
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                itemCount: halls.length,
                itemBuilder: (context, index) {
                  return buildRefreshableGrid(
                    controller.tabDataList[index],
                    index,
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Tab 按钮
  Widget tabButton(String title, int index, int tableCount) {
    return Obx(() {
      bool selected = controller.selectedTab.value == index;
      return GestureDetector(
        onTap: () => controller.onTabTapped(index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$title($tableCount)',
                style: TextStyle(
                  color: selected ? Colors.orange : Colors.black,
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              SizedBox(height: 4),
              Container(
                width: 60,
                height: 2,
                decoration: BoxDecoration(
                  color: selected ? Colors.orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// 下拉刷新 + 加载状态 + 空数据提示 + Grid 间距优化
  Widget buildRefreshableGrid(RxList<TableListModel> data, int tabIndex) {
    return Obx(() {
      return RefreshIndicator(
        onRefresh: () async {
          await controller.fetchDataForTab(tabIndex);
        },
        child: CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: data.isEmpty
                  ? SliverFillRemaining(
                      child: controller.isLoading.value
                          ? Center(child: RestaurantLoadingWidget(size: 40))
                          : Center(child: Text('暂无数据')),
                    )
                  : SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 13,
                        childAspectRatio: 1.2,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => TableCard(
                          table: data[index],
                          tableModelList: controller.menuModelList,
                          isMergeMode: controller.isMergeMode.value,
                          isSelected: controller.selectedTables.contains(
                            data[index].tableId.toString(),
                          ),
                          onSelect: () => controller.toggleTableSelected(
                            data[index].tableId.toString(),
                          ),
                        ),
                        childCount: data.length,
                      ),
                    ),
            ),
          ],
        ),
      );
    });
  }
}
