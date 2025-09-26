import 'package:flutter/material.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:lib_domain/entrity/home/lobby_list_model/lobby_list_model.dart';
import 'package:order_app/utils/toast_utils.dart';
import '../../../constants/global_colors.dart';
import 'package:lib_domain/api/base_api.dart';
import 'package:order_app/pages/table/sub_page/select_menu_page.dart';
import 'package:order_app/pages/order/order_main_page.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/table/card/table_card.dart';
import 'package:order_app/widgets/base_list_page_widget.dart';
import 'package:order_app/components/skeleton_widget.dart';
import 'package:order_app/utils/pull_to_refresh_wrapper.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class MergeTablesPage extends BaseListPageWidget {
  final List<List<TableListModel>> allTabTables;
  final List<TableMenuListModel> menuModelList;
  final LobbyListModel lobbyListModel;
  final TableListModel? mergedTable;

  const MergeTablesPage({
    super.key,
    required this.allTabTables,
    required this.menuModelList,
    required this.lobbyListModel,
    this.mergedTable,
  });

  @override
  State<MergeTablesPage> createState() => _MergeTablesPageState();
}

class _MergeTablesPageState extends BaseListPageState<MergeTablesPage> with TickerProviderStateMixin {
  final RefreshController _refreshController = RefreshController();
  final List<String> selectedTableIds = [];
  final BaseApi _baseApi = BaseApi();
  bool _isMerging = false;
  
  // Tab相关
  late TabController _tabController;
  var lobbyListModel = LobbyListModel(halls: []).obs;
  var tabDataList = <RxList<TableListModel>>[].obs;
  var selectedTab = 0.obs;
  var _isLoading = false.obs;
  var _hasError = false.obs;
  var errorMessage = ''.obs;
  
  // 预加载相关
  var _preloadedTabs = <int>{}.obs; // 已预加载的tab索引
  var _preloadingTabs = <int>{}.obs; // 正在预加载的tab索引
  final int _maxPreloadRange = 1; // 预加载范围：前后各1个tab
  
  // Tab滚动相关
  late ScrollController _tabScrollController;

  @override
  void initState() {
    super.initState();
    // 如果传入了已合并的桌台，自动选中
    if (widget.mergedTable != null) {
      selectedTableIds.add(widget.mergedTable!.tableId.toString());
    }
    
    // 初始化tab滚动控制器
    _tabScrollController = ScrollController();
    
    // 初始化tab数据
    _initializeTabData();
  }
  
  /// 初始化tab数据
  void _initializeTabData() {
    lobbyListModel.value = widget.lobbyListModel;
    final halls = lobbyListModel.value.halls ?? [];
    
    // 初始化tabDataList
    tabDataList.value = List.generate(
      halls.length,
      (_) => <TableListModel>[].obs,
    );
    
    // 初始化TabController
    _tabController = TabController(length: halls.length, vsync: this);
    _tabController.addListener(() {
      selectedTab.value = _tabController.index;
      // 处理tab切换逻辑
      _handleTabSwitch(_tabController.index);
      // 滚动tab到可视区域
      _scrollToTab(_tabController.index);
    });
    
    // 获取第一个tab的数据
    _fetchDataForTab(0);
  }
  
  /// 获取指定tab的数据
  Future<void> _fetchDataForTab(int index) async {
    if (index >= tabDataList.length) return;
    
    _isLoading.value = true;
    _hasError.value = false;
    errorMessage.value = '';
    
    try {
      final result = await _baseApi.getTableList(
        hallId: lobbyListModel.value.halls!.isNotEmpty
            ? lobbyListModel.value.halls![index].hallId.toString()
            : "0",
      );
      
      if (result.isSuccess) {
        List<TableListModel> data = result.data!;
        tabDataList[index].value = data;
        _hasError.value = false;
        // 标记为已预加载
        _preloadedTabs.add(index);
      } else {
        _hasError.value = true;
        errorMessage.value = result.msg ?? '数据加载失败';
        tabDataList[index].value = [];
      }
    } catch (e) {
      _hasError.value = true;
      errorMessage.value = '网络连接异常，请检查网络后重试';
      tabDataList[index].value = [];
    }
    
    _isLoading.value = false;
    
    // 当前tab加载完成后，预加载相邻tab
    _preloadAdjacentTabs(index);
  }
  
