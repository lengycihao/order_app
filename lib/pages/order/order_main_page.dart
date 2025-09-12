import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/pages/order/tabs/order_dish_tab.dart';
import 'package:order_app/pages/order/tabs/ordered_tab.dart';
import 'package:lib_base/utils/navigation_manager.dart';
import 'package:order_app/pages/order/components/more_options_modal_widget.dart';

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

    // 获取或创建OrderController实例
    try {
      controller = Get.find<OrderController>();
      print('🎯 OrderMainPage 获取已存在的 controller');
    } catch (e) {
      controller = Get.put(OrderController());
      print('🎯 OrderMainPage 创建新的 controller');
    }

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
      // 当切换到已点页面时，刷新已点订单数据
      if (_tabController.index == 1) {
        // 只有在不是loading状态时才刷新，避免重复请求
        if (!controller.isLoadingOrdered.value) {
          controller.loadCurrentOrder();
        }
      }
    }
  }

  /// 处理返回按钮点击
  void _handleBackPressed() async {
    await NavigationManager.backToTablePage();
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
                GestureDetector(
                  onTap: () => _tabController.animateTo(0),
                  child: _buildNavButton('点餐', _tabController.index == 0),
                ),
                SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    // 切换到已点页面前先刷新数据
                    controller.loadCurrentOrder();
                    _tabController.animateTo(1);
                  },
                  child: _buildNavButton('已点', _tabController.index == 1),
                ),
              ],
            ),
          ),
          // 右侧更多按钮
          GestureDetector(
            onTap: () {
              MoreOptionsModalWidget.showMoreModal(context);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(16),
              ),
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
        ],
      ),
    );
  }

  /// 构建导航按钮
  Widget _buildNavButton(String text, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.orange : Colors.black,
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Column(
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
            child: TabBarView(
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
    );
  }
}