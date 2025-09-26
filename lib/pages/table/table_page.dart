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
  bool _isFromLogin = false; // 是否来自登录页面

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 检查是否来自登录页面，如果是则强制刷新数据
    _checkIfFromLogin();
    
    // 检查是否应该显示骨架图
    _checkShouldShowSkeleton();
  }

  /// 检查是否来自登录页面
  void _checkIfFromLogin() {
    // 简单检查：如果TabController的数据为空或者路由栈很简单，认为是新登录
    _isFromLogin = controller.tabDataList.isEmpty || 
                   controller.lobbyListModel.value.halls?.isEmpty == true;
    
    if (_isFromLogin) {
      print('✅ 检测到需要刷新数据（新登录或数据为空）');
      // 延迟执行强制刷新，确保页面完全初始化
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _forceRefreshData();
      });
    }
  }

  /// 强制刷新数据
  Future<void> _forceRefreshData() async {
    try {
      print('🔄 开始强制刷新桌台数据...');
      // 调用Controller的强制重置方法
      await controller.forceResetAllData();
      print('✅ 强制刷新桌台数据完成');
    } catch (e) {
      print('❌ 强制刷新桌台数据失败: $e');
    }
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
    print('🔄 应用生命周期状态变化: $state');
    
    if (state == AppLifecycleState.resumed) {
      // 应用从后台回到前台时，检查是否需要刷新数据
      print('✅ 应用回到前台，检查数据刷新');
      _checkShouldShowSkeleton();
      // 恢复轮询
      controller.resumePolling();
    } else if (state == AppLifecycleState.paused) {
      // 应用进入后台时暂停轮询
      print('⏸️ 应用进入后台，暂停轮询');
      controller.pausePolling();
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
                controller: controller.tabScrollController,
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
          // 手动刷新时重置轮询计时器
          controller.stopPolling();
          await controller.fetchDataForTab(tabIndex);
          // 刷新完成后重新启动轮询
          controller.startPolling();
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