  /// 预加载相邻tab的数据
  void _preloadAdjacentTabs(int currentIndex) {
    final totalTabs = lobbyListModel.value.halls?.length ?? 0;
    if (totalTabs <= 1) return; // 只有一个tab时不需要预加载
    
    // 计算需要预加载的tab范围
    final startIndex = (currentIndex - _maxPreloadRange).clamp(0, totalTabs - 1);
    final endIndex = (currentIndex + _maxPreloadRange).clamp(0, totalTabs - 1);
    
    // 预加载范围内的tab（排除当前tab）
    for (int i = startIndex; i <= endIndex; i++) {
      if (i != currentIndex && 
          i < tabDataList.length && 
          !_preloadedTabs.contains(i) && 
          !_preloadingTabs.contains(i)) {
        _preloadTabData(i);
      }
    }
  }

  /// 预加载指定tab的数据
  Future<void> _preloadTabData(int index) async {
    if (index >= tabDataList.length) return;
    
    _preloadingTabs.add(index);
    
    try {
      final result = await _baseApi.getTableList(
        hallId: lobbyListModel.value.halls!.isNotEmpty
            ? lobbyListModel.value.halls![index].hallId.toString()
            : "0",
      );
      
      if (result.isSuccess) {
        List<TableListModel> data = result.data!;
        tabDataList[index].value = data;
        _preloadedTabs.add(index);
        print('✅ 并桌页面预加载tab $index 数据成功，桌台数量: ${data.length}');
      } else {
        print('❌ 并桌页面预加载tab $index 数据失败: ${result.msg}');
      }
    } catch (e) {
      print('❌ 并桌页面预加载tab $index 数据异常: $e');
    } finally {
      _preloadingTabs.remove(index);
    }
  }
  
