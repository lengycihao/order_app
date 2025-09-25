import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/order/components/order_submit_dialog.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/pages/order/components/dish_item_widget.dart';
import 'package:order_app/pages/order/components/allergen_filter_widget.dart';
import 'package:order_app/pages/order/components/specification_modal_widget.dart';
import 'package:order_app/pages/order/components/unified_cart_widget.dart';
import 'package:order_app/utils/focus_manager.dart';
import 'package:order_app/pages/order/order_main_page.dart';
import 'package:order_app/components/skeleton_widget.dart';
import 'package:lib_base/network/interceptor/auth_service.dart';
import 'package:get_it/get_it.dart';

class OrderDishTab extends StatefulWidget {
  const OrderDishTab({super.key});

  @override
  State<OrderDishTab> createState() => _OrderDishTabState();
}

class _OrderDishTabState extends State<OrderDishTab> with AutomaticKeepAliveClientMixin {
  late final OrderController controller;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  
  // 每个类目在列表中的位置信息
  List<double> _categoryPositions = [];
  bool _isClickCategory = false;
  
  // 吸顶相关状态已移除，现在由统一的吸顶头部处理
  
  // 性能优化：防抖定时器
  Timer? _scrollDebounceTimer;
  Timer? _categoryCalculationTimer;
  Timer? _searchDebounceTimer;
  
  // 性能优化：缓存机制
  String? _lastFilteredDishesHash;
  bool _categoryPositionsCalculated = false;
  
  // 搜索框显示状态
  bool _showSearchField = false;

  @override
  bool get wantKeepAlive => true; // 保持页面状态

