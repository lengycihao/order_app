import 'package:flutter/material.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:lib_domain/entrity/home/lobby_list_model/lobby_list_model.dart';
import 'package:order_app/utils/l10n_utils.dart';
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
import 'package:lib_base/logging/logging.dart';
import 'package:order_app/cons/table_status.dart';

class MergeTablesPage extends BaseListPageWidget {
  final List<List<TableListModel>> allTabTables;
  final List<TableMenuListModel> menuModelList;
  final LobbyListModel lobbyListModel;
  final TableListModel? mergedTable;
  final bool hasInitialNetworkError;

  const MergeTablesPage({
    super.key,
    required this.allTabTables,
    required this.menuModelList,
    required this.lobbyListModel,
    this.mergedTable,
    this.hasInitialNetworkError = false,
  });

  @override
  State<MergeTablesPage> createState() => _MergeTablesPageState();
}

class _MergeTablesPageState extends BaseListPageState<MergeTablesPage> with TickerProviderStateMixin {
  // 每个tab一个独立的RefreshController
  final List<RefreshController> _refreshControllers = [];
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
  
  // 已选桌台区域滚动控制器
  late ScrollController _selectedTablesScrollController;

  @override
  void initState() {
    super.initState();
    // 如果传入了已合并的桌台，自动选中
    if (widget.mergedTable != null) {
      selectedTableIds.add(widget.mergedTable!.tableId.toString());
    }
    
    // 初始化tab滚动控制器
    _tabScrollController = ScrollController();
    
    // 初始化已选桌台滚动控制器
    _selectedTablesScrollController = ScrollController();
    
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
    
    // 为每个tab创建独立的RefreshController
    _refreshControllers.clear();
    for (int i = 0; i < halls.length; i++) {
      _refreshControllers.add(RefreshController());
    }
    
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
    
    // 检查大厅数据是否有效
    if (lobbyListModel.value.halls == null || 
        lobbyListModel.value.halls!.isEmpty || 
        index >= lobbyListModel.value.halls!.length) {
      _hasError.value = true;
      errorMessage.value = '大厅数据无效或索引越界';
      tabDataList[index].value = [];
      return;
    }
    
    _isLoading.value = true;
    _hasError.value = false;
    errorMessage.value = '';
    
    try {
      final hallId = lobbyListModel.value.halls![index].hallId.toString();
      logDebug('🔄 合并桌台页面获取tab $index 数据: hallId=$hallId');
      
      final result = await _baseApi.getTableList(hallId: hallId);
      
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
        // 加载失败时，从预加载成功列表中移除
        _preloadedTabs.remove(index);
        logError('❌ 合并桌台页面Tab $index 数据获取失败: ${result.msg}');
      }
    } catch (e) {
      _hasError.value = true;
      errorMessage.value = '网络连接异常，请检查网络后重试';
      tabDataList[index].value = [];
      // 加载失败时，从预加载成功列表中移除
      _preloadedTabs.remove(index);
      logError('❌ 合并桌台页面Tab $index 数据获取异常: $e');
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
    
    // 检查大厅数据是否有效
    if (lobbyListModel.value.halls == null || 
        lobbyListModel.value.halls!.isEmpty || 
        index >= lobbyListModel.value.halls!.length) {
      logError('❌ 合并桌台页面预加载tab $index 失败: 大厅数据无效或索引越界', tag: 'MergeTablesPage');
      return;
    }
    
    _preloadingTabs.add(index);
    
    try {
      final hallId = lobbyListModel.value.halls![index].hallId.toString();
      logDebug('🔄 合并桌台页面预加载tab $index 数据: hallId=$hallId', tag: 'MergeTablesPage');
      
      final result = await _baseApi.getTableList(hallId: hallId);
      
      if (result.isSuccess) {
        List<TableListModel> data = result.data!;
        tabDataList[index].value = data;
        _preloadedTabs.add(index);
        logDebug('✅ 合并桌台页面预加载tab $index 数据成功，桌台数量: ${data.length}', tag: 'MergeTablesPage');
      } else {
        logError('❌ 合并桌台页面预加载tab $index 数据失败: ${result.msg}', tag: 'MergeTablesPage');
      }
    } catch (e) {
      logError('❌ 合并桌台页面预加载tab $index 数据异常: $e', tag: 'MergeTablesPage');
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
      logDebug('并桌页面Tab $index 已预加载，直接显示数据', tag: 'MergeTablesPage');
      // 预加载相邻tab
      _preloadAdjacentTabs(index);
    } else {
      // 如果该tab没有预加载过，正常加载
      logDebug('并桌页面Tab $index 未预加载，开始加载数据', tag: 'MergeTablesPage');
      _fetchDataForTab(index);
    }
  }

