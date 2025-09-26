import 'package:flutter/material.dart';
import 'package:order_app/pages/table/card/table_card.dart';
import 'package:order_app/pages/table/table_controller.dart';
import 'package:get/get.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:order_app/components/skeleton_widget.dart';
import 'package:order_app/widgets/base_list_page_widget.dart';
import 'package:order_app/utils/smart_refresh_wrapper.dart';

class TablePage extends BaseListPageWidget {
  @override
  _TablePageState createState() => _TablePageState();
}

class _TablePageState extends BaseListPageState<TablePage> with WidgetsBindingObserver {
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

  // 实现抽象类要求的方法
  @override
  bool get isLoading => controller.isLoading.value;

  @override
  bool get hasNetworkError => controller.hasNetworkError.value;

  @override
  bool get hasData {
    final halls = controller.lobbyListModel.value.halls ?? [];
    if (halls.isEmpty) return false;
    
    // 检查当前选中的tab是否有数据
    final currentTabIndex = controller.selectedTab.value;
    if (currentTabIndex < controller.tabDataList.length) {
      return controller.tabDataList[currentTabIndex].isNotEmpty;
    }
    return false;
  }
  
  @override
  bool get shouldShowSkeleton => _shouldShowSkeleton;

  @override
  Future<void> onRefresh() async {
    final currentTabIndex = controller.selectedTab.value;
    await controller.fetchDataForTab(currentTabIndex);
  }
  
  @override
  Widget buildSkeletonWidget() {
    return const TablePageSkeleton();
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
        shadowColor: Colors.grey.withValues(alpha: 0.3),
        actions: [
          // 预加载状态调试按钮（仅在调试模式下显示）
          // 如需启用调试功能，将下面的false改为true
          // if (false) // 设置为true可显示调试按钮
          //   GestureDetector(
          //     onTap: () => _showPreloadStatus(),
          //     child: Container(
          //       margin: EdgeInsets.only(right: 8),
          //       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //       decoration: BoxDecoration(
          //         borderRadius: BorderRadius.circular(12),
          //         color: Colors.blue.withOpacity(0.8),
          //       ),
          //       child: Text(
          //         '预加载状态',
          //         style: TextStyle(color: Colors.white, fontSize: 12),
          //       ),
          //     ),
          //   ),
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
      body: _buildTablePageBody(),
    );
  }

  /// 构建桌台页面主体内容
  Widget _buildTablePageBody() {
    return Obx(() {
      final halls = controller.lobbyListModel.value.halls ?? [];
      
      // 如果没有大厅数据，显示空状态
      if (halls.isEmpty) {
        if (shouldShowSkeleton && isLoading) {
          return buildSkeletonWidget();
        }
        if (isLoading) {
          return buildLoadingWidget();
        }
        if (hasNetworkError) {
          return buildNetworkErrorState();
        }
        return buildEmptyState();
      }

      // 有大厅数据时，显示带tab的内容
      return buildDataContent();
    });
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
      // 如果数据加载完成，标记不再需要显示骨架图
      if (data.isNotEmpty) {
        _shouldShowSkeleton = false;
      }
      
      return SmartRefreshWrapper(
        onRefresh: () async {
          try {
            // 手动刷新时重置轮询计时器
            controller.stopPolling();
            await controller.fetchDataForTab(tabIndex);
            // 刷新完成后重新启动轮询
            controller.startPolling();
          } catch (e) {
            print('❌ 刷新失败: $e');
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: data.isEmpty
                  ? SliverFillRemaining(
                      child: controller.isLoading.value
                          ? buildLoadingWidget()
                          : (controller.hasNetworkError.value ? buildNetworkErrorState() : buildEmptyState()),
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

  @override
  String getEmptyStateText() => '暂无桌台';

  @override
  String getNetworkErrorText() => '暂无网络';

  @override
  Widget buildDataContent() {
    return Obx(() {
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
                return _buildTabContent(index);
              },
            ),
          ),
        ],
      );
    });
  }

  /// 构建单个tab的内容
  Widget _buildTabContent(int tabIndex) {
    return Obx(() {
      final data = controller.tabDataList[tabIndex];
      final isCurrentTab = controller.selectedTab.value == tabIndex;
      
      // 如果当前tab正在加载且没有数据，显示加载状态
      if (isCurrentTab && controller.isLoading.value && data.isEmpty) {
        return buildLoadingWidget();
      }
      
      // 如果当前tab有网络错误，显示网络错误状态
      if (isCurrentTab && controller.hasNetworkError.value && data.isEmpty) {
        return buildNetworkErrorState();
      }
      
      // 无论是否有数据，都使用可刷新的网格布局
      // 这样空数据状态也能进行下拉刷新
      return buildRefreshableGrid(data, tabIndex);
    });
  }

  /// 显示预加载状态（调试用）
  // ignore: unused_element
  void _showPreloadStatus() {
    final status = controller.getPreloadStatus();
    final halls = controller.lobbyListModel.value.halls ?? [];
    
    String message = '预加载状态:\n';
    message += '预加载范围: ${status['maxPreloadRange']}\n';
    message += '已预加载: ${status['preloadedTabs']}\n';
    message += '正在预加载: ${status['preloadingTabs']}\n\n';
    
    message += '各Tab状态:\n';
    for (int i = 0; i < halls.length; i++) {
      final hallName = halls[i].hallName ?? '未知';
      final isPreloaded = controller.isTabPreloaded(i);
      final isPreloading = controller.isTabPreloading(i);
      final hasData = controller.tabDataList[i].isNotEmpty;
      
      String tabStatus = '';
      if (isPreloading) {
        tabStatus = '预加载中';
      } else if (isPreloaded) {
        tabStatus = '已预加载';
      } else if (hasData) {
        tabStatus = '已加载';
      } else {
        tabStatus = '未加载';
      }
      
      message += 'Tab $i ($hallName): $tabStatus\n';
    }
    
    Get.dialog(
      AlertDialog(
        title: Text('预加载状态'),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }
}
