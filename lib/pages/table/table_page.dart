import 'package:flutter/material.dart';
import 'package:order_app/pages/table/card/table_card.dart';
import 'package:order_app/pages/table/table_controller.dart';
import 'package:get/get.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';
import 'package:order_app/components/skeleton_widget.dart';
import 'package:order_app/utils/restaurant_refresh_indicator.dart';

class TablePage extends StatefulWidget {
  @override
  _TablePageState createState() => _TablePageState();
}

class _TablePageState extends State<TablePage> with WidgetsBindingObserver {
  final TableController controller = Get.put(TableController());
  bool _shouldShowSkeleton = true; // 默认显示骨架图

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 检查是否应该显示骨架图
    _checkShouldShowSkeleton();
  }

  /// 检查是否应该显示骨架图
  void _checkShouldShowSkeleton() {
    // 如果已经有数据，说明不是首次进入，不显示骨架图
    if (controller.tabDataList.isNotEmpty && 
        controller.tabDataList[controller.selectedTab.value].isNotEmpty) {
      _shouldShowSkeleton = false;
      print('✅ 检测到现有数据，不显示骨架图');
    } else {
      print('✅ 首次进入或从登录页进入，显示骨架图');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 应用恢复时，检查是否应该显示骨架图
      _checkShouldShowSkeleton();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      appBar: AppBar(
        automaticallyImplyLeading: false, // 禁用自动返回按钮
        title: Text('桌台'),
        backgroundColor: Colors.white,
        centerTitle: true,
        shadowColor: Colors.grey.withOpacity(0.3),
        actions: [
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
      // 只有在应该显示骨架图且正在加载且没有数据时才显示骨架图
      if (_shouldShowSkeleton && controller.isLoading.value && data.isEmpty) {
        return const TablePageSkeleton();
      }
      
      // 如果数据加载完成，标记不再需要显示骨架图
      if (data.isNotEmpty) {
        _shouldShowSkeleton = false;
      }
      
      return RestaurantRefreshIndicator(
        onRefresh: () async {
          await controller.fetchDataForTab(tabIndex);
        },
        loadingColor: const Color(0xFFFF9027),
        child: CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: data.isEmpty
                  ? SliverFillRemaining(
                      child: controller.isLoading.value
                          ? Center(child: RestaurantLoadingWidget(size: 40))
                          : (controller.hasNetworkError.value ? _buildNetworkErrorState() : _buildEmptyState()),
                    )
                  : SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 13,
                        childAspectRatio: 1.33, // 根据UI设计稿调整：165/124 = 1.33
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

  /// 构建空状态
  Widget _buildEmptyState() {
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
            '暂无桌台',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFFF9027),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建网络错误状态
  Widget _buildNetworkErrorState() {
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
}
