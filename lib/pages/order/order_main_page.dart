import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/pages/order/tabs/order_dish_tab.dart';
import 'package:order_app/pages/order/tabs/ordered_tab.dart';
import 'package:lib_base/utils/navigation_manager.dart';
import 'package:order_app/pages/order/components/more_options_modal_widget.dart';
import 'package:order_app/pages/takeaway/components/menu_selection_modal_widget.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:lib_domain/api/base_api.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:order_app/utils/keyboard_utils.dart';
import 'package:lib_base/logging/logging.dart';

// 简单的控制器来管理主页面状态
class OrderMainPageController extends GetxController {
  late TabController _tabController;
  
  void setTabController(TabController tabController) {
    _tabController = tabController;
  }
  
  void switchToOrderedTab() {
    _tabController.animateTo(1);
  }
  
  void switchToOrderTab() {
    _tabController.animateTo(0);
  }
}

class OrderMainPage extends StatefulWidget {
  const OrderMainPage({super.key});

  @override
  State<OrderMainPage> createState() => _OrderMainPageState();
}

class _OrderMainPageState extends State<OrderMainPage> with TickerProviderStateMixin {
  late final OrderController controller;
  late final OrderMainPageController mainPageController;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();

    // 总是创建新的OrderController实例，避免缓存问题
    // 先清理可能存在的旧实例
    if (Get.isRegistered<OrderController>()) {
      Get.delete<OrderController>();
      logDebug('🧹 清理旧的OrderController实例', tag: 'OrderMainPage');
    }
    
    // 创建新的OrderController实例
    controller = Get.put(OrderController());
    logDebug('🎯 OrderMainPage 创建新的 controller', tag: 'OrderMainPage');

    // 创建主页面控制器
    mainPageController = Get.put(OrderMainPageController());

    // 初始化TabController
    _tabController = TabController(length: 2, vsync: this);
    
    // 将TabController传递给控制器
    mainPageController.setTabController(_tabController);
    
    // 监听Tab变化
    _tabController.addListener(_onTabChanged);
    
    // 加载敏感物数据
    controller.loadAllergens();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    Get.delete<OrderMainPageController>(); // 清理控制器
    super.dispose();
  }

  /// Tab变化监听
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      if (_tabController.index == 1) {
        // 切换到已点页面时，刷新已点订单数据
        if (!controller.isLoadingOrdered.value) {
          controller.loadCurrentOrder(showLoading: false);
        }
        
        // 如果刚刚提交了订单，清空购物车
        if (controller.justSubmittedOrder.value) {
          controller.clearCart();
          controller.justSubmittedOrder.value = false; // 重置标记
        }
      } else if (_tabController.index == 0) {
        // 切换回菜单页面时，刷新购物车数据
        controller.forceRefreshCart(silent: true);
      }
    }
  }

  /// 处理返回按钮点击
  void _handleBackPressed() async {
    // 判断是否来自外卖页面
    if (controller.source.value == 'takeaway') {
      // 返回外卖页面
      Get.back();
    } else {
      // 返回桌台页面
      await NavigationManager.backToTablePage();
    }
  }

  /// 显示更换菜单弹窗
  void _showChangeMenuModal() async {
    final selectedMenu = await MenuSelectionModalWidget.showMenuSelectionModal(
      context,
      currentMenu: controller.menu.value,
    );
    
    if (selectedMenu != null && selectedMenu.menuId != controller.menu.value?.menuId) {
      // 调用API更换菜单
      await _performChangeMenu(selectedMenu);
    }
  }

  /// 执行更换菜单操作
  Future<void> _performChangeMenu(TableMenuListModel selectedMenu) async {
    final currentTableId = controller.table.value?.tableId.toInt();

    if (currentTableId == null) {
      GlobalToast.error('当前桌台信息错误');
      return;
    }

    try {
      final result = await BaseApi().changeMenu(
        tableId: currentTableId,
        menuId: selectedMenu.menuId!,
      );

      if (result.isSuccess) {
        // 更新controller中的菜单信息
        controller.menu.value = selectedMenu;
        // 同步更新menuId，确保菜品数据能正确加载
        controller.menuId.value = selectedMenu.menuId ?? 0;
        
        // 刷新点餐页面数据
        await controller.refreshOrderData();

        GlobalToast.success('已成功更换菜单');
      } else {
        GlobalToast.error(result.msg ?? '更换菜单失败');
      }
    } catch (e) {
      GlobalToast.error('更换菜单操作异常：$e');
    }
  }

  /// 构建顶部导航
  Widget _buildTopNavigation() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 18,
      ),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => _handleBackPressed(),
            child: Container(
              width: 32,
              height: 32,
              padding: EdgeInsets.all(5),
              child: Image.asset(
                'assets/order_dish_back.webp',
                fit: BoxFit.contain,
                width: 20,
                height: 20,
              ),
            ),
          ),
          SizedBox(width: 12),
          // 中间导航按钮组
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 根据来源显示不同的导航
                if (controller.source.value == 'takeaway') ...[
                  // 外卖页面只显示"外卖"
                  _buildNavButton('外卖', true),
                ] else ...[
                  // 桌台页面显示"菜单"和"已点"
                  GestureDetector(
                    onTap: () => _tabController.animateTo(0),
                    child: _buildNavButton('菜单', _tabController.index == 0),
                  ),
                  SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => _tabController.animateTo(1),
                    child: _buildNavButton('已点', _tabController.index == 1),
                  ),
                ],
              ],
            ),
          ),
          // 右侧按钮
          if (controller.source.value == 'takeaway') ...[
            // 外卖页面显示更换按钮
            GestureDetector(
              onTap: () {
                _showChangeMenuModal();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '更换',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ] else ...[
            // 桌台页面显示更多按钮
            GestureDetector(
              onTap: () {
                MoreOptionsModalWidget.showMoreModal(context);
              },
              child: Container(
                height: 24,
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '更多',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建导航按钮
  Widget _buildNavButton(String text, bool isSelected) {
    // 判断是否为外卖来源
    bool isTakeawaySource = controller.source.value == 'takeaway';
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              color: isTakeawaySource 
                ? Colors.black  // 外卖来源：黑色
                : (isSelected ? Colors.orange : Color(0xFF666666)), // 其他来源：保持原样
              fontSize: isTakeawaySource ? 24 : 16, // 外卖来源：24pt，其他来源：16pt
              fontWeight: isTakeawaySource 
                ? FontWeight.bold  // 外卖来源：加粗
                : (isSelected ? FontWeight.bold : FontWeight.normal), // 其他来源：保持原样
            ),
          ),
          // 外卖来源不显示状态条，其他来源保持原样
          if (!isTakeawaySource && isSelected)
            Container(
              margin: EdgeInsets.only(top: 4),
              height: 2,
              width: text.length * 16.0, // 根据文字长度动态调整宽度
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: KeyboardUtils.buildDismissiblePage(
        child: Column(
          children: [
            // 顶部导航栏
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                return _buildTopNavigation();
              },
            ),
            // Tab内容
            Expanded(
            child: controller.source.value == 'takeaway' 
              ? OrderDishTab() // 外卖页面只显示点餐页面
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // 点餐页面
                    OrderDishTab(),
                    // 已点页面
                    OrderedTab(),
                  ],
                ),
          ),
        ],
        ),
      ),
    );
  }
}