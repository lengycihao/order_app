import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/order/components/order_submit_dialog.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/pages/order/components/dish_item_widget.dart';
import 'package:order_app/pages/order/model/dish.dart';
import 'package:order_app/pages/order/components/allergen_filter_widget.dart';
import 'package:order_app/pages/order/components/specification_modal_widget.dart';
import 'package:order_app/pages/order/components/unified_cart_widget.dart';
import 'package:order_app/utils/focus_manager.dart';
import 'package:order_app/pages/order/order_main_page.dart';
import 'package:order_app/components/skeleton_widget.dart';
import 'package:order_app/utils/l10n_utils.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:order_app/utils/modal_utils.dart';
import 'package:lib_base/lib_base.dart';
import 'package:lib_base/utils/navigation_manager.dart';
import 'package:order_app/pages/nav/screen_nav_page.dart';
import 'package:order_app/widgets/base_list_page_widget.dart';
import 'package:order_app/utils/image_cache_manager.dart';

class OrderDishTab extends BaseListPageWidget {
  const OrderDishTab({super.key});

  @override
  State<OrderDishTab> createState() => _OrderDishTabState();
}

class _OrderDishTabState extends BaseListPageState<OrderDishTab> with AutomaticKeepAliveClientMixin {
  late final OrderController controller;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  
  // 购物车按钮的GlobalKey，用于动画定位
  final GlobalKey _cartButtonKey = GlobalKey();
  
  // 每个类目在列表中的位置信息
  List<double> _categoryPositions = [];
  bool _isClickCategory = false;
  // 每个类目的锚点Key，用于动态测量位置
  final List<GlobalKey> _categoryKeys = [];
  static const double _stickyHeaderHeight = 40.0;
  static const double _inListHeaderHeight = 80.0;
  
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

  // 基类要求的抽象方法实现
  @override
  bool get isLoading => controller.isLoading.value;

  @override
  bool get hasNetworkError => controller.hasNetworkError.value;

  @override
  bool get hasData => controller.filteredDishes.isNotEmpty;

  @override
  bool get shouldShowSkeleton => true;