  /// 处理重新加载逻辑
  Future<void> _handleReload() async {
    // 如果是初始网络错误或者halls为空，需要通知父页面重新获取lobby数据
    if (widget.hasInitialNetworkError || 
        lobbyListModel.value.halls == null || 
        lobbyListModel.value.halls!.isEmpty) {
      logDebug('并桌页面检测到初始网络错误或halls为空，返回桌台页面重新加载', tag: 'MergeTablesPage');
      
      // 返回桌台页面并携带重新加载的标识
      Navigator.of(context).pop(true); // 传递true表示需要重新加载
      return;
    }
    
    // 否则重新加载当前tab数据
    final currentTabIndex = selectedTab.value;
    await _fetchDataForTab(currentTabIndex);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _tabScrollController.dispose();
    _selectedTablesScrollController.dispose();
    // 释放所有RefreshController
    for (var controller in _refreshControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // 实现抽象类要求的方法
  @override
  bool get isLoading => _isLoading.value;

  @override
  bool get hasNetworkError => _hasError.value || widget.hasInitialNetworkError;

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
    Map<String, TableListModel> uniqueTables = {};
    for (var table in allTables) {
      final tableId = table.tableId;
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
        // 添加新桌台后，延迟滚动到底部以查看最新添加的桌台
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_selectedTablesScrollController.hasClients) {
            _selectedTablesScrollController.animateTo(
              _selectedTablesScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
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
      GlobalToast.message(context.l10n.merging);

      // 转换桌台ID为整数列表
      final tableIds = selectedTableIds.map((id) => int.parse(id)).toList();

      // 调用并桌API
      final result = await _baseApi.mergeTables(tableIds: tableIds.map((id) => id.toString()).toList());

      if (result.isSuccess && result.data != null) {
        // 并桌成功，直接使用返回的桌台详情
        await _handleMergeSuccess(result.data!);
      } else {
        // 并桌失败，显示错误
        GlobalToast.error(result.msg ?? Get.context!.l10n.mergeFailedPleaseRetry);
      }
    } catch (e) {
      // 网络错误，显示错误
      GlobalToast.error('${Get.context!.l10n.failed}: $e');
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
      GlobalToast.success(context.l10n.mergeSuccessful);

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
      GlobalToast.error('${Get.context!.l10n.failed}: $e');
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
      GlobalToast.error(Get.context!.l10n.noCanUseMenu);
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
        title: Text(context.l10n.mergeTables),
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
                      context.l10n.confirm,
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
  
  /// 构建可刷新的网格 - 与桌台页面相同的样式
  Widget _buildRefreshableGrid(RxList<TableListModel> data, int tabIndex) {
    return Obx(() {
      return PullToRefreshWrapper(
        controller: _refreshControllers[tabIndex],
        onRefresh: () async {
          try {
            await _fetchDataForTab(tabIndex);
            // 通知刷新完成
            _refreshControllers[tabIndex].refreshCompleted();
          } catch (e) {
            logError('并桌页面刷新失败: $e', tag: 'MergeTablesPage');
            // 刷新失败也要通知完成
            _refreshControllers[tabIndex].refreshFailed();
          }
        },
        child: CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: data.isEmpty
                  ? SliverFillRemaining(
                      child: buildEmptyState(),
                    )
                  : SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 13,
                        childAspectRatio: 1.4, // 调整宽高比以避免越界
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final table = data[index];
                          final isSelected = selectedTableIds.contains(table.tableId.toString());
                          final status = _getStatus(table.businessStatus.toInt());
                          // 不可用、维修中、已预定的桌台不能被选择
                          final isUnselectable = status == TableStatus.Unavailable || 
                                                 status == TableStatus.Maintenance || 
                                                 status == TableStatus.Reserved;
                          
                          return GestureDetector(
                            onTap: isUnselectable 
                                ? null 
                                : () => _toggleTableSelection(table.tableId.toString()),
                            child: Opacity(
                              opacity: isUnselectable ? 0.5 : 1.0,
                              child: TableCard(
                                table: table,
                                tableModelList: widget.menuModelList,
                                isSelected: isSelected,
                                isMergeMode: true,
                              ),
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
  String getEmptyStateText() => context.l10n.noCanUseTable;

  @override
  String getNetworkErrorText() => context.l10n.networkErrorPleaseTryAgain;
  
  /// 重写空状态操作按钮
  @override
  Widget? getEmptyStateAction() {
    return ElevatedButton(
      onPressed: () async {
        await _handleReload();
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
  
  /// 重写网络错误状态操作按钮
  @override
  Widget? getNetworkErrorAction() {
    return ElevatedButton(
      onPressed: () async {
        await _handleReload();
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
    );
  }

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
                  final hallName = halls[index].hallName ?? context.l10n.unknown;
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
          // 已选桌台信息显示区域
          if (selectedTableIds.isNotEmpty)
            _buildSelectedTablesInfo(),
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

  /// 构建已选桌台信息显示区域
  Widget _buildSelectedTablesInfo() {
    // 计算3行的高度：标签高度(28) * 3 + 行间距(8) * 2 = 100
    const double chipHeight = 28.0; // 标签高度
    const double runSpacing = 8.0; // 行间距
    const double maxHeight = chipHeight * 3 + runSpacing * 2; // 3行的最大高度
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFFF9027).withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${context.l10n.selected}（${selectedTableIds.length}）',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 8),
          // 限制最大高度为3行，超过时可滚动
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
            ),
            child: SingleChildScrollView(
              controller: _selectedTablesScrollController,
              physics: BouncingScrollPhysics(),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedTableIds.map((tableId) {
                  final table = _getTableById(tableId);
                  final tableName = table?.tableName ?? tableId;
                  return _buildTableChip(tableId, tableName);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个桌台标签（可点击取消选中）
  Widget _buildTableChip(String tableId, String tableName) {
    // 不再限制桌台名称长度，改为动态调整字体大小
    
    // 获取桌台状态颜色
    final table = _getTableById(tableId);
    final status = _getStatus(table?.businessStatus.toInt() ?? 0);
    final bgColor = _getStatusColor(status);
    // 空桌台用深色文字，其他状态用白色文字
    final textColor =  Color(0xff333333) ;
    
    return GestureDetector(
      onTap: () {
        // 取消选中该桌台
        setState(() {
          selectedTableIds.remove(tableId);
        });
      },
      child: Container(
        constraints: BoxConstraints(maxWidth: 200), // 增加标签最大宽度
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          // boxShadow: [
          //   BoxShadow(
          //     color: Color(0xFFFF9027).withOpacity(0.3),
          //     blurRadius: 4,
          //     offset: Offset(0, 2),
          //   ),
          // ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 根据文字长度动态调整字体大小
                  double fontSize = 13;
                  if (tableName.length > 12) {
                    fontSize = 11;
                  } else if (tableName.length > 8) {
                    fontSize = 12;
                  }
                  
                  return Text(
                    tableName,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  );
                },
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.close,
              size: 16,
              color: textColor,
            ),
          ],
        ),
      ),
    );
  }

  /// 根据业务状态码获取TableStatus
  TableStatus _getStatus(int status) {
    switch (status) {
      case 0:
        return TableStatus.Empty;
      case 1:
        return TableStatus.Occupied;
      case 2:
        return TableStatus.WaitingOrder;
      case 3:
        return TableStatus.PendingBill;
      case 4:
        return TableStatus.PreBilled;
      case 5:
        return TableStatus.Unavailable;
      case 6:
        return TableStatus.Maintenance;
      case 7:
        return TableStatus.Reserved;
    }
    return TableStatus.Empty;
  }

  /// 根据TableStatus获取背景色
  Color _getStatusColor(TableStatus status) {
    switch (status) {
      case TableStatus.Unavailable:
        return Color(0xff999999);
      case TableStatus.PendingBill:
        return Color(0xffF47E97);
      case TableStatus.PreBilled:
        return Color(0xff77DD77);
      case TableStatus.WaitingOrder:
        return Color(0xffFFD700);
      case TableStatus.Empty:
        return Colors.white;
      case TableStatus.Occupied:
        return Color(0xff999999);
      case TableStatus.Maintenance:
        return Color(0xff999999);
      case TableStatus.Reserved:
        return Color(0xff999999);
    }
  }

  /// 构建单个tab的内容
  Widget _buildTabContent(int tabIndex) {
    return Obx(() {
      final data = tabDataList[tabIndex];
      
      // 如果当前tab正在加载且没有数据，显示加载状态
      if (isLoading && data.isEmpty) {
        return buildLoadingWidget();
      }
      
      // 判断当前tab是否有网络错误：
      // 1. 全局有错误状态
      // 2. 当前tab没有数据 
      // 3. 当前tab不在预加载成功列表中（说明加载失败了）
      bool currentTabHasError = hasNetworkError && 
                               data.isEmpty && 
                               !_preloadedTabs.contains(tabIndex);
      
      // 如果当前tab有网络错误，显示网络错误状态
      if (currentTabHasError) {
        return buildNetworkErrorState();
      }
      
      // 无论是否有数据，都使用可刷新的网格布局
      // 这样空数据状态也能进行下拉刷新
      return _buildRefreshableGrid(data, tabIndex);
    });
  }
}
