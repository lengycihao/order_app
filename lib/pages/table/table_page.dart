import 'package:flutter/material.dart';
import 'package:order_app/pages/table/card/table_card.dart';
import 'package:order_app/pages/table/table_controller.dart';
import 'package:order_app/pages/table/state/table_page_state.dart';
import 'package:get/get.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:order_app/components/skeleton_widget.dart';
import 'package:order_app/utils/l10n_utils.dart';
import 'package:order_app/widgets/base_list_page_widget.dart';
import 'package:order_app/utils/pull_to_refresh_wrapper.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:lib_base/logging/logging.dart';

class TablePage extends BaseListPageWidget {
  @override
  _TablePageState createState() => _TablePageState();
}

class _TablePageState extends BaseListPageState<TablePage> with WidgetsBindingObserver {
  final TableControllerRefactored controller = Get.put(TableControllerRefactored());
  final TablePageState _pageState = TablePageState();
  // 为每个tab创建独立的RefreshController
  final Map<int, RefreshController> _refreshControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 初始化页面状态
    _initializePageState();
  }

  /// 初始化页面状态
  void _initializePageState() {
    // 检查是否来自登录页面
    final isFromLogin = _pageState.checkIfFromLogin(
      controller.tabDataList, 
      controller.lobbyListModel.value
    );
    
    if (isFromLogin) {
      // 延迟执行强制刷新，确保页面完全初始化
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _forceRefreshData();
      });
    } else {
      // 检查是否有部分数据（可能是从点餐页面返回）
      final halls = controller.lobbyListModel.value.halls ?? [];
      final hasPartialData = controller.tabDataList.isNotEmpty && halls.isNotEmpty;
      
      if (hasPartialData) {
        // 有部分数据，使用智能刷新
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _smartRefreshData();
        });
      } else {
        // 没有数据，检查是否需要刷新
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkAndRefreshDataIfNeeded();
        });
      }
    }
    
    // 更新骨架图状态
    _pageState.updateSkeletonState(
      controller.tabDataList, 
      controller.selectedTab.value
    );
  }

  /// 强制刷新数据
  Future<void> _forceRefreshData() async {
    try {
      logDebug('🔄 开始强制刷新桌台数据...', tag: 'TablePage');
      
      // 设置超时机制，确保不会一直显示骨架图
      await Future.any([
        controller.forceResetAllData(),
        Future.delayed(Duration(seconds: 10)), // 10秒超时
      ]);
      
      logDebug('✅ 强制刷新桌台数据完成', tag: 'TablePage');
      
      // 完成登录后的初始加载
      _pageState.completeLoginInitialLoading();
      
      // 数据加载完成后更新骨架图状态
      _pageState.updateSkeletonState(
        controller.tabDataList, 
        controller.selectedTab.value
      );
    } catch (e) {
      logError('❌ 强制刷新桌台数据失败: $e', tag: 'TablePage');
      // 即使失败也要完成登录后的初始加载，避免一直显示骨架图
      _pageState.completeLoginInitialLoading();
    }
  }
  
  /// 智能刷新数据（用于从点餐页面返回）
  Future<void> _smartRefreshData() async {
    try {
      logDebug('🔄 开始智能刷新桌台数据...', tag: 'TablePage');
      
      // 设置超时机制，避免长时间等待
      await Future.any([
        controller.smartResetData(),
        Future.delayed(Duration(seconds: 8)), // 8秒超时
      ]);
      
      logDebug('✅ 智能刷新桌台数据完成', tag: 'TablePage');
      
      // 数据加载完成后更新骨架图状态
      _pageState.updateSkeletonState(
        controller.tabDataList, 
        controller.selectedTab.value
      );
    } catch (e) {
      logError('❌ 智能刷新桌台数据失败: $e', tag: 'TablePage');
      // 即使失败也要更新骨架图状态，避免一直显示骨架图
      _pageState.updateSkeletonState(
        controller.tabDataList, 
        controller.selectedTab.value
      );
    }
  }

  /// 检查并刷新数据（如果需要）
  Future<void> _checkAndRefreshDataIfNeeded() async {
    try {
      // 检查大厅数据是否为空
      final halls = controller.lobbyListModel.value.halls ?? [];
      if (halls.isEmpty) {
        logDebug('🔄 检测到大厅数据为空，开始刷新...', tag: 'TablePage');
        await controller.getLobbyList();
      }
      
      // 检查当前tab的数据是否为空
      final currentTabIndex = controller.selectedTab.value;
      if (currentTabIndex < controller.tabDataList.length) {
        final currentTabData = controller.tabDataList[currentTabIndex];
        if (currentTabData.isEmpty && halls.isNotEmpty) {
          logDebug('🔄 检测到当前tab数据为空，开始刷新...', tag: 'TablePage');
          await controller.fetchDataForTab(currentTabIndex);
        }
      }
      
      // 更新骨架图状态
      _pageState.updateSkeletonState(
        controller.tabDataList, 
        controller.selectedTab.value
      );
    } catch (e) {
      logError('❌ 检查并刷新数据失败: $e', tag: 'TablePage');
    }
  }

  /// 获取或创建指定tab的RefreshController
  RefreshController _getRefreshController(int tabIndex) {
    if (!_refreshControllers.containsKey(tabIndex)) {
      _refreshControllers[tabIndex] = RefreshController(initialRefresh: false);
    }
    return _refreshControllers[tabIndex]!;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 释放所有RefreshController
    for (final refreshController in _refreshControllers.values) {
      refreshController.dispose();
    }
    _refreshControllers.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    logDebug('🔄 应用生命周期状态变化: $state', tag: 'TablePage');
    
    if (state == AppLifecycleState.resumed) {
      // 应用从后台回到前台时，检查是否需要刷新数据
      logDebug('✅ 应用回到前台，检查数据刷新', tag: 'TablePage');
      _pageState.updateSkeletonState(
        controller.tabDataList, 
        controller.selectedTab.value
      );
      // 恢复轮询 - 已关闭
      // controller.resumePolling();
    } else if (state == AppLifecycleState.paused) {
      // 应用进入后台时暂停轮询
      logDebug('⏸️ 应用进入后台，暂停轮询', tag: 'TablePage');
      controller.pausePolling();
    }
  }

  // 实现抽象类要求的方法
  @override
  bool get isLoading => controller.isLoading.value;

  @override
  bool get hasNetworkError {
    // 如果是登录后的初始加载期间，不显示网络错误状态
    if (_pageState.isLoginInitialLoading) {
      return false;
    }
    return controller.hasNetworkError.value;
  }

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
  bool get shouldShowSkeleton {
    // 如果是登录后的初始加载期间，优先显示骨架图
    if (_pageState.isLoginInitialLoading) {
      return true;
    }
    return _pageState.shouldShowSkeleton;
  }

  @override
  Future<void> onRefresh() async {
    final currentTabIndex = controller.selectedTab.value;
    await controller.fetchDataForTab(currentTabIndex);
    
    // 刷新完成后更新骨架图状态
    _pageState.updateSkeletonState(
      controller.tabDataList, 
      currentTabIndex
    );
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
        title: Text(context.l10n.table),
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
                context.l10n.more,
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
        final shouldShowSkeleton = _pageState.shouldShowSkeletonForTab(controller.tabDataList, controller.selectedTab.value);
        
        // 优先显示网络错误状态，避免在重新加载时闪烁
        if (hasNetworkError) {
          return buildNetworkErrorState();
        }
        
        if (shouldShowSkeleton && isLoading) {
          return buildSkeletonWidget();
        }
        if (isLoading) {
          return buildLoadingWidget();
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
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$title($tableCount)',
                style: TextStyle(
                  color: selected ? Colors.orange : Colors.black,
                  fontSize: selected ? 16 : 14,
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
      final refreshController = _getRefreshController(tabIndex);
      return PullToRefreshWrapper(
        controller: refreshController,
        onRefresh: () async {
          try {
            // 手动刷新时重置轮询计时器
            controller.stopPolling();
            // 只刷新桌台数据，菜单数据相对稳定，不需要频繁刷新
            await controller.fetchDataForTab(tabIndex);
            // 如果菜单数据为空，才尝试获取菜单数据
            if (controller.menuModelList.isEmpty) {
              await controller.getMenuList();
            }
            // 通知刷新完成
            refreshController.refreshCompleted();
            // 刷新完成后重新启动轮询 - 已关闭
            // controller.startPolling();
          } catch (e) {
            logError('❌ 刷新失败: $e', tag: 'TablePage');
            // 刷新失败也要通知完成
            refreshController.refreshFailed();
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
                        childAspectRatio: 1.4, // 调整宽高比以避免越界
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
  String getEmptyStateText() => context.l10n.noData;

  @override
  String getNetworkErrorText() => context.l10n.networkErrorPleaseTryAgain;
  
  /// 重写空状态操作按钮
  @override
  Widget? getEmptyStateAction() {
    return ElevatedButton(
      onPressed: () async {
        // 重新加载大厅数据
        await controller.getLobbyList();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF9027),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        context.l10n.loadAgain,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
  
  /// 重写网络错误状态操作按钮
  @override
  Widget? getNetworkErrorAction() {
    return Obx(() => ElevatedButton(
      onPressed: controller.isLoading.value ? null : () async {
        // 重新加载大厅数据，但不显示加载状态以避免闪烁
        await controller.getLobbyList();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF9027),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        controller.isLoading.value ? context.l10n.loadingData : context.l10n.loadAgain,
        style: TextStyle(fontSize: 14),
      ),
    ));
  }

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