  @override
  Future<void> onRefresh() async {
    // 保存搜索框状态
    final currentSearchText = _searchController.text;
    final hasFocus = _searchFocusNode.hasFocus;
    
    await controller.refreshData();
    
    // 恢复搜索框状态
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && currentSearchText.isNotEmpty) {
          _searchController.text = currentSearchText;
          controller.searchKeyword.value = currentSearchText;
          
          // 如果之前有焦点，尝试恢复焦点
          if (hasFocus) {
            _searchFocusNode.requestFocus();
          }
        }
      });
    }
  }

  @override
  Widget buildDataContent() {
    return _buildMainDishContent();
  }

  /// 确保每个类目都有对应的GlobalKey
  void _ensureCategoryKeys() {
    final int needed = controller.categories.length;
    // 尽量复用已存在的key，避免频繁重建
    if (_categoryKeys.length < needed) {
      for (int i = _categoryKeys.length; i < needed; i++) {
        _categoryKeys.add(GlobalKey(debugLabel: 'category_anchor_$i'));
      }
    } else if (_categoryKeys.length > needed) {
      _categoryKeys.removeRange(needed, _categoryKeys.length);
    }
  }

  @override
  String getEmptyStateText() => '暂无菜品数据';

  @override
  String getNetworkErrorText() => '网络连接失败，请检查网络后重试';

  @override
  Widget? getNetworkErrorAction() {
    return ElevatedButton(
      onPressed: onRefresh,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFFF9027),
        foregroundColor: Colors.white,
      ),
      child: Text('重试'),
    );
  }

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
      // 重置位置计算状态，强制重新计算
      _categoryPositionsCalculated = false;
      _calculateCategoryPositions();
    });
  }

  /// 执行搜索功能 - 外卖页面专用
  void _performSearch() {
    // 强制释放焦点，确保光标消失
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    // 强制隐藏键盘
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    // 搜索提交时才计算位置
    _calculateCategoryPositions();
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
    const double categoryBottomSpace = 0.0; // 已移除底部间距

    for (int categoryIndex = 0; categoryIndex < controller.categories.length; categoryIndex++) {
      _categoryPositions.add(currentPosition);
      
      // 类目标题高度
      currentPosition += categoryHeaderHeight;
      
      // 该类目下的菜品数量
      final dishesInCategory = controller.filteredDishes
          .where((d) => d.categoryId == categoryIndex)
          .length;
      
      // 菜品列表高度 - 使用实际菜品数量，不再使用固定值
      currentPosition += dishesInCategory * itemHeight;
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
    if (!_scrollController.hasClients || controller.categories.isEmpty) return;

    // 使用动态锚点和Viewport来判断当前分类
    int calculatedIndex = 0;
    try {
      _ensureCategoryKeys();
      final double current = _scrollController.offset;
      final double line = current + _stickyHeaderHeight + 1; // 顶部吸顶线下方一点点

      for (int i = 0; i < _categoryKeys.length; i++) {
        final context = _categoryKeys[i].currentContext;
        if (context == null) continue;
        final renderObject = context.findRenderObject();
        if (renderObject == null || !renderObject.attached) continue;
        final viewport = RenderAbstractViewport.of(renderObject);
        // viewport不会为null（在滚动视图中），无需冗余判断

        final double revealOffset = viewport.getOffsetToReveal(renderObject, 0.0).offset;
        if (revealOffset <= line) {
          calculatedIndex = i;
        } else {
          break;
        }
      }
    } catch (_) {
      // 安静失败，保持原逻辑不崩溃
    }

    if (controller.selectedCategory.value != calculatedIndex) {
      controller.selectedCategory.value = calculatedIndex;
      
      // 预加载当前分类附近的图片
      _preloadNearbyImages(calculatedIndex);
    }
  }

  /// 预加载附近分类的图片
  void _preloadNearbyImages(int currentIndex) {
    if (controller.dishes.isEmpty) return;
    
    // 预加载当前分类前后2个分类的图片
    const int range = 2;
    ImageCacheManager().preloadNearbyImages(controller.dishes, currentIndex, range);
  }

  /// 滚动到指定类目
  void _scrollToCategory(int categoryIndex) async {
    if (controller.categories.isEmpty) return;
    
    if (categoryIndex < 0 || 
        categoryIndex >= controller.categories.length) return;

    _isClickCategory = true;
    // 立即更新选中的分类，确保吸顶头部文字立即更新
    controller.selectedCategory.value = categoryIndex;
    
    try {
      _ensureCategoryKeys();
      final ctx = _categoryKeys[categoryIndex].currentContext;
      if (ctx != null) {
        final ro = ctx.findRenderObject();
        if (ro != null && ro.attached) {
          // 第一个分类：直接置顶，无需滚动补偿
          if (categoryIndex == 0) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0);
            }
          } else {
            final viewport = RenderAbstractViewport.of(ro);
            // 目标 = 锚点显露offset - 吸顶头 + 列表内标题高度（避免重复标题重叠）
            double target = viewport.getOffsetToReveal(ro, 0.0).offset - _stickyHeaderHeight + _inListHeaderHeight;
            if (target < 0) target = 0;
            await _scrollController.animateTo(
              target,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      }
    } catch (e) {
      logError('❌ 滚动到类目失败: $e', tag: 'OrderDishTab');
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
      child: Obx(() => TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textAlignVertical: TextAlignVertical.center,
        // 性能优化配置
        enableInteractiveSelection: true,
        autocorrect: true,
        enableSuggestions: true,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        // 光标样式配置
        cursorColor: Colors.orange,
        cursorWidth: 1.0,
        cursorHeight: 16.0,
        decoration: InputDecoration(
          hintText: context.l10n.enterDishCodeOrName,
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
      )),
    );
  }

  /// 构建桌台信息文本，支持动态字号调整
  Widget _buildTableInfoText() {
    final tableName = controller.table.value?.tableName ?? 'null';
    final adultCount = controller.adultCount.value;
    final childCount = controller.childCount.value;

    final tableText = '${context.l10n.table}:$tableName';
    final adultText = '${context.l10n.adults}:$adultCount';
    final childText = '${context.l10n.children}:$childCount';

    // 当小孩数量为0时，不显示小孩信息
    final fullText = childCount == 0
        ? '$tableText | $adultText'
        : '$tableText | $adultText $childText';

    // 根据文本长度动态调整字号
    double fontSize = 12.0;
    if (fullText.length > 30) {
      fontSize = 10.0;
    } else if (fullText.length > 20) {
      fontSize = 11.0;
    }

    return Text(
      fullText,
      style: TextStyle(
        fontSize: fontSize,
        color: Color(0xff666666),
        fontWeight: FontWeight.w400,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  /// 构建搜索和筛选区域
  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Obx(() {
        // 如果是外卖页面，显示搜索框和搜索按钮
        if (controller.source.value == 'takeaway') {
          return Row(
            children: [
              Expanded(
                child: _buildSearchField(showClearIcon: true, showSearchIcon: false),
              ),
              SizedBox(width: 10),
              // 搜索按钮
              GestureDetector(
                onTap: () {
                  // 执行搜索功能
                  _performSearch();
                },
                child: Image(
                  image: AssetImage("assets/order_allergen_search.webp"),
                  width: 20,
                ),
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
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      height: 30,
                      child: !_showSearchField 
                        ? _buildTableInfoText()
                        : _buildSearchField(showClearIcon: true, showSearchIcon: false),
                    ),
                  ),
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
  Widget _buildMainDishContent() {
    return Obx(() {
      // 如果没有菜单ID，显示整个页面的空状态
      if (controller.menuId.value == 0) {
        return _buildEmptyState();
      }
      
      return Row(
        children: [
          _buildCategoryList(),
          _buildDishList(),
        ],
      );
    });
  }

  /// 构建分类列表
  Widget _buildCategoryList() {
    return Container(
      width: 72,
      color: Color(0xffF4F4F4),
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
                    .where((e) => e.key.dish.categoryId == index && _isRegularDish(e.key.dish))
                    .fold<int>(0, (sum, e) => sum + e.value);

                final selectedIndex = controller.selectedCategory.value;
                final isAboveSelected = index == selectedIndex - 1;
                final isBelowSelected = index == selectedIndex + 1;
                
                return GestureDetector(
                    onTap: () => _scrollToCategory(index),
                    child: Stack(
                      children: [
                        // 主容器
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 0,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Color(0xffF4F4F4),
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
                                        ? FontWeight.w500 
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (categoryCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        categoryCount > 99 ? '99+' : '$categoryCount',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // 向外扩散的圆角效果 - 在选中item的上下边缘
                        if (isSelected)
                          Positioned(
                            right: 0,
                            top: -12,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(0xffF4F4F4),
                                borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        if (isSelected)
                          Positioned(
                            right: 0,
                            bottom: -12,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(0xffF4F4F4),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
              },
            );
          },
        );
      }),
    );
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
          const SizedBox(height: 8),
          Text(
            context.l10n.noData,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFFF9027),
            ),
          ),
        ],
      ),
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
                  _categoryPositionsCalculated = false;
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
      logError('获取滚动偏移量时出错: $e', tag: 'OrderDishTab');
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
    
    // 确保锚点keys齐全
    _ensureCategoryKeys();

    // 确保位置信息已计算
    if (_categoryPositions.isEmpty || !_categoryPositionsCalculated) {
      _calculateCategoryPositions();
    }
    
    // 添加统一的吸顶分类头
    slivers.add(
      Obx(() => SliverPersistentHeader(
        pinned: true,
        delegate: _UnifiedStickyHeaderDelegate(
          height: _stickyHeaderHeight,
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
      )),
    );

    // 为第一个分类添加一个零高度的锚点，确保可被定位
    slivers.add(
      SliverToBoxAdapter(
        key: _categoryKeys.isNotEmpty ? _categoryKeys[0] : null,
        child: const SizedBox.shrink(),
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
              key: _categoryKeys[categoryIndex],
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
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF000000),
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
      cartButtonKey: _cartButtonKey, // 传递购物车按钮key用于动画
      onSpecificationTap: () {
        SpecificationModalWidget.showSpecificationModal(context, dish, cartButtonKey: _cartButtonKey);
      },
      onAddTap: () {
        controller.addToCart(dish);
      },
      onRemoveTap: () {
        controller.removeFromCart(dish);
      },
      onDishTap: () async {
        // 跳转到菜品详情页面
        final result = await Get.toNamed('/dish-detail-route', arguments: {'dish': dish});
        
        // 检查是否从菜品详情页面提交了订单
        if (result == 'order_submitted') {
          // 自动切换到已点页面
          _switchToOrderedTab();
        }
      },
    );
  }


  /// 判断是否为普通菜品（排除包餐费等非菜品项目）
  bool _isRegularDish(Dish dish) {
    // 优先使用 dish_type 字段判断
    // dish_type = 1: 正常菜品
    // dish_type = 3: 特殊项目（桌号、人数等），不计入分类数量
    if (dish.dishType == 3) {
      return false; // 特殊项目，不计入分类数量
    }
    
    // 如果 dish_type 不是 3，则认为是正常菜品
    return true;
  }

  /// 构建类目底部空间
  Widget _buildCategoryBottomSpace(int categoryIndex) {
    // 检查数据是否有效
    if (controller.categories.isEmpty) {
      return Container(height: 0, color: Colors.white);
    }
    
    return Container(
      height: 0, // 去掉所有分类间距
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
    
    // 根据服务员设置决定是否显示确认弹窗
    if (controller.waiterSetting.value.confirmOrderBeforeSubmit) {
      // 显示确认下单弹窗 - 与退出登录弹窗保持完全一致
      final confirm = await ModalUtils.showConfirmDialog(
        context: context,
        message: context.l10n.confirmOrder,  // 使用message参数，不使用title
        confirmText: context.l10n.confirm,
        cancelText: context.l10n.cancel,
        confirmColor: Color(0xFFFF9027), // 使用橙色确认按钮，与退出登录一致
      );
      
      // 如果用户取消，直接返回
      if (confirm != true) return;
    }
    
    // 根据订单来源判断处理方式
    if (controller.source.value == 'takeaway') {
      // 外卖订单：直接提交订单（不跳转到备注页面）
      _submitTakeawayOrder();
    } else {
      // 桌台订单：直接提交订单
      _submitTableOrder();
    }
  }


  /// 提交桌台订单
  Future<void> _submitTableOrder() async {
    if (!mounted) return;
    
    try {
      // 显示纯动画加载弹窗（无文字）
      OrderSubmitDialog.showLoadingOnly(context);
      
      final result = await controller.submitOrder();
      
      if (!mounted) return;
      
      // 关闭加载弹窗
      Navigator.of(context).pop();
      
      if (result['success'] == true) {
        // 下单成功，显示成功提示
        GlobalToast.success(context.l10n.orderPlacedSuccessfully);
        // 刷新已点订单数据后切换到已点页面
        controller.loadCurrentOrder(showLoading: false);
        _switchToOrderedTab();
      } else {
        // 下单失败，显示错误提示
        GlobalToast.error(result['message'] ?? context.l10n.failed);
      }
    } catch (e) {
      logError('❌ 提交订单异常: $e', tag: 'OrderDishTab');
      if (mounted) {
        // 关闭加载弹窗
        Navigator.of(context).pop();
        // 显示错误提示
        GlobalToast.error(context.l10n.networkErrorPleaseTryAgain);
      }
    }
  }

  /// 提交外卖订单（直接提交，不跳转到备注页面）
  Future<void> _submitTakeawayOrder() async {
    if (!mounted) return;
    
    try {
      // 显示纯动画加载弹窗（无文字）
      OrderSubmitDialog.showLoadingOnly(context);
      
      // 获取桌台ID
      final tableId = controller.table.value?.tableId;
      if (tableId == null || tableId <= 0) {
        if (mounted) {
          Navigator.of(context).pop();
          ToastUtils.showError(context, context.l10n.operationTooFrequentPleaseTryAgainLater);
        }
        return;
      }
      
      // 准备提交参数（包含备注）
      final params = {
        'table_id': tableId,
        'remark': controller.remark.value, // 提交备注
      };
      
      // 调用外卖订单提交API
      final result = await HttpManagerN.instance.executePost(
        '/api/waiter/cart/submit_takeout_order',
        jsonParam: params,
      );
      
      if (!mounted) return;
      
      // 关闭加载弹窗
      Navigator.of(context).pop();
      
      if (result.isSuccess) {
        // 下单成功，清空备注
        controller.clearRemark();
        // 显示成功提示
        ToastUtils.showSuccess(context, '订单提交成功');
        // 跳转到主页面并切换到外卖标签页，同时刷新桌台数据
        Get.offAll(() => ScreenNavPage(initialIndex: 1));
        // 延迟刷新桌台数据，确保页面切换完成
        Future.delayed(Duration(milliseconds: 500), () {
          NavigationManager.refreshTableData();
        });
      } else {
        // 下单失败，显示错误提示
        final errorMessage = result.msg ?? '订单提交失败';
        ToastUtils.showError(context, errorMessage);
      }
    } catch (e) {
      logError('❌ 提交外卖订单异常: $e', tag: 'OrderDishTab');
      if (mounted) {
        // 关闭加载弹窗
        Navigator.of(context).pop();
        // 显示错误提示
        ToastUtils.showError(context, '${context.l10n.networkErrorPleaseTryAgain}');
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
      logError('切换到已点页面失败: $e', tag: 'OrderDishTab');
    }
  }

  /// 构建底部购物车按钮
  Widget _buildBottomCartButton() {
    return GetBuilder<OrderController>(
      builder: (controller) {
        final totalCount = controller.totalCount;
        final totalPrice = controller.totalPrice;
        
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
                key: _cartButtonKey, // 添加GlobalKey用于动画定位
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
                      '€',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1,
                        color: Color(0xFFFF1010),
                       ),
                    ),
                    Text(
                      totalCount > 0 ? '$totalPrice' : '0',
                      style: TextStyle(
                        fontSize: 24,
                        height: 1,
                        color: Color(0xFFFF1010),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // 下单按钮
              GestureDetector(
                onTap: _handleSubmitOrder,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9027),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child:   Text(
                    context.l10n.placeOrder,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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
      child: Stack(
        children: [
          // 主要内容区域
          Column(
            children: [
              // 搜索 + 排序
              _buildSearchAndFilter(),
              // 主体内容区域
              buildMainContent(),
              // 底部占位空间，为固定按钮留出空间
              SizedBox(height: 60),
            ],
          ),
          // 固定在底部的购物车按钮
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomCartButton(),
          ),
        ],
      ),
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
    // 优先使用selectedCategory，如果没有则根据滚动位置计算
    int currentCategoryIndex = selectedCategory >= 0 && selectedCategory < categories.length 
        ? selectedCategory 
        : _getCurrentCategoryIndex();
    
    // 检查索引是否有效
    if (currentCategoryIndex < 0 || currentCategoryIndex >= categories.length) {
      return Container(height: height, color: Colors.white);
    }
    
    return Container(
      height: height,
      margin: EdgeInsets.only(left: 10),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 毛玻璃模糊效果
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Color(0x90F4F4F4), // 半透明背景色
              boxShadow: overlapsContent ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ] : null,
            ),
            child: _buildCategoryHeader(currentCategoryIndex),
          ),
        ),
      ),
    );
  }

  /// 获取当前应该显示的类目索引
  int _getCurrentCategoryIndex() {
    if (categoryPositions.isEmpty || categories.isEmpty) return 0;
    
    // 根据滚动位置确定当前类目
    // 添加一个小的偏移量来确保更准确的匹配
    const double offsetThreshold = 20.0;
    
    for (int i = categoryPositions.length - 1; i >= 0; i--) {
      if (scrollOffset >= (categoryPositions[i] - offsetThreshold)) {
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
      padding: EdgeInsets.symmetric(horizontal: 16).copyWith(left: 0),
      margin: EdgeInsets.only(left: 10),
      alignment: Alignment.centerLeft,
      child: Text(
        categoryName,maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          
          fontWeight: FontWeight.w500,
          color: Color(0xFF000000),
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