  /// 滚动tab到屏幕中间
  void _scrollToTab(int index) {
    if (!_tabScrollController.hasClients) return;
    
    // 获取总tab数量
    int totalTabs = lobbyListModel.value.halls?.length ?? 0;
    if (totalTabs == 0) return;
    
    // 计算目标tab在总宽度中的比例位置
    double tabRatio = index / (totalTabs - 1).clamp(1, double.infinity);
    
    // 计算目标滚动位置，让选中的tab显示在屏幕中央
    double maxScrollPosition = _tabScrollController.position.maxScrollExtent;
    
    // 使用更简单的计算方式，直接根据比例滚动到对应位置
    double targetScrollPosition = maxScrollPosition * tabRatio;
    
    // 确保滚动位置在有效范围内
    targetScrollPosition = targetScrollPosition.clamp(0.0, maxScrollPosition);
    
    // 执行滚动动画
    _tabScrollController.animateTo(
      targetScrollPosition,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  /// 处理tab切换逻辑
  void _handleTabSwitch(int index) {
    // 如果该tab已经预加载过，直接显示数据，不需要重新加载
    if (_preloadedTabs.contains(index)) {
      print('✅ 并桌页面Tab $index 已预加载，直接显示数据');
      // 预加载相邻tab
      _preloadAdjacentTabs(index);
    } else {
      // 如果该tab没有预加载过，正常加载
      print('🔄 并桌页面Tab $index 未预加载，开始加载数据');
      _fetchDataForTab(index);
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _tabScrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  // 实现抽象类要求的方法
  @override
  bool get isLoading => _isLoading.value;

  @override
  bool get hasNetworkError => _hasError.value;

  @override
  bool get hasData {
    final currentTabIndex = selectedTab.value;
    if (currentTabIndex < tabDataList.length) {
      return tabDataList[currentTabIndex].isNotEmpty;
    }
    return false;
  }
  
  @override
  bool get shouldShowSkeleton => !hasData;

  @override
  Future<void> onRefresh() async {
    final currentTabIndex = selectedTab.value;
    await _fetchDataForTab(currentTabIndex);
  }
  
  @override
  Widget buildSkeletonWidget() {
    return const TablePageSkeleton();
  }

  /// 获取所有可用的桌台（合并所有tab的数据）
  List<TableListModel> _getAllAvailableTables() {
    List<TableListModel> allTables = [];
    
    // 合并所有tab的桌台数据
    for (var tabTables in widget.allTabTables) {
      allTables.addAll(tabTables);
    }
    
    // 去重：根据桌台ID去重，保留第一个出现的桌台
    Map<int, TableListModel> uniqueTables = {};
    for (var table in allTables) {
      final tableId = table.tableId.toInt();
      if (!uniqueTables.containsKey(tableId)) {
        uniqueTables[tableId] = table;
      }
    }
    
    // 过滤出可用的桌台
    return uniqueTables.values.where((table) {
      final status = table.businessStatus.toInt();
      return status != 5 && status != 6; // 排除不可用和维修中的桌台
    }).toList();
  }


  /// 切换桌台选择状态
  void _toggleTableSelection(String tableId) {
    setState(() {
      if (selectedTableIds.contains(tableId)) {
        selectedTableIds.remove(tableId);
      } else {
        selectedTableIds.add(tableId);
      }
    });
  }


  /// 根据桌台ID获取桌台信息
  TableListModel? _getTableById(String tableId) {
    final allTables = _getAllAvailableTables();
    try {
      final id = int.parse(tableId);
      return allTables.firstWhere((table) => table.tableId == id);
    } catch (e) {
      return null;
    }
  }

  /// 确认并桌操作
  Future<void> _confirmMerge() async {
    if (selectedTableIds.length < 2) {
      GlobalToast.error('请至少选择2个桌台进行合并');
      return;
    }

    if (_isMerging) {
      return; // 防止重复点击
    }

    setState(() {
      _isMerging = true;
    });

    try {
      // 显示加载提示（使用临时提示，会自动取消之前的提示）
      GlobalToast.message('正在合并桌台...');

      // 转换桌台ID为整数列表
      final tableIds = selectedTableIds.map((id) => int.parse(id)).toList();

      // 调用并桌API
      final result = await _baseApi.mergeTables(tableIds: tableIds);

      if (result.isSuccess && result.data != null) {
        // 并桌成功，直接使用返回的桌台详情
        await _handleMergeSuccess(result.data!);
      } else {
        // 并桌失败，显示错误
        GlobalToast.error(result.msg ?? '并桌失败');
      }
    } catch (e) {
      // 网络错误，显示错误
      GlobalToast.error('并桌操作失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isMerging = false;
        });
      }
    }
  }

  /// 处理并桌成功后的逻辑
  Future<void> _handleMergeSuccess(TableListModel mergedTable) async {
    try {
      // 显示成功提示
      GlobalToast.success('桌台合并成功');

      // 判断选中的桌子中是否有非空闲桌子
      final hasNonEmptyTables = _hasNonEmptyTables();
      
      if (hasNonEmptyTables) {
        // 有非空闲桌子，直接进入点餐页面
        await _navigateToOrderPage(mergedTable);
      } else {
        // 全是空闲桌子，进入菜单选择页面
        await _navigateToSelectMenuPage(mergedTable);
      }
    } catch (e) {
      // 跳转异常，显示错误
      GlobalToast.error('跳转失败: $e');
    }
  }

  /// 判断选中的桌子中是否有非空闲桌子
  bool _hasNonEmptyTables() {
    for (String tableId in selectedTableIds) {
      final table = _getTableById(tableId);
      if (table != null && table.businessStatus != 0) {
        // 找到非空闲桌子（状态不是0）
        return true;
      }
    }
    return false;
  }

  /// 获取非空闲桌子的菜单信息
  TableMenuListModel? _getNonEmptyTableMenu() {
    for (String tableId in selectedTableIds) {
      final table = _getTableById(tableId);
      if (table != null && table.businessStatus != 0) {
        // 找到非空闲桌子，返回其菜单
        return widget.menuModelList.firstWhere(
          (menu) => menu.menuId == table.menuId,
          orElse: () => widget.menuModelList.first, // 如果找不到匹配的菜单，返回第一个
        );
      }
    }
    return null;
  }

  /// 跳转到菜单选择页面
  Future<void> _navigateToSelectMenuPage(TableListModel mergedTable) async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectMenuPage(),
        settings: RouteSettings(
          arguments: {
            'table': mergedTable,
            'menu': widget.menuModelList,
            'table_id': mergedTable.tableId,
            'isFromMerge': true, // 标记来自并桌操作
          },
        ),
      ),
    );
  }

  /// 直接跳转到点餐页面
  Future<void> _navigateToOrderPage(TableListModel mergedTable) async {
    // 获取非空闲桌子的菜单
    final selectedMenu = _getNonEmptyTableMenu();
    if (selectedMenu == null) {
      GlobalToast.error('无法获取菜单信息');
      return;
    }

    // 准备传递给点餐页面的数据
    final orderData = {
      'table': mergedTable,
      'menu': selectedMenu,
      'table_id': mergedTable.tableId,
      'menu_id': selectedMenu.menuId,
      'adult_count': mergedTable.currentAdult > 0 ? mergedTable.currentAdult.toInt() : mergedTable.standardAdult.toInt(),
      'child_count': mergedTable.currentChild.toInt(),
      'isFromMerge': true, // 标识来自并桌操作
    };

    // 跳转到点餐页面
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OrderMainPage(),
        settings: RouteSettings(arguments: orderData),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.primaryBackground,
      appBar: AppBar(
        title: const Text('并桌'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Image.asset(
            'assets/order_arrow_back.webp',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          GestureDetector(
            onTap: (selectedTableIds.length >= 2 && !_isMerging) ? _confirmMerge : null,
            child: Container(
              margin: EdgeInsets.only(right: 15),
              padding: EdgeInsets.symmetric(horizontal: 12),
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: (selectedTableIds.length >= 2 && !_isMerging) 
                    ? Color(0xffFF9027) 
                    : Color(0xffCCCCCC),
              ),
              alignment: Alignment.center,
              child: _isMerging
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      '确认',
                      style: TextStyle(
                        color: (selectedTableIds.length >= 2 && !_isMerging) 
                            ? Colors.white 
                            : Color(0xff999999), 
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: _buildMergeTablesPageBody(),
    );
  }

  /// 构建并桌页面主体内容
  Widget _buildMergeTablesPageBody() {
    return Obx(() {
      final halls = lobbyListModel.value.halls ?? [];
      
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
  
  /// Tab 按钮 - 与桌台页面相同的样式
  Widget _tabButton(String title, int index, int tableCount) {
    return Obx(() {
      bool selected = selectedTab.value == index;
      return GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          _handleTabSwitch(index);
          // 滚动tab到可视区域
          _scrollToTab(index);
        },
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
  
  /// 构建可刷新的网格 - 与桌台页面相同的样式
  Widget _buildRefreshableGrid(RxList<TableListModel> data, int tabIndex) {
    return Obx(() {
      return PullToRefreshWrapper(
        controller: _refreshController,
        onRefresh: () async {
          try {
            await _fetchDataForTab(tabIndex);
            // 通知刷新完成
            _refreshController.refreshCompleted();
          } catch (e) {
            print('❌ 并桌页面刷新失败: $e');
            // 刷新失败也要通知完成
            _refreshController.refreshFailed();
          }
        },
        child: CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: data.isEmpty
                  ? SliverFillRemaining(
                      child: _isLoading.value
                          ? buildLoadingWidget()
                          : (_hasError.value ? buildNetworkErrorState() : buildEmptyState()),
                    )
                  : SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 13,
                        childAspectRatio: 1.33, // 根据UI设计稿调整：165/124 = 1.33
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final table = data[index];
                          final isSelected = selectedTableIds.contains(table.tableId.toString());
                          
                          return GestureDetector(
                            onTap: () => _toggleTableSelection(table.tableId.toString()),
                            child: TableCard(
                              table: table,
                              tableModelList: widget.menuModelList,
                              isSelected: isSelected,
                              isMergeMode: true,
                            ),
                          );
                        },
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
      final halls = lobbyListModel.value.halls ?? [];

      // 保证 tabDataList 与 halls 对齐
      while (tabDataList.length < halls.length) {
        tabDataList.add(<TableListModel>[].obs);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Row - 与桌台页面相同的样式
          Container(
            color: Colors.transparent,
            child: SingleChildScrollView(
              controller: _tabScrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(halls.length, (index) {
                  final hallName = halls[index].hallName ?? '未知';
                  return Row(
                    children: [
                      SizedBox(width: 12),
                      _tabButton(
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
          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(halls.length, (index) {
                return _buildTabContent(index);
              }),
            ),
          ),
        ],
      );
    });
  }

  /// 构建单个tab的内容
  Widget _buildTabContent(int tabIndex) {
    return Obx(() {
      final data = tabDataList[tabIndex];
      
      // 如果当前tab正在加载且没有数据，显示加载状态
      if (isLoading && data.isEmpty) {
        return buildLoadingWidget();
      }
      
      // 如果当前tab有网络错误，显示网络错误状态
      if (hasNetworkError && data.isEmpty) {
        return buildNetworkErrorState();
      }
      
      // 无论是否有数据，都使用可刷新的网格布局
      // 这样空数据状态也能进行下拉刷新
      return _buildRefreshableGrid(data, tabIndex);
    });
  }
}
