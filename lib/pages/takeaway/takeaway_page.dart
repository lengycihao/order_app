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
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';
import 'package:order_app/utils/keyboard_utils.dart';
import 'package:order_app/widgets/base_list_page_widget.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class TakeawayPage extends BaseListPageWidget {
  final List<String> tabs = ['未结账', '已结账'];

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

  @override
  void initState() {
    super.initState();
    controller = Get.put(TakeawayController());
    _tabController = TabController(length: widget.tabs.length, vsync: this);
    _tabController.addListener(() {
      _currentTabIndex = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _unpaidRefreshController.dispose();
    _paidRefreshController.dispose();
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
      return controller.unpaidOrders.isNotEmpty;
    } else {
      return controller.paidOrders.isNotEmpty;
    }
  }
  
  @override
  bool get shouldShowSkeleton {
    // 只有未结账页面且没有数据时才显示骨架图
    return _currentTabIndex == 0 && !hasData;
  }

  @override
  Future<void> onRefresh() async {
    await controller.refreshData(_currentTabIndex);
  }
  
  @override
  Widget buildSkeletonWidget() {
    return const TakeawayPageSkeleton();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: widget.tabs.length,
      child: Scaffold(
        backgroundColor: Color(0xFFF9F9F9),
        appBar: CenteredTabBar(
          tabs: ['未结账', '已结账'],
          controller: _tabController,
        ),
        body: KeyboardUtils.buildDismissiblePage(
          child: _buildTakeawayPageBody(),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  /// 构建外卖页面主体内容
  Widget _buildTakeawayPageBody() {
    return Obx(() {
      // 如果应该显示骨架图且正在加载且没有数据，显示骨架图
      if (shouldShowSkeleton && isLoading && !hasData) {
        return buildSkeletonWidget();
      }

      if (isLoading && !hasData) {
        return buildLoadingWidget();
      }

      if (hasNetworkError) {
        return buildNetworkErrorState();
      }

      if (!hasData) {
        return buildEmptyState();
      }

      return buildDataContent();
    });
  }

  /// 构建搜索框
  Widget _buildSearchBar() {
    final controller = Get.find<TakeawayController>();
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
      
      // 根据标签页索引选择对应的RefreshController
      final refreshController = tabIndex == 0 ? _unpaidRefreshController : _paidRefreshController;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SmartRefresher(
          controller: refreshController,
          enablePullDown: true,
          enablePullUp: hasMore,
          onRefresh: () async {
            print('🔄 开始刷新标签页 $tabIndex');
            try {
              await controller.refreshData(tabIndex);
              print('✅ 刷新完成标签页 $tabIndex');
              // 通知刷新完成
              refreshController.refreshCompleted();
            } catch (e) {
              print('❌ 外卖页面刷新失败: $e');
              // 刷新失败也要通知完成
              refreshController.refreshFailed();
            }
          },
          onLoading: () async {
            print('🔄 开始加载更多标签页 $tabIndex');
            try {
              await controller.loadMore(tabIndex);
              print('✅ 加载更多完成标签页 $tabIndex');
              // 通知加载完成
              refreshController.loadComplete();
            } catch (e) {
              print('❌ 加载更多失败: $e');
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
                child: body,
              );
            },
          ),
          child: orders.isEmpty && !isRefreshing
              ? _buildTabEmptyState(hasNetworkError)
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
      );
    });
  }

  /// 构建单个tab的空状态
  Widget _buildTabEmptyState(bool hasNetworkError) {
    return Center(
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
            hasNetworkError ? '暂无网络' : '暂无订单',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFFF9027),
            ),
          ),
        ],
      ),
    );
  }

  @override
  String getEmptyStateText() => '暂无订单';

  @override
  String getNetworkErrorText() => '暂无网络';

  @override
  Widget buildDataContent() {
    return Column(
      children: [
        // 搜索框
        _buildSearchBar(),
        // Tab内容
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 未结账 Tab
              _buildOrderList(0),
              // 已结账 Tab
              _buildOrderList(1),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建加载更多指示器
  Widget _buildLoadMoreIndicator(int tabIndex) {
    final controller = Get.find<TakeawayController>();
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

