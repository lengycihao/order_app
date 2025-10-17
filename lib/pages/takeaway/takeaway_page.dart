import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/takeaway/items/takeaway_item.dart';
import 'package:order_app/utils/center_tabbar.dart';
import 'package:order_app/pages/order/order_main_page.dart';
import 'package:order_app/components/skeleton_widget.dart';
import 'package:order_app/utils/l10n_utils.dart';
import 'takeaway_controller.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';
import 'package:order_app/utils/keyboard_utils.dart';
import 'package:order_app/widgets/base_list_page_widget.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' hide RefreshIndicator;
import 'package:lib_base/logging/logging.dart';

class TakeawayPage extends BaseListPageWidget {
  final List<String> tabs = [Get.context!.l10n.unpaid, Get.context!.l10n.paid];

  TakeawayPage({super.key});

  @override
  _TakeawayPageState createState() => _TakeawayPageState();
}

class _TakeawayPageState extends BaseListPageState<TakeawayPage> with TickerProviderStateMixin {
  late TakeawayController controller;
  late TabController _tabController;
  int _currentTabIndex = 0;
  // 为每个标签页创建独立的RefreshController
  final RefreshController _unpaidRefreshController = RefreshController();
  final RefreshController _paidRefreshController = RefreshController();
  
  // 可拖动按钮的位置 - 使用null表示未初始化
  double? _fabX;
  double? _fabY;
  bool _fabInitialized = false;