  @override
  void initState() {
    super.initState();

    // 获取OrderController实例
    controller = Get.find<OrderController>();

    // 监听滚动来更新左侧类目选中状态
    _scrollController.addListener(_onScroll);
    
    // 同步搜索框和controller的值
    _searchController.addListener(() {
      if (_searchController.text != controller.searchKeyword.value) {
        controller.searchKeyword.value = _searchController.text;
      }
    });
    
    // 监听焦点变化，处理键盘收起时的光标释放
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        // 焦点丢失时，确保光标完全释放
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // 强制清除焦点，确保光标消失
            FocusScope.of(context).unfocus();
            // 额外确保搜索框失去焦点
            _searchFocusNode.unfocus();
          }
        });
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
    _scrollDebounceTimer?.cancel();
    _categoryCalculationTimer?.cancel();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  /// 防抖搜索 - 优化搜索性能
  void _debouncedSearch(String value) {
    // 取消之前的搜索定时器
    _searchDebounceTimer?.cancel();
    
    // 设置防抖定时器，延迟300ms执行
    _searchDebounceTimer = Timer(Duration(milliseconds: 300), () {
      _calculateCategoryPositions();
    });
  }

  /// 计算每个类目在列表中的位置 - 优化版本，使用防抖
  void _calculateCategoryPositions() {
    // 取消之前的计算定时器
    _categoryCalculationTimer?.cancel();
    
    // 设置防抖定时器，延迟100ms执行
    _categoryCalculationTimer = Timer(Duration(milliseconds: 100), () {
      _performCategoryCalculation();
    });
  }
  
  /// 执行类目位置计算 - 优化版本，使用缓存机制
  void _performCategoryCalculation() {
    // 生成当前过滤菜品的哈希值
    final currentHash = _generateFilteredDishesHash();
    
    // 如果数据没有变化且已经计算过，则跳过
    if (_categoryPositionsCalculated && _lastFilteredDishesHash == currentHash) {
      return;
    }
    
    _categoryPositions.clear();
    
    // 检查数据是否有效
    if (controller.categories.isEmpty) {
      return;
    }
    
    double currentPosition = 0.0;
    const double itemHeight = 116.0;
    const double categoryHeaderHeight = 40.0;
    const double categoryBottomSpace = 100.0;

    for (int categoryIndex = 0; categoryIndex < controller.categories.length; categoryIndex++) {
      _categoryPositions.add(currentPosition);
      
      // 类目标题高度
      currentPosition += categoryHeaderHeight;
      
      // 该类目下的菜品数量
      final dishesInCategory = controller.filteredDishes
          .where((d) => d.categoryId == categoryIndex)
          .length;
      
      // 菜品列表高度 - 使用固定值避免MediaQuery问题
      const double defaultScreenHeight = 800.0; // 默认屏幕高度
      final minItemsPerScreen = ((defaultScreenHeight - 200) / itemHeight).floor();
      final actualItemCount = dishesInCategory > 0 
          ? (dishesInCategory < minItemsPerScreen ? minItemsPerScreen : dishesInCategory)
          : minItemsPerScreen;
      
      currentPosition += actualItemCount * itemHeight;
      currentPosition += categoryBottomSpace;
    }
    
    // 更新缓存状态
    _lastFilteredDishesHash = currentHash;
    _categoryPositionsCalculated = true;
  }
  
  /// 生成过滤菜品的哈希值，用于缓存判断
  String _generateFilteredDishesHash() {
    final buffer = StringBuffer();
    buffer.write('categories:${controller.categories.length}');
    buffer.write('dishes:${controller.filteredDishes.length}');
    buffer.write('search:${controller.searchKeyword.value}');
    buffer.write('allergens:${controller.selectedAllergens.length}');
    buffer.write('sort:${controller.sortType.value}');
    return buffer.toString();
  }



  /// 滚动监听 - 优化版本，使用防抖减少频繁计算
  void _onScroll() {
    if (_isClickCategory || _categoryPositions.isEmpty || controller.categories.isEmpty) return;

    // 取消之前的定时器
    _scrollDebounceTimer?.cancel();
    
    // 设置防抖定时器，延迟50ms执行
    _scrollDebounceTimer = Timer(Duration(milliseconds: 50), () {
      _performScrollUpdate();
    });
  }
  
  /// 执行滚动更新逻辑
  void _performScrollUpdate() {
    if (!_scrollController.hasClients) return;
    
    final scrollOffset = _scrollController.offset;
    int newSelectedCategory = 0;

    // 根据滚动位置确定当前选中的分类
    for (int i = _categoryPositions.length - 1; i >= 0; i--) {
      if (scrollOffset >= _categoryPositions[i]) {
        newSelectedCategory = i;
        break;
      }
    }

    // 只有分类真正改变时才更新
    if (controller.selectedCategory.value != newSelectedCategory) {
      controller.selectedCategory.value = newSelectedCategory;
    }
    
    // 吸顶分类状态现在由统一的吸顶头部处理
  }

  /// 滚动到指定类目
  void _scrollToCategory(int categoryIndex) async {
    if (controller.categories.isEmpty) return;
    
    if (categoryIndex < 0 || 
        categoryIndex >= controller.categories.length) return;

    // 如果位置信息为空，先计算位置
    if (_categoryPositions.isEmpty) {
      _calculateCategoryPositions();
    }

    _isClickCategory = true;
    controller.selectedCategory.value = categoryIndex;
    
    try {
      if (categoryIndex < _categoryPositions.length) {
        await _scrollController.animateTo(
          _categoryPositions[categoryIndex],
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      print('❌ 滚动到类目失败: $e');
    } finally {
      Future.delayed(Duration(milliseconds: 100), () {
        _isClickCategory = false;
      });
    }
  }

  /// 构建共用的搜索框组件
  Widget _buildSearchField({bool showClearIcon = true, bool showSearchIcon = true}) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: Color(0xffF5F5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textAlignVertical: TextAlignVertical.center,
        // 性能优化配置
        enableInteractiveSelection: true,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        // 光标样式配置
        cursorColor: Colors.orange,
        cursorWidth: 1.0,
        cursorHeight: 16.0,
        decoration: InputDecoration(
          hintText: "请输入菜品编码或名称",
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          suffixIcon: showClearIcon && controller.searchKeyword.value.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    controller.searchKeyword.value = '';
                    // 强制释放焦点，确保光标消失
                    _searchFocusNode.unfocus();
                    FocusScope.of(context).unfocus();
                    // 强制隐藏键盘
                    SystemChannels.textInput.invokeMethod('TextInput.hide');
                    _calculateCategoryPositions();
                  },
                  child: Icon(
                    Icons.clear,
                    color: Colors.grey.shade500,
                    size: 18,
                  ),
                )
              : showClearIcon && showSearchIcon
                  ? Icon(
                      Icons.search,
                      color: Colors.grey.shade500,
                      size: 18,
                    )
                  : null,
        ),
        onChanged: (v) {
          controller.searchKeyword.value = v;
          // 使用防抖搜索，避免频繁计算
          _debouncedSearch(v);
        },
        onSubmitted: (value) {
          // 强制释放焦点，确保光标消失
          _searchFocusNode.unfocus();
          FocusScope.of(context).unfocus();
          // 强制隐藏键盘
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          // 搜索提交时才计算位置
          _calculateCategoryPositions();
        },
        onTap: () {
          // 点击搜索框时，确保焦点正确
          _searchFocusNode.requestFocus();
        },
      ),
    );
  }

  /// 构建搜索和筛选区域
  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Obx(() {
        // 如果是外卖页面，直接显示搜索框
        if (controller.source.value == 'takeaway') {
          return Row(
            children: [
              Expanded(
                child: _buildSearchField(showClearIcon: true),
              ),
              SizedBox(width: 15),
              // 敏感物筛选图标
              AllergenFilterWidget.buildFilterButton(context),
            ],
          );
        }
        
        // 桌台页面：显示桌台信息和搜索按钮
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              // padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // 根据状态显示桌台信息或搜索框
                  if (!_showSearchField) ...[
                    // 桌台号和人数信息
                    Flexible(
                       child: Text(
                        '桌子:${controller.table.value?.tableName ?? 'null'} | 大人:${controller.adultCount.value} 小孩:${controller.childCount.value}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff666666),
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else ...[
                    // 搜索框
                    Expanded(
                      child: _buildSearchField(showClearIcon: true, showSearchIcon: false),
                    ),
                  ],
                  // Spacer(),
                  // 搜索按钮
                  SizedBox(width: 10,),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showSearchField = !_showSearchField;
                      });
                    },
                    child: Image(image: AssetImage("assets/order_allergen_search.webp"),width: 20,),
                  ),
                  SizedBox(width: 12),
                  // 过敏原筛选按钮
                  AllergenFilterWidget.buildFilterButton(context),
                ],
              ),
            ),
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
          _buildCategoryList(),
          _buildDishList(),
        ],
      ),
    );
  }

  /// 构建分类列表
  Widget _buildCategoryList() {
    return Container(
      width: 72,
      child: Obx(() {
        if (controller.categories.isEmpty) {
          return const OrderPageSkeleton();
        }
        
        final selectedCategoryIndex = controller.selectedCategory.value;
        
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: controller.categories.length,
          itemBuilder: (context, index) {
            final isSelected = selectedCategoryIndex == index;
            
            return GetBuilder<OrderController>(
              builder: (controller) {
                final categoryCount = controller.cart.entries
                    .where((e) => e.key.dish.categoryId == index)
                    .fold<int>(0, (sum, e) => sum + e.value);

                final selectedIndex = controller.selectedCategory.value;
                final isAboveSelected = index == selectedIndex - 1;
                final isBelowSelected = index == selectedIndex + 1;
                
                return GestureDetector(
                    onTap: () => _scrollToCategory(index),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Color(0xfff4f4f4),
                        borderRadius: (isAboveSelected || isBelowSelected) ? BorderRadius.only(
                          topRight: isBelowSelected ? Radius.circular(8) : Radius.zero,
                          bottomRight: isAboveSelected ? Radius.circular(8) : Radius.zero,
                        ) : null,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
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
                                    topRight: Radius.elliptical(5, 5),
                                    bottomRight: Radius.elliptical(5, 5),
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
                                    ? Colors.black
                                    : Color(0xff666666),
                                    fontSize: 12,
                                fontWeight: isSelected 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (categoryCount > 0)
                            Positioned(
                              right: 0,
                              top: -12,
                              child: Container(
                                constraints: BoxConstraints(
                                  minWidth: 15,
                                  maxWidth: 20,
                                  minHeight: 15,
                                  maxHeight: 15
                                ),
                                // padding: EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                   
                                ),
                                child: Center(
                                  child: Text(
                                    "$categoryCount",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      height: 1,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
        color: Colors.white,
        child: Obx(() {
          if (controller.categories.isEmpty) {
            return const OrderPageSkeleton();
          }

          return GestureDetector(
            onTap: () {
              GlobalFocusManager().dismissAllQuantityInputs();
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification) {
                  // 滚动结束时重新计算位置，使用防抖
                  _calculateCategoryPositions();
                }
                // 移除ScrollUpdateNotification的处理，因为_onScroll已经处理了
                return false;
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: ClampingScrollPhysics(),
                slivers: _buildSlivers(),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 安全获取滚动偏移量
  double _getScrollOffset() {
    try {
      if (_scrollController.hasClients) {
        return _scrollController.offset;
      }
    } catch (e) {
      print('获取滚动偏移量时出错: $e');
    }
    return 0.0;
  }

  /// 构建Sliver列表 - 优化版本
  List<Widget> _buildSlivers() {
    List<Widget> slivers = [];
    
    // 检查数据是否有效，添加null检查
    if (controller.categories.isEmpty || controller.filteredDishes.isEmpty) {
      return slivers;
    }
    
    // 确保位置信息已计算
    if (_categoryPositions.isEmpty || !_categoryPositionsCalculated) {
      _calculateCategoryPositions();
    }
    
    // 添加统一的吸顶分类头
    slivers.add(
      SliverPersistentHeader(
        pinned: true,
        delegate: _UnifiedStickyHeaderDelegate(
          height: 40,
          categoryPositions: _categoryPositions,
          scrollOffset: _getScrollOffset(),
          categories: controller.categories,
          selectedCategory: controller.selectedCategory.value,
          onScrollOffsetChanged: (offset) {
            // 当滚动位置变化时，触发重建
            if (mounted) {
              setState(() {});
            }
          },
        ),
      ),
    );
    
    for (int categoryIndex = 0; categoryIndex < controller.categories.length; categoryIndex++) {
      // 检查索引是否有效
      if (categoryIndex >= controller.categories.length) break;
      
      // 添加该类目的菜品
      final dishes = controller.filteredDishes
          .where((d) => d.categoryId == categoryIndex)
          .toList();
      
      if (dishes.isNotEmpty) {
        // 添加类目标题（第一个类目不显示标题，因为吸顶的就是它）
        if (categoryIndex > 0) {
          slivers.add(
            SliverToBoxAdapter(
              child: _buildCategoryHeader(categoryIndex),
            ),
          );
        }
        
        // 添加该类目的菜品列表
        slivers.add(
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= dishes.length) return Container();
                return _buildDishItem(dishes[index]);
              },
              childCount: dishes.length,
            ),
          ),
        );
      }
      
      // 添加类目底部空间
      slivers.add(
        SliverToBoxAdapter(
          child: _buildCategoryBottomSpace(categoryIndex),
        ),
      );
    }
    
    return slivers;
  }



  /// 构建类目标题（用于列表中的类目标题）
  Widget _buildCategoryHeader(int categoryIndex) {
    // 检查数据是否有效
    if (controller.categories.isEmpty || 
        categoryIndex < 0 || 
        categoryIndex >= controller.categories.length) {
      return Container();
    }
    
    final categoryName = controller.categories[categoryIndex].toString();
    
    return Container(
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        categoryName,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// 构建菜品项
  Widget _buildDishItem(dynamic dish) {
    // 检查菜品数据是否有效
    if (dish == null) {
      return Container(height: 116, color: Colors.grey[100]);
    }
    
    return DishItemWidget(
      dish: dish,
      onSpecificationTap: () {
        SpecificationModalWidget.showSpecificationModal(context, dish);
      },
      onAddTap: () {
        controller.addToCart(dish);
      },
      onRemoveTap: () {
        controller.removeFromCart(dish);
      },
      onDishTap: () {
        // 跳转到菜品详情页面
        Get.toNamed('/dish-detail-route', arguments: {'dish': dish});
      },
    );
  }

  /// 构建类目底部空间
  Widget _buildCategoryBottomSpace(int categoryIndex) {
    // 检查数据是否有效
    if (controller.categories.isEmpty) {
      return Container(height: 100, color: Colors.white);
    }
    
    final isLastCategory = categoryIndex == controller.categories.length - 1;
    return Container(
      height: isLastCategory ? 150 : 100,
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      // child: isLastCategory ? Center(
      //   child: Text(
      //     '已经到底啦～',
      //     style: TextStyle(
      //       color: Colors.grey,
      //       fontSize: 14,
      //     ),
      //   ),
      // ) : null,
    );
  }

  /// 处理提交订单
  Future<void> _handleSubmitOrder() async {
    if (!mounted) return;
    
    try {
      // 显示纯动画加载弹窗（无文字）
      OrderSubmitDialog.showLoadingOnly(context);
      
      final result = await controller.submitOrder();
      
      if (!mounted) return;
      
      // 关闭加载弹窗
      Navigator.of(context).pop();
      
      if (result['success'] == true) {
        // 下单成功，刷新已点订单数据后切换到已点页面
        await controller.loadCurrentOrder();
        _switchToOrderedTab();
      } else {
        // 下单失败，显示错误弹窗
        await OrderSubmitDialog.showError(context);
      }
    } catch (e) {
      print('❌ 提交订单异常: $e');
      if (mounted) {
        // 关闭加载弹窗
        Navigator.of(context).pop();
        // 显示错误弹窗
        await OrderSubmitDialog.showError(
          context,
          message: '提交订单时发生错误，请重试',
        );
      }
    }
  }

  /// 切换到已点页面
  void _switchToOrderedTab() {
    if (!mounted) return;
    
    try {
      // 直接使用OrderMainPageController来切换Tab
      Get.find<OrderMainPageController>().switchToOrderedTab();
    } catch (e) {
      print('❌ 切换到已点页面失败: $e');
    }
  }

  /// 构建底部购物车按钮
  Widget _buildBottomCartButton() {
    return GetBuilder<OrderController>(
      builder: (controller) {
        final totalCount = controller.totalCount;
        final totalPrice = controller.totalPrice;
        
        if (totalCount == 0) {
          return const SizedBox.shrink();
        }
        
        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 购物车图标和数量角标
              GestureDetector(
                onTap: () => UnifiedCartWidget.showCartModal(
                  context,
                  onSubmitOrder: _handleSubmitOrder,
                ),
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/order_shop_car.webp',
                      width: 44,
                      height: 44,
                    ),
                    if (totalCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF1010),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            totalCount > 99 ? '99+' : totalCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 价格信息
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '￥',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1,
                        color: Color(0xFFFF1010),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      totalPrice.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 24,
                        height: 1,
                        color: Color(0xFFFF1010),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // 下单按钮
              GestureDetector(
                onTap: _handleSubmitOrder,
                child: Container(
                  width: 80,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9027),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Text(
                      '下单',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，因为使用了AutomaticKeepAliveClientMixin
    
    return GestureDetector(
      // 添加全局点击监听器，处理键盘收起按钮点击
      onTap: () {
        // 当用户点击其他地方时，释放搜索框焦点
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          FocusScope.of(context).unfocus();
          // 强制隐藏键盘
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          // 搜索 + 排序
          _buildSearchAndFilter(),
          // 主体内容区域
          _buildMainContent(),
          // 底部购物车按钮
          _buildBottomCartButton(),
        ],
      ),
    );
  }
}

/// 用户头像组件（带loading动画）
class _UserAvatarWithLoading extends StatefulWidget {
  final bool isLoading;
  
  const _UserAvatarWithLoading({
    Key? key,
    required this.isLoading,
  }) : super(key: key);

  @override
  State<_UserAvatarWithLoading> createState() => _UserAvatarWithLoadingState();
}

class _UserAvatarWithLoadingState extends State<_UserAvatarWithLoading>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_UserAvatarWithLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isLoading && !oldWidget.isLoading) {
      // 开始loading
      _startLoading();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      // 停止loading
      _stopLoading();
    }
  }

  void _startLoading() {
    _loadingController.repeat();
    // 设置超时逻辑 - 10秒后自动停止loading
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && widget.isLoading) {
        _stopLoading();
      }
    });
  }

  void _stopLoading() {
    _loadingController.stop();
    _timeoutTimer?.cancel();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = GetIt.instance<AuthService>();
    final user = authService.currentUser;
    return Stack(
          children: [
            // 用户头像 - 使用真实头像或占位图
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // 移除边框
              ),
              child: ClipOval(
                child: user?.avatar != null && user?.avatar?.isNotEmpty == true
                    ? Image.network(
                        user?.avatar ?? '',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/order_mine_placeholder.webp',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        'assets/order_mine_placeholder.webp',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            // Loading动画 - 在头像内部显示转圈动画
            if (widget.isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.3),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: AnimatedBuilder(
                        animation: _loadingController,
                        builder: (context, child) {
                          return CircularProgressIndicator(
                            value: _loadingController.value,
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
  }
}

/// 统一的吸顶头部委托类
class _UnifiedStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final List<double> categoryPositions;
  final double scrollOffset;
  final List<dynamic> categories;
  final int selectedCategory;
  final Function(double)? onScrollOffsetChanged;

  _UnifiedStickyHeaderDelegate({
    required this.height,
    required this.categoryPositions,
    required this.scrollOffset,
    required this.categories,
    required this.selectedCategory,
    this.onScrollOffsetChanged,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // 计算当前应该显示的类目
    int currentCategoryIndex = _getCurrentCategoryIndex();
    
    // 检查索引是否有效
    if (currentCategoryIndex < 0 || currentCategoryIndex >= categories.length) {
      return Container(height: height, color: Colors.white);
    }
    
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white, // 统一白色背景
        boxShadow: overlapsContent ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ] : null,
      ),
      child: _buildCategoryHeader(currentCategoryIndex),
    );
  }

  /// 获取当前应该显示的类目索引
  int _getCurrentCategoryIndex() {
    if (categoryPositions.isEmpty || categories.isEmpty) return 0;
    
    // 根据滚动位置确定当前类目
    for (int i = categoryPositions.length - 1; i >= 0; i--) {
      if (scrollOffset >= categoryPositions[i]) {
        return i;
      }
    }
    
    return 0;
  }

  /// 构建类目标题
  Widget _buildCategoryHeader(int categoryIndex) {
    if (categoryIndex < 0 || categoryIndex >= categories.length) {
      return Container();
    }
    
    final categoryName = categories[categoryIndex]?.toString() ?? '未知分类';
    
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        categoryName,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    if (oldDelegate is _UnifiedStickyHeaderDelegate) {
      // 安全地比较列表，避免null check operator错误
      bool categoriesChanged = false;
      if (oldDelegate.categories.length != categories.length) {
        categoriesChanged = true;
      } else {
        for (int i = 0; i < categories.length; i++) {
          if (oldDelegate.categories[i] != categories[i]) {
            categoriesChanged = true;
            break;
          }
        }
      }
      
      bool positionsChanged = false;
      if (oldDelegate.categoryPositions.length != categoryPositions.length) {
        positionsChanged = true;
      } else {
        for (int i = 0; i < categoryPositions.length; i++) {
          if (oldDelegate.categoryPositions[i] != categoryPositions[i]) {
            positionsChanged = true;
            break;
          }
        }
      }
      
      return oldDelegate.scrollOffset != scrollOffset ||
             positionsChanged ||
             oldDelegate.selectedCategory != selectedCategory ||
             categoriesChanged;
    }
    return true;
  }
}
