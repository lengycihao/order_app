import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:order_app/pages/order/order_element/models.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/pages/order/components/dish_item_widget.dart';
import 'package:order_app/pages/order/components/allergen_filter_widget.dart';
import 'package:order_app/pages/order/components/specification_modal_widget.dart';
import 'package:order_app/pages/order/components/more_options_modal_widget.dart';
import 'package:order_app/pages/order/components/modal_utils.dart';
import 'package:order_app/pages/order/components/quantity_input_widget.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';
import 'package:order_app/pages/order/ordered_page.dart';
import 'package:lib_base/utils/navigation_manager.dart';
import 'package:order_app/utils/focus_manager.dart';
import 'package:order_app/pages/order/components/order_submit_dialog.dart';

class OrderDishPage extends StatefulWidget {
  const OrderDishPage({super.key});

  @override
  State<OrderDishPage> createState() => _OrderDishPageState();
}

class _OrderDishPageState extends State<OrderDishPage> {
  late final OrderController controller;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  
  // 每个类目在列表中的位置信息
  List<double> _categoryPositions = [];
  bool _isClickCategory = false;

  @override
  void initState() {
    super.initState();

    // 获取或创建OrderController实例
    try {
      controller = Get.find<OrderController>();
      print('🎯 OrderDishPage 获取已存在的 controller');
    } catch (e) {
      controller = Get.put(OrderController());
      print('🎯 OrderDishPage 创建新的 controller');
    }
    print('🎯 Controller 类目数量: ${controller.categories.length}');

    // 加载敏感物数据
    controller.loadAllergens();

    // 监听滚动来更新左侧类目选中状态
    _scrollController.addListener(_onScroll);
    
    // 同步搜索框和controller的值
    _searchController.addListener(() {
      if (_searchController.text != controller.searchKeyword.value) {
        controller.searchKeyword.value = _searchController.text;
      }
    });
    
    // 延迟计算类目位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateCategoryPositions();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 计算每个类目在列表中的位置
  void _calculateCategoryPositions() {
    _categoryPositions.clear();
    double currentPosition = 0.0;
    const double itemHeight = 116.0;
    const double categoryHeaderHeight = 40.0; // 普通标题高度
    const double categoryBottomSpace = 100.0; // 每个类目底部的空间

    for (int categoryIndex = 0; categoryIndex < controller.categories.length; categoryIndex++) {
      _categoryPositions.add(currentPosition);
      
      // 类目标题高度
      currentPosition += categoryHeaderHeight;
      
      // 该类目下的菜品数量
      final dishesInCategory = controller.filteredDishes
          .where((d) => d.categoryId == categoryIndex)
          .length;
      
      // 菜品列表高度 - 确保至少一屏
      final screenHeight = MediaQuery.of(context).size.height;
      final minItemsPerScreen = ((screenHeight - 200) / itemHeight).floor(); // 减去其他UI元素高度
      final actualItemCount = dishesInCategory > 0 
          ? (dishesInCategory < minItemsPerScreen ? minItemsPerScreen : dishesInCategory)
          : minItemsPerScreen;
      
      currentPosition += actualItemCount * itemHeight;
      
      // 类目底部空间
      currentPosition += categoryBottomSpace;
      
      // print('📍 类目 $categoryIndex (${controller.categories[categoryIndex]}) 位置: ${_categoryPositions[categoryIndex]}');
    }
  }

  /// 计算列表总项目数
  int _buildItemCount() {
    int count = 0;
    for (int categoryIndex = 0; categoryIndex < controller.categories.length; categoryIndex++) {
      // 类目标题
      count++;
      
      // 该类目的菜品 - 确保至少一屏
      final dishes = controller.filteredDishes
          .where((d) => d.categoryId == categoryIndex)
          .toList();
      
      final screenHeight = MediaQuery.of(context).size.height;
      final minItemsPerScreen = ((screenHeight - 200) / 116).floor();
      final displayItemCount = dishes.length < minItemsPerScreen ? minItemsPerScreen : dishes.length;
      
      count += displayItemCount;
      
      // 类目底部空间
      count++;
    }
    return count;
  }

  /// 构建列表项
  Widget _buildListItem(int index) {
    int currentIndex = 0;
    
    for (int categoryIndex = 0; categoryIndex < controller.categories.length; categoryIndex++) {
      // 类目标题
      if (currentIndex == index) {
        return _buildCategoryHeader(categoryIndex);
      }
      currentIndex++;
      
      // 该类目的菜品
      final dishes = controller.filteredDishes
          .where((d) => d.categoryId == categoryIndex)
          .toList();
      
      // 计算显示数量（确保至少一屏）
      final screenHeight = MediaQuery.of(context).size.height;
      final minItemsPerScreen = ((screenHeight - 200) / 116).floor();
      final displayItemCount = dishes.length < minItemsPerScreen ? minItemsPerScreen : dishes.length;
      
      for (int dishIndex = 0; dishIndex < displayItemCount; dishIndex++) {
        if (currentIndex == index) {
          if (dishIndex < dishes.length) {
            // 显示真实菜品
            return _buildDishItem(dishes[dishIndex]);
          } else {
            // 填充空白项目以确保至少一屏
            return Container(
              height: 116,
              color: Colors.white,
              child: Center(
                child: Text(
                  '更多菜品即将上线',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }
        }
        currentIndex++;
      }
      
      // 类目底部空间
      if (currentIndex == index) {
        return _buildCategoryBottomSpace(categoryIndex);
      }
      currentIndex++;
    }
    
    return SizedBox.shrink();
  }

  /// 构建类目标题
  Widget _buildCategoryHeader(int categoryIndex) {
    return Container(
      height: 40,
      color: Colors.grey.shade200,
      padding: EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        controller.categories[categoryIndex],
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// 滚动监听
  void _onScroll() {
    if (_isClickCategory || _categoryPositions.isEmpty) return;

    final scrollOffset = _scrollController.offset;
    int newSelectedCategory = 0;

    // 找到当前滚动位置对应的类目
    for (int i = _categoryPositions.length - 1; i >= 0; i--) {
      if (scrollOffset >= _categoryPositions[i]) {
        newSelectedCategory = i;
        break;
      }
    }

    if (controller.selectedCategory.value != newSelectedCategory) {
      print('🔄 滚动切换类目: ${controller.selectedCategory.value} -> $newSelectedCategory');
      controller.selectedCategory.value = newSelectedCategory;
    }
  }

  /// 构建导航按钮
  Widget _buildNavButton(String text, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: isSelected ? null : null,
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



  /// 处理返回按钮点击
  void _handleBackPressed() async {
    // 使用导航管理器统一处理返回逻辑
    await NavigationManager.backToTablePage();
  }

  /// 导航到已点页面
  void _navigateToOrderedPage() async {
    // 跳转前刷新已点订单数据
    await controller.loadCurrentOrder();
    Get.to(() => OrderedPage());
  }

  /// 处理提交订单
  Future<void> _handleSubmitOrder() async {
    try {
      // 显示纯动画加载弹窗（无文字）
      OrderSubmitDialog.showLoadingOnly(context);
      
      // 提交订单
      final result = await controller.submitOrder();
      
      // 关闭加载弹窗
      Navigator.of(context).pop();
      
      if (result['success'] == true) {
        // 提交成功，刷新数据后跳转到已点页面
        await controller.loadCurrentOrder();
        Get.to(() => OrderedPage());
      } else {
        // 提交失败，显示错误弹窗
        await OrderSubmitDialog.showError(context);
      }
    } catch (e) {
      print('❌ 提交订单异常: $e');
      // 关闭加载弹窗
      Navigator.of(context).pop();
      // 显示错误弹窗
      await OrderSubmitDialog.showError(
        context,
        message: '提交订单时发生错误，请重试',
      );
    }
  }

  /// zhuo
  void _scrollToCategory(int categoryIndex) async {
    if (categoryIndex < 0 || 
        categoryIndex >= controller.categories.length || 
        _categoryPositions.isEmpty) return;

    print('🎯 点击类目: $categoryIndex (${controller.categories[categoryIndex]})');
    
    _isClickCategory = true;
    controller.selectedCategory.value = categoryIndex;
    
    try {
      await _scrollController.animateTo(
        _categoryPositions[categoryIndex],
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      print('✅ 滚动到类目完成');
    } catch (e) {
      print('❌ 滚动到类目失败: $e');
    } finally {
      // 延迟重置标志
      Future.delayed(Duration(milliseconds: 100), () {
        _isClickCategory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ OrderDishPage build 被调用');
    print('  类目数量: ${controller.categories.length}');
    print('  菜品数量: ${controller.dishes.length}');
    print('  购物车数量: ${controller.cart.length}');
    
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // 防止键盘抬起时购物车跟随移动
      body: Column(
        children: [
          // 顶部导航栏
          _buildTopNavigation(),
          // 搜索 + 排序
          _buildSearchAndFilter(),
          // // 主体内容区域
          _buildMainContent(),
          // 底部购物车
          _buildBottomCart(),
        ],
      ),
    );
  }

  /// 构建顶部导航
  Widget _buildTopNavigation() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top+10,
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
                _buildNavButton('点餐', true),
                SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _navigateToOrderedPage(),
                  child: _buildNavButton('已点', false),
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

  /// 构建搜索和筛选区域
  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Obx(() {
        return Row( 
          children: [
            // 桌号显示或搜索框
            if (!controller.isSearchVisible.value) ...[
              // 显示桌号
              Text(
                controller.getTableDisplayText(),
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xff666666),
                ),
              ),
              Spacer(), // 桌号和搜索图标之间的间距，实现两端对齐
            ] else ...[
              // 显示搜索框
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(0xffF5F5F5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: "请输入菜品名称或首字母",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      suffixIcon: controller.searchKeyword.value.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                controller.searchKeyword.value = '';
                                _searchFocusNode.unfocus(); // 失去焦点
                                // 清除搜索后重新计算位置
                                Future.delayed(Duration(milliseconds: 100), () {
                                  _calculateCategoryPositions();
                                });
                              },
                              child: Icon(
                                Icons.clear,
                                color: Colors.grey.shade500,
                                size: 18,
                              ),
                            )
                          : null,
                    ),
                    onChanged: (v) {
                      // 搜索后重新计算位置
                      Future.delayed(Duration(milliseconds: 100), () {
                        _calculateCategoryPositions();
                      });
                    },
                    onSubmitted: (value) {
                      // 搜索提交后失去焦点
                      _searchFocusNode.unfocus();
                    },
                  ),
                ),
              ),
              SizedBox(width: 15), // 输入框和关闭按钮间隔15px
            ],
            // 搜索图标（仅在搜索框未显示时显示）
            if (!controller.isSearchVisible.value) ...[
              GestureDetector(
                onTap: () {
                  // 显示搜索框
                  controller.showSearchBox();
                  // 延迟聚焦搜索框
                  Future.delayed(Duration(milliseconds: 100), () {
                    _searchFocusNode.requestFocus();
                  });
                },
                child: SizedBox(
                  width: 24,
                  height: 24,
                   
                  child: Image(image: AssetImage("assets/order_allergen_search.webp"),width:20,)
                ),
              ),
              SizedBox(width: 13),
            ],
            
            // 如果搜索框显示，添加关闭按钮
            if (controller.isSearchVisible.value) ...[
              GestureDetector(
                onTap: () {
                  controller.hideSearchBox();
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                  // 隐藏搜索框后重新计算位置
                  Future.delayed(Duration(milliseconds: 100), () {
                    _calculateCategoryPositions();
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(0xffF5F5F5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: 13),
            ],
            
            // 敏感物筛选图标
            AllergenFilterWidget.buildFilterButton(context),
          ],
        );
      }),
    );
  }

  /// 构建主体内容
  Widget _buildMainContent() {
    return Expanded(
      child: Row(
        children: [
          // 左侧分类
          _buildCategoryList(),
          // 右侧菜品列表
          _buildDishList(),
        ],
      ),
    );
  }

  /// 构建分类列表
  Widget _buildCategoryList() {
    return Container(
      width: 72,
      // color: Colors.grey.shade50, // 使用浅灰色作为整体背景
      child: Obx(() {
        if (controller.categories.isEmpty) {
          return Center(
            child: RestaurantLoadingWidget(size: 30),
          );
        }
        
        final selectedCategoryIndex = controller.selectedCategory.value;
        
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: controller.categories.length,
          itemBuilder: (context, index) {
            final isSelected = selectedCategoryIndex == index;
            
            return GetBuilder<OrderController>(
              builder: (controller) {
                // 在GetBuilder中计算购物车数量，确保响应式更新
                final categoryCount = controller.cart.entries
                    .where((e) => e.key.dish.categoryId == index)
                    .fold<int>(0, (sum, e) => sum + e.value);

                // 检查当前分类是否是被选中分类的上下相邻分类
                final selectedIndex = controller.selectedCategory.value;
                final isAboveSelected = index == selectedIndex - 1;
                final isBelowSelected = index == selectedIndex + 1;
                
                return GestureDetector(
                    onTap: () => _scrollToCategory(index),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Color(0xfff4f4f4), // 未选中项使用红色背景
                        borderRadius: (isAboveSelected || isBelowSelected) ? BorderRadius.only(
                          topRight: isBelowSelected ? Radius.circular(8) : Radius.zero,
                          bottomRight: isAboveSelected ? Radius.circular(8) : Radius.zero,
                        ) : null,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 状态指示条
                          if (isSelected)
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.only(
       topRight: Radius.elliptical(5, 5),  // 右上角椭圆半径
       bottomRight: Radius.elliptical(5, 5),// 右下角椭圆半径
    ),
                                ),
                              ),
                            ),
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              controller.categories[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.orange
                                    : Color(0xff666666), // 红色背景上使用白色文字
                                fontWeight: isSelected 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (categoryCount > 0)
                            Positioned(
                              right: 4,
                              bottom: 12,
                              child: Container(
                                constraints: BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: categoryCount > 99 ? 6 : 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "$categoryCount",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
              },
            );
          },
        );
      }),
    );
  }

  /// 构建菜品列表
  Widget _buildDishList() {
    return Expanded(
      child: Container(
        color: Colors.white, // 内容区域背景色设为红色
        child: Obx(() {
          if (controller.categories.isEmpty) {
            return Center(
              child: RestaurantLoadingWidget(
                message: '加载菜品中...',
                size: 80.0,
              ),
            );
          }

          return GestureDetector(
            onTap: () {
              // 点击列表时收起所有数量输入键盘并恢复原值
              GlobalFocusManager().dismissAllQuantityInputs();
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // 滚动结束后重新计算位置
                if (notification is ScrollEndNotification) {
                  Future.delayed(Duration(milliseconds: 50), () {
                    _calculateCategoryPositions();
                  });
                }
                return false;
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                itemCount: _buildItemCount(),
                itemBuilder: (context, index) {
                  return _buildListItem(index);
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 构建菜品项
  Widget _buildDishItem(dynamic dish) {
    return DishItemWidget(
      dish: dish,
      onSpecificationTap: () {
        SpecificationModalWidget.showSpecificationModal(context, dish);
      },
      onAddTap: () {
        print('➕ 添加菜品: ${dish.name}');
        controller.addToCart(dish);
      },
      onRemoveTap: () {
        print('➖ 减少菜品: ${dish.name}');
        controller.removeFromCart(dish);
      },
    );
  }

  /// 构建类目底部空间
  Widget _buildCategoryBottomSpace(int categoryIndex) {
    final isLastCategory = categoryIndex == controller.categories.length - 1;
    return Container(
      height: isLastCategory ? 150 : 100, // 最后一个类目给更多空间
      color: Colors.white,
      child: Center(
        child: Text(
          isLastCategory ? '已经到底啦～' : '${controller.categories[categoryIndex]} 结束',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// 构建底部购物车
  Widget _buildBottomCart() {
    return Obx(() {
      // 缓存计算结果，避免重复计算
      final totalCount = controller.totalCount;
      final totalPrice = controller.totalPrice;
      
      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // 购物车图标和数量
            GestureDetector(
              onTap: () {
                if (totalCount > 0) {
                  _showCartModal();
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: totalCount > 0 ? Colors.orange : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  if (totalCount > 0)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: totalCount > 99 ? 6 : 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '$totalCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 12),
            // 价格信息
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (totalCount > 0) ...[
                    Text(
                      ' ',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 2),
                  ],
                  Text(
                    totalCount > 0 
                        ? '￥${totalPrice.toStringAsFixed(0)}' 
                        : '选择菜品',
                    style: TextStyle(
                      color: totalCount > 0 ? Colors.black : Colors.grey.shade500,
                      fontSize: totalCount > 0 ? 18 : 16,
                      fontWeight: totalCount > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            // 下单按钮
            Container(
              height: 40,
              child: ElevatedButton(
                onPressed: totalCount > 0 ? () => _handleSubmitOrder() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: totalCount > 0 ? Colors.orange : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Text(
                  '下单',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 显示购物车弹窗
  void _showCartModal() {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.8; // 五分之四屏幕高度
    
    ModalUtils.showBottomModal(
      context: context,
      isScrollControlled: true,
      child: CartModalContainer(
        title: ' ',
        onClear: () => _showClearCartDialog(context),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxHeight,
          ),
          child: _CartModalContent(),
        ),
      ),
    );
  }

  /// 显示清空购物车对话框
  void _showClearCartDialog(BuildContext context) {
    final controller = Get.find<OrderController>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              '清空购物车',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '确认要清空购物车中的所有菜品吗？',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.red[600],
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Obx(() {
                    final totalCount = controller.totalCount;
                    return Text(
                      '当前购物车有 $totalCount 个菜品',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }),
                ],
              ),
            ),
            SizedBox(height: 12),
            
          ],
        ),actionsAlignment: MainAxisAlignment.spaceAround,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[400],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '取消',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              controller.clearCart();
              Navigator.of(context).pop(); // 关闭对话框
              Get.back(); // 关闭购物车弹窗
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '确认',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

}


/// 购物车弹窗内容
class _CartModalContent extends StatelessWidget {
  /// 处理提交订单
  Future<void> _handleSubmitOrder(BuildContext context) async {
    try {
      final controller = Get.find<OrderController>();
      // 显示纯动画加载弹窗（无文字）
      OrderSubmitDialog.showLoadingOnly(context);
      
      // 提交订单
      final result = await controller.submitOrder();
      
      // 关闭加载弹窗
      Navigator.of(context).pop();
      
      if (result['success'] == true) {
        // 提交成功，刷新数据后跳转到已点页面
        await controller.loadCurrentOrder();
        Get.to(() => OrderedPage());
      } else {
        // 提交失败，显示错误弹窗
        await OrderSubmitDialog.showError(context);
      }
    } catch (e) {
      print('❌ 提交订单异常: $e');
      // 关闭加载弹窗
      Navigator.of(context).pop();
      // 显示错误弹窗
      await OrderSubmitDialog.showError(
        context,
        message: '提交订单时发生错误，请重试',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = Get.find<OrderController>();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 购物车列表
          controller.isLoadingCart.value
              ? Container(
                  padding: EdgeInsets.all(40),
                  child: RestaurantLoadingWidget(
                    message: '正在加载购物车...',
                    size: 60.0,
                  ),
                )
              : controller.cart.isEmpty
                  ? Container(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '购物车是空的',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.all(16),
                        itemCount: controller.cart.length,
                        itemBuilder: (context, index) {
                          final entry = controller.cart.entries.elementAt(index);
                          final cartItem = entry.key;
                          final count = entry.value;
                          return _CartItem(cartItem: cartItem, count: count);
                        },
                      ),
                    ),
          // 底部统计和下单
          if (controller.cart.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: Offset(0, -1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '共${controller.totalCount}件',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '￥${controller.totalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      _handleSubmitOrder(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 32),
                    ),
                    child: Text(
                      '下单',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}

/// 购物车项目
class _CartItem extends StatelessWidget {
  final CartItem cartItem;
  final int count;

  const _CartItem({
    Key? key,
    required this.cartItem,
    required this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrderController>();
    return Slidable(
      key: Key('cart_item_${cartItem.cartSpecificationId ?? cartItem.dish.id}'),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25, // 限制侧滑宽度为屏幕的25%
        children: [
          SlidableAction(
            onPressed: (context) async {
              // 显示确认对话框
              final shouldDelete = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        '确认删除',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '确定要删除以下菜品吗？',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                cartItem.dish.image,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.restaurant, color: Colors.grey[600]),
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cartItem.dish.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '数量：${Get.find<OrderController>().cart[cartItem] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                       
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '删除',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ) ?? false;
              
              if (shouldDelete) {
                // 删除整个购物车项（所有数量）
                controller.deleteCartItem(cartItem);
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '删除',
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // 菜品图片
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: cartItem.dish.image,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 60,
                height: 60,
                color: Colors.grey.shade200,
                child: Icon(Icons.image, color: Colors.grey),
              ),
              errorWidget: (context, url, error) => Container(
                width: 60,
                height: 60,
                color: Colors.grey.shade200,
                child: Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          SizedBox(width: 12),
          // 菜品信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.dish.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                // 敏感物图标
                if (cartItem.dish.allergens != null && cartItem.dish.allergens!.isNotEmpty)
                  Row(
                    children: cartItem.dish.allergens!.take(4).map((allergen) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (allergen.icon != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: allergen.icon!,
                                width: 16,
                                height: 16,
                                errorWidget: (context, url, error) => Icon(
                                  Icons.warning,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.warning,
                              size: 16,
                              color: Colors.orange,
                            ),
                          SizedBox(width: 4),
                        ],
                      );
                    }).toList(),
                  ),
                SizedBox(height: 8),
                // 规格显示
                if (cartItem.specificationText.isNotEmpty)
                  Text(
                    cartItem.specificationText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                if (cartItem.specificationText.isNotEmpty)
                  SizedBox(height: 4),
                // 价格显示
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '￥${cartItem.dish.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: '/份',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          // 数量控制
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                  GestureDetector(
                    onTap: () => controller.removeFromCart(cartItem),
                    child: Icon(
                      Icons.remove_circle_outline,
                      color: Colors.orange,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  QuantityInputWidget(
                    cartItem: cartItem,
                    currentQuantity: count,
                    isInCartModal: true,
                    onQuantityChanged: () {
                      // 刷新购物车UI
                      controller.forceRefreshCartUI();
                    },
                  ),
                  SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => controller.addCartItemQuantity(cartItem),
                    child: Icon(
                      Icons.add_circle,
                      color: Colors.orange,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