  @override
  void initState() {
    super.initState();
    logDebug('🚀 外卖页面初始化开始', tag: 'TakeawayPage');
    
    // 使用 Get.put 但设置标签，方便管理
    controller = Get.put(TakeawayController(), tag: 'takeaway_page');
    _tabController = TabController(length: widget.tabs.length, vsync: this);
    // 监听tab切换（包括滑动和点击）
    _tabController.addListener(() {
      // 使用animation来获取实时的tab位置，支持滑动切换
      final animationValue = _tabController.animation?.value ?? _tabController.index.toDouble();
      final newIndex = animationValue.round();
      
      // 只有当tab完全切换到新位置时才触发
      if (newIndex != _currentTabIndex && !_tabController.indexIsChanging) {
        logDebug('📱 Tab切换: $_currentTabIndex -> $newIndex (滑动: ${_tabController.indexIsChanging})', tag: 'TakeawayPage');
        _currentTabIndex = newIndex;
        // 通知控制器tab切换，触发数据加载
        controller.onTabChanged(_currentTabIndex);
      }
    });
    
    logDebug('✅ 外卖页面初始化完成', tag: 'TakeawayPage');
    
    // 延迟一帧后检查数据状态，确保初始化完成后数据能正确展示
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkInitialDataState();
    });
  }
  
  /// 检查初始数据状态
  Future<void> _checkInitialDataState() async {
    logDebug('🔍 检查初始数据状态 - 未结账: ${controller.unpaidOrders.length}, 已结账: ${controller.paidOrders.length}', tag: 'TakeawayPage');
    logDebug('🔍 当前tab: $_currentTabIndex, 未结账加载状态: ${controller.isRefreshingUnpaid.value}, 已结账加载状态: ${controller.isRefreshingPaid.value}', tag: 'TakeawayPage');
    
    // 强制触发数据加载，确保页面有数据
    logDebug('🔄 强制触发数据加载', tag: 'TakeawayPage');
    await controller.refreshData(_currentTabIndex);
    
    // 再次检查数据状态
    logDebug('🔍 数据加载后状态 - 未结账: ${controller.unpaidOrders.length}, 已结账: ${controller.paidOrders.length}', tag: 'TakeawayPage');
  }

  /// 初始化浮动按钮位置
  void _initializeFabPosition() {
    if (!_fabInitialized) {
      final screenSize = MediaQuery.of(context).size;
      _fabX = screenSize.width - 72; // 距离右边16px + 按钮宽度56px
      _fabY = screenSize.height - 240; // 原始位置：距离底部200px + 按钮高度56px - 16px = 240px
      _fabInitialized = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _unpaidRefreshController.dispose();
    _paidRefreshController.dispose();
    
    // 安全地删除控制器
    try {
      if (Get.isRegistered<TakeawayController>(tag: 'takeaway_page')) {
        Get.delete<TakeawayController>(tag: 'takeaway_page');
      }
    } catch (e) {
      logError('Error disposing TakeawayController: $e', tag: 'TakeawayPage');
    }
    
    super.dispose();
  }

  // 实现抽象类要求的方法
  @override
  bool get isLoading {
    if (_currentTabIndex == 0) {
      return controller.isRefreshingUnpaid.value;
    } else {
      return controller.isRefreshingPaid.value;
    }
  }

  @override
  bool get hasNetworkError {
    if (_currentTabIndex == 0) {
      return controller.hasNetworkErrorUnpaid.value;
    } else {
      return controller.hasNetworkErrorPaid.value;
    }
  }

  @override
  bool get hasData {
    if (_currentTabIndex == 0) {
      final hasUnpaidData = controller.unpaidOrders.isNotEmpty;
      logDebug('📊 未结账页面数据状态: $hasUnpaidData, 订单数量: ${controller.unpaidOrders.length}', tag: 'TakeawayPage');
      return hasUnpaidData;
    } else {
      final hasPaidData = controller.paidOrders.isNotEmpty;
      logDebug('📊 已结账页面数据状态: $hasPaidData, 订单数量: ${controller.paidOrders.length}', tag: 'TakeawayPage');
      return hasPaidData;
    }
  }
  
  @override
  bool get shouldShowSkeleton {
    // 只有在首次加载且没有数据时才显示骨架图
    // 参考桌台页面实现，避免在有数据时刷新出现骨架图
    final currentOrders = _currentTabIndex == 0 ? controller.unpaidOrders : controller.paidOrders;
    final isCurrentTabLoading = _currentTabIndex == 0 ? controller.isRefreshingUnpaid.value : controller.isRefreshingPaid.value;
    
    // 如果已经有数据了，即使在刷新也不显示骨架图
    if (currentOrders.isNotEmpty) {
      return false;
    }
    
    // 只有在正在加载且没有数据时才显示骨架图
    return isCurrentTabLoading && currentOrders.isEmpty;
  }

  @override
  Future<void> onRefresh() async {
    logDebug('🔄 用户手动刷新页面', tag: 'TakeawayPage');
    await controller.refreshData(_currentTabIndex);
  }
  
  /// 强制刷新所有数据（用于订单状态变更后）
  Future<void> forceRefreshAll() async {
    logDebug('🔄 强制刷新所有外卖数据', tag: 'TakeawayPage');
    await controller.forceRefresh();
  }
  
  @override
  Widget buildSkeletonWidget() {
    return const TakeawayPageSkeleton();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent, // 最外层透明背景，完全不显示
      child: DefaultTabController(
        length: widget.tabs.length,
        child: Scaffold(
        backgroundColor: Colors.transparent, // 改为透明背景，完全不显示
        appBar: CenteredTabBar(
          tabs: [context.l10n.unpaid, context.l10n.paid],
          controller: _tabController,
        ),
        body: Stack(
          children: [
            KeyboardUtils.buildDismissiblePage(
              child: _buildTakeawayPageBody(),
            ),
            _buildDraggableFloatingActionButton(),
          ],
        ),
        ), // 结束 Scaffold
      ), // 结束 DefaultTabController
    ); // 结束 Container
  }

  /// 构建外卖页面主体内容
  Widget _buildTakeawayPageBody() {
    return Container(
      color: Colors.transparent, // 确保整个页面体的背景是透明
      child: Obx(() {
      // 添加调试信息
      logDebug('🎨 页面渲染状态 - hasData: $hasData, isLoading: $isLoading, hasNetworkError: $hasNetworkError, shouldShowSkeleton: $shouldShowSkeleton', tag: 'TakeawayPage');
      
      // 优先显示网络错误状态
      if (hasNetworkError) {
        logDebug('🎨 显示网络错误状态', tag: 'TakeawayPage');
        return _buildContentWithEmptyState(isNetworkError: true);
      }

      // 如果应该显示骨架图且正在加载，显示带搜索框的骨架图
      if (shouldShowSkeleton && isLoading) {
        logDebug('🎨 显示骨架图', tag: 'TakeawayPage');
        return _buildContentWithSkeleton();
      }

      // 如果正在加载但没有数据（非骨架图情况），显示加载状态
      if (isLoading && !hasData) {
        logDebug('🎨 显示加载状态', tag: 'TakeawayPage');
        return buildLoadingWidget();
      }

      // 始终显示TabBarView内容，即使没有数据也要显示，这样才能横向滑动
      logDebug('🎨 显示TabBarView内容', tag: 'TakeawayPage');
      return buildDataContent();
      }),
    );
  }

  /// 构建带搜索框的骨架图内容
  Widget _buildContentWithSkeleton() {
    return Column(
      children: [
        // 显示真实的搜索框
        _buildSearchBar(),
        // 列表区域显示骨架图
        Expanded(
          child: Container(
            color: Colors.transparent,
            child: const TakeawayListSkeleton(), // 使用新的列表骨架图
          ),
        ),
      ],
    );
  }

  /// 构建带搜索框的空状态内容
  Widget _buildContentWithEmptyState({required bool isNetworkError}) {
    return Column(
      children: [
        // 显示真实的搜索框
        _buildSearchBar(),
        // 列表区域显示空状态
        Expanded(
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    isNetworkError ? 'assets/order_nonet.webp' : 'assets/order_empty.webp',
                    width: 180,
                    height: 100,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isNetworkError ? context.l10n.networkErrorPleaseTryAgain : context.l10n.noData,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF9027),
                    ),
                  ),
                  if (isNetworkError) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        // 重新加载当前tab的数据
                        await controller.refreshData(_currentTabIndex);
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
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建搜索框
  Widget _buildSearchBar() {
    return GetBuilder<TakeawayController>(
      tag: 'takeaway_page',
      builder: (controller) {
        // 如果控制器已被释放，返回空容器
        if (!Get.isRegistered<TakeawayController>(tag: 'takeaway_page')) {
          return Container();
        }
        
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
               textInputAction: TextInputAction.search,
              style: TextStyle(
                fontSize: 14,
                height: 1.0, // 设置行高为1.0确保文字垂直居中
              ),
              decoration: InputDecoration(
                hintText: context.l10n.pleaseEnterPickupCode,
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
                   // 检查控制器是否仍然有效
                   if (Get.isRegistered<TakeawayController>(tag: 'takeaway_page')) {
                     // 使用防抖搜索，避免频繁请求
                     if (value.isNotEmpty) {
                       controller.debouncedSearch(value);
                     } else {
                       controller.clearSearch();
                     }
                   }
                 } catch (e) {
                   logError('Controller disposed during onChanged: $e', tag: 'TakeawayPage');
                 }
               },
              onSubmitted: (value) {
                try {
                  // 检查控制器是否仍然有效
                  if (Get.isRegistered<TakeawayController>(tag: 'takeaway_page')) {
                    if (value.isNotEmpty) {
                      controller.searchByPickupCode(value);
                    }
                  }
                } catch (e) {
                  logError('Controller disposed during onSubmitted: $e', tag: 'TakeawayPage');
                }
              },
            ),
          ),
        );
      },
    );
  }

  /// 构建可拖动的浮动按钮
  Widget _buildDraggableFloatingActionButton() {
    // 在第一次构建时初始化位置
    _initializeFabPosition();
    
    // 如果位置还未初始化，不显示按钮（避免闪现）
    if (_fabX == null || _fabY == null) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      left: _fabX!,
      top: _fabY!,
      child: Obx(() => _DraggableFab(
        onTap: _performVirtualTableOpen,
        isLoading: controller.isVirtualTableOpening.value,
        onDragUpdate: (details) {
          // 拖动过程中实时更新位置
          final screenSize = MediaQuery.of(context).size;
          final maxY = screenSize.height - 100; // 距离底部100px，避免被tab遮挡
          
          // 使用全局位置减去按钮半径来得到左上角位置
          final newX = (details.globalPosition.dx - 28).clamp(0.0, screenSize.width - 56);
          final newY = (details.globalPosition.dy - 28).clamp(0.0, maxY);
          
          setState(() {
            _fabX = newX;
            _fabY = newY;
          });
        },
        onDragEnd: (details) {
          // 拖动结束时的最终位置调整（如果需要的话）
          final screenSize = MediaQuery.of(context).size;
          final maxY = screenSize.height - 230; // 距离底部100px，避免被tab遮挡
          
          setState(() {
            // 确保最终位置在有效范围内
            _fabX = _fabX!.clamp(0.0, screenSize.width - 56);
            _fabY = _fabY!.clamp(0.0, maxY);
          });
        },
      )),
    );
  }

  /// 直接执行开桌操作（无需选择菜单）
  void _performVirtualTableOpen() async {
    _performOpenTable();
  }
  
  /// 执行开桌操作
  Future<void> _performOpenTable() async {
    try {
      // 使用controller的虚拟开桌方法（loading状态已在controller中管理）
      final result = await controller.performVirtualTableOpen();
      
      // 严格检查：必须有返回值且成功标记为true且有有效的桌台数据
      if (result != null && 
          result['success'] == true && 
          result['data'] != null) {
        // 开桌成功，跳转到点餐页面
        final tableData = result['data'];
        
        // 额外验证桌台数据的有效性
        if (tableData.tableId != null && tableData.tableId > 0) {
          logDebug('✅ 虚拟开桌成功，跳转到点餐页面', tag: 'TakeawayPage');
          Get.to(
            () => OrderMainPage(),
            arguments: {
              'fromTakeaway': true,
              'table': tableData,
              'menu_id': tableData.menuId,  // 使用接口返回的菜单ID
              'adult_count': (tableData?.currentAdult ?? 0) > 0 ? tableData.currentAdult : tableData?.standardAdult ?? 1,
              'child_count': tableData?.currentChild ?? 0,
            },
          );
        } else {
          logDebug('❌ 桌台数据无效，tableId: ${tableData?.tableId}', tag: 'TakeawayPage');
          // GlobalToast.error('开桌失败：桌台数据无效');
        }
      } else {
        // 开桌失败，不跳转页面
        logDebug('❌ 虚拟开桌失败，不跳转页面。result: $result', tag: 'TakeawayPage');
        // 错误信息已在controller中处理，这里不需要重复显示
      }
    } catch (e) {
      logDebug('❌ 开桌操作异常: $e', tag: 'TakeawayPage');
      GlobalToast.error(Get.context!.l10n.networkErrorPleaseTryAgain);
    }
  }

  /// 构建订单列表
  Widget _buildOrderList(int tabIndex) {
    return Obx(() {
      final orders = tabIndex == 0 ? controller.unpaidOrders : controller.paidOrders;
      final isRefreshing = tabIndex == 0 ? controller.isRefreshingUnpaid.value : controller.isRefreshingPaid.value;
      final hasMore = tabIndex == 0 ? controller.hasMoreUnpaid.value : controller.hasMorePaid.value;
      final hasNetworkError = tabIndex == 0 ? controller.hasNetworkErrorUnpaid.value : controller.hasNetworkErrorPaid.value;
      
      // 根据标签页索引选择对应的RefreshController
      final refreshController = tabIndex == 0 ? _unpaidRefreshController : _paidRefreshController;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Container(
          color: Colors.transparent, // 确保SmartRefresher的背景是透明
          child: SmartRefresher(
          controller: refreshController,
          enablePullDown: true,
          enablePullUp: hasMore,
          onRefresh: () async {
            logDebug('开始刷新标签页 $tabIndex', tag: 'TakeawayPage');
            
            // 保存搜索框状态
            final currentSearchText = controller.searchController.text;
            
            try {
              await controller.refreshData(tabIndex);
              logDebug('刷新完成标签页 $tabIndex', tag: 'TakeawayPage');
              
              // 恢复搜索框状态
              if (mounted && currentSearchText.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    controller.searchController.text = currentSearchText;
                    controller.preserveSearchState();
                  }
                });
              }
              
              // 通知刷新完成
              refreshController.refreshCompleted();
            } catch (e) {
              logError('外卖页面刷新失败: $e', tag: 'TakeawayPage');
              // 刷新失败也要通知完成
              refreshController.refreshFailed();
            }
          },
          onLoading: () async {
            logDebug('开始加载更多标签页 $tabIndex', tag: 'TakeawayPage');
            try {
              await controller.loadMore(tabIndex);
              logDebug('加载更多完成标签页 $tabIndex', tag: 'TakeawayPage');
              // 通知加载完成
              refreshController.loadComplete();
            } catch (e) {
              logError('加载更多失败: $e', tag: 'TakeawayPage');
              // 加载失败也要通知完成
              refreshController.loadFailed();
            }
          },
          header: CustomHeader(
            builder: (context, mode) {
              Widget body;
              if (mode == RefreshStatus.idle) {
                // 空闲状态 - 显示箭头
                body = const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFFFF9027),
                  size: 30,
                );
              } else if (mode == RefreshStatus.canRefresh) {
                // 可以刷新状态 - 显示向上箭头
                body = const Icon(
                  Icons.keyboard_arrow_up,
                  color: Color(0xFFFF9027),
                  size: 30,
                );
              } else if (mode == RefreshStatus.refreshing) {
                // 刷新中状态 - 显示你的动画
                body = const RestaurantLoadingWidget();
              } else if (mode == RefreshStatus.completed) {
                // 刷新完成状态 - 显示勾选
                body = const Icon(
                  Icons.check,
                  color: Colors.green,
                  size: 30,
                );
              } else {
                // 其他状态
                body = const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFFFF9027),
                  size: 30,
                );
              }

              return Container(
                height: 60,
                alignment: Alignment.center,
                color: Colors.transparent, // 设置透明背景，避免灰色闪现
                child: body,
              );
            },
          ),
          footer: CustomFooter(
            builder: (context, mode) {
              Widget body;
              if (mode == LoadStatus.idle) {
                body = const SizedBox.shrink();
              } else if (mode == LoadStatus.loading) {
                body = const RestaurantLoadingWidget(
                  size: 30,
                  color: Color(0xFFFF9027),
                );
              } else if (mode == LoadStatus.failed) {
                body = const Text('加载失败');
              } else if (mode == LoadStatus.canLoading) {
                body = const SizedBox.shrink();
              } else {
                body = const SizedBox.shrink();
              }

              return Container(
                height: 60,
                alignment: Alignment.center,
                color: Colors.transparent, // 设置透明背景，避免灰色闪现
                child: body,
              );
            },
          ),
          child: orders.isEmpty && !isRefreshing
              ? _buildTabEmptyState(hasNetworkError)
              : ListView.separated(
                  physics: const BouncingScrollPhysics(), // 使用弹性滚动，提供更好的用户体验
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
          ), // 结束 SmartRefresher
        ), // 结束 Container
      );
    });
  }

  /// 构建单个tab的空状态（在SmartRefresher中使用，自带下拉刷新功能）
  Widget _buildTabEmptyState(bool hasNetworkError) {
    return SizedBox(
      // 设置最小高度确保可以触发下拉刷新
      height: MediaQuery.of(context).size.height - 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              hasNetworkError ? 'assets/order_nonet.webp' : 'assets/order_empty.webp',
              width: 180,
              height: 100,
            ),
            const SizedBox(height: 8),
            Text(
              hasNetworkError ? context.l10n.networkErrorPleaseTryAgain : context.l10n.noData,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFFF9027),
              ),
            ),
            
            if (hasNetworkError) ...[
              const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                // 重新加载当前tab的数据
                await controller.refreshData(_currentTabIndex);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9027),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:  Text(
                context.l10n.loadAgain,
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }

  @override
  String getEmptyStateText() => context.l10n.noData;

  @override
  String getNetworkErrorText() => context.l10n.networkErrorPleaseTryAgain;

  @override
  Widget? getNetworkErrorAction() {
    return ElevatedButton(
      onPressed: () async {
        // 重新加载当前tab的数据
        await controller.refreshData(_currentTabIndex);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF9027),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child:  Text(
        context.l10n.loadAgain,
        style: TextStyle(fontSize: 14),
      ),
    );
  }

  @override
  Widget buildDataContent() {
    return Column(
      children: [
        // 搜索框
        _buildSearchBar(),
        // Tab内容
        Expanded(
        child: Container(
          color: Colors.transparent, // 确保TabBarView的背景是透明
          child: TabBarView(
              controller: _tabController,
              physics: const PageScrollPhysics(), // 使用页面滑动物理效果，更适合tab切换
              children: [
                // 未结账 Tab
                _buildOrderList(0),
                // 已结账 Tab
                _buildOrderList(1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建加载更多指示器
  Widget _buildLoadMoreIndicator(int tabIndex) {
    // 直接使用实例变量controller，无需重新Get.find
    return Obx(() {
      final isLoadingMore = controller.isLoadingMore.value;
      
      if (isLoadingMore) {
        return Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          color: Colors.transparent, // 设置透明背景，避免灰色闪现
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

/// 独立的可拖动浮动按钮组件
class _DraggableFab extends StatefulWidget {
  final VoidCallback onTap;
  final Function(DraggableDetails) onDragEnd;
  final DragUpdateCallback? onDragUpdate;
  final bool isLoading;

  const _DraggableFab({
    required this.onTap,
    required this.onDragEnd,
    this.onDragUpdate,
    this.isLoading = false,
  });

  @override
  State<_DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends State<_DraggableFab> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 如果正在loading，禁用拖拽功能
    if (widget.isLoading) {
      return _buildFabButton();
    }
    
    return Draggable(
      feedback: Material(
        elevation: 0,
        shape: const CircleBorder(),
        color: Colors.transparent,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Color(0xFFFF9027),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
      childWhenDragging: _buildFabButton(isPlaceholder: true),
      onDragStarted: () {
        _animationController.forward();
      },
      onDragUpdate: widget.onDragUpdate,
      onDragEnd: (details) {
        _animationController.reverse();
        widget.onDragEnd(details);
      },
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onTap,
        onTapDown: widget.isLoading ? null : (_) => _animationController.forward(),
        onTapUp: widget.isLoading ? null : (_) => _animationController.reverse(),
        onTapCancel: widget.isLoading ? null : () => _animationController.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: _buildFabButton(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFabButton({bool isDragging = false, bool isPlaceholder = false}) {
    // 如果是占位符（原位置），完全透明，不显示任何内容
    if (isPlaceholder) {
      return Container(
        width: 56,
        height: 56,
        // 完全透明，不显示任何内容
        color: Colors.transparent,
      );
    }
    
    final opacity = isDragging ? 0.9 : 1.0;
    
    return Material(
      elevation: 0,
      shape: const CircleBorder(),
      color: Colors.transparent,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Color(0xFFFF9027).withValues(alpha: opacity),
          shape: BoxShape.circle,
        ),
        child: widget.isLoading 
          ? RestaurantLoadingWidget(
              size: 32,
              color: Colors.white,
            )
          : Icon(
              Icons.add,
              color: Colors.white.withValues(alpha: opacity),
              size: 36,
            ),
      ),
    );
  }
}

