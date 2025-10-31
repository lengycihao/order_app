import 'package:flutter/material.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:lib_domain/entrity/home/lobby_list_model/lobby_list_model.dart';
import 'package:lib_domain/entrity/table/close_reason_model.dart';
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
import 'package:order_app/pages/table/sub_page/merge_tables_controller.dart';

class MergeTablesPage extends BaseListPageWidget {
  final List<TableMenuListModel> menuModelList;
  final TableListModel? mergedTable;
  final String? operationType; // 操作类型：merge(并桌)、close(关桌)、remove(撤桌)

  const MergeTablesPage({
    super.key,
    required this.menuModelList,
    this.mergedTable,
    this.operationType,
  });

  @override
  State<MergeTablesPage> createState() => _MergeTablesPageState();
}

class _MergeTablesPageState extends BaseListPageState<MergeTablesPage>
    with TickerProviderStateMixin {
  // Controller 用于业务逻辑
  late MergeTablesController _controller;
  
  // 每个tab一个独立的RefreshController
  final List<RefreshController> _refreshControllers = [];
  final List<String> selectedTableIds = [];
  final BaseApi _baseApi = BaseApi();
  bool _isMerging = false;
  
  // 撤桌状态下，选中要移除的桌台列表
  final List<String> selectedRemoveTableIds = [];

  // Tab相关
  late TabController _tabController;

  // Tab滚动相关
  late ScrollController _tabScrollController;

  // 已选桌台区域滚动控制器
  late ScrollController _selectedTablesScrollController;

  // 使用 controller 的状态变量
  var lobbyListModel = LobbyListModel(halls: []).obs;
  var tabDataList = <RxList<TableListModel>>[].obs;
  var selectedTab = 0.obs;
  var _isLoading = false.obs;
  var _hasError = false.obs;
  var errorMessage = ''.obs;
  var _preloadedTabs = <int>{}.obs;
  var closeReasonList = <CloseReasonModel>[].obs;
  var selectedCloseReason = Rx<CloseReasonModel?>(null);
  var isLoadingCloseReasons = false.obs;
  var isReasonDrawerVisible = false.obs;

  @override
  void initState() {
    super.initState();
    
    // 初始化 controller
    _controller = Get.put(MergeTablesController(), tag: 'merge_tables_${DateTime.now().millisecondsSinceEpoch}');
    _controller.operationType = widget.operationType;
    
    // 同步 controller 的状态到页面变量（保持 UI 代码不变）
    lobbyListModel = _controller.lobbyListModel;
    tabDataList = _controller.tabDataList;
    selectedTab = _controller.selectedTab;
    _isLoading = _controller.isLoading;
    _hasError = _controller.hasError;
    errorMessage = _controller.errorMessage;
    _preloadedTabs = _controller.preloadedTabs;
    closeReasonList = _controller.closeReasonList;
    selectedCloseReason = _controller.selectedCloseReason;
    isLoadingCloseReasons = _controller.isLoadingCloseReasons;
    isReasonDrawerVisible = _controller.isReasonDrawerVisible;
    
    // 如果传入了已合并的桌台，自动选中
    if (widget.mergedTable != null) {
      selectedTableIds.add(widget.mergedTable!.tableId.toString());
    }

    // 初始化tab滚动控制器
    _tabScrollController = ScrollController();

    // 初始化已选桌台滚动控制器
    _selectedTablesScrollController = ScrollController();

    // 初始化数据并加载大厅列表
    _initializeData();
  }
  
  /// 初始化数据
  Future<void> _initializeData() async {
    // 调用 controller 初始化数据（会自动获取大厅列表）
    await _controller.initializeData();
    
    // 大厅数据加载完成后，初始化tab相关
    final halls = lobbyListModel.value.halls ?? [];
    if (halls.isNotEmpty) {
    _initializeTabData();
    }
  }

  /// 初始化tab数据
  void _initializeTabData() {
    final halls = lobbyListModel.value.halls ?? [];

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
      
      // 如果是关桌页面，加载关桌原因列表
      if (widget.operationType == 'close') {
        _loadCloseReasons();
      }
    }

  /// 获取指定tab的数据（委托给 controller）
  Future<void> _fetchDataForTab(int index) async {
    await _controller.fetchDataForTab(index);
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

  /// 处理tab切换逻辑（委托给 controller）
  void _handleTabSwitch(int index) {
    _controller.handleTabSwitch(index);
  }

  /// 处理重新加载逻辑
  Future<void> _handleReload() async {
    // 重新初始化数据（会重新获取大厅列表）
    await _initializeData();
  }

  /// 加载关桌原因列表（委托给 controller）
  Future<void> _loadCloseReasons() async {
    await _controller.loadCloseReasons();
  }

  /// 切换原因选择抽屉显示/隐藏（委托给 controller）
  void _toggleReasonDrawer() {
    _controller.toggleReasonDrawer();
  }

  /// 隐藏原因选择抽屉（委托给 controller）
  void _hideReasonDrawer() {
    _controller.hideReasonDrawer();
  }

  /// 构建原因抽屉内容
  Widget _buildReasonDrawerContent() {
    return Obx(() {
      if (isLoadingCloseReasons.value) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12,vertical: 5),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9027)),
              ),
            ),
          ),
        );
      }

      if (closeReasonList.isEmpty) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              context.l10n.noData,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        );
      }

      const itemHeight = 32.0;
      
      return ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero, // 移除默认的内边距
        physics: NeverScrollableScrollPhysics(),
        itemCount: closeReasonList.length,
        separatorBuilder: (context, index) => SizedBox.shrink(), // 移除分隔线，改用边距
        itemBuilder: (context, index) {
          final reason = closeReasonList[index];
          final isLast = index == closeReasonList.length - 1;
          
          return Obx(() {
            final isSelected = selectedCloseReason.value?.value == reason.value;
            
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                selectedCloseReason.value = reason;
                _hideReasonDrawer();
              },
              child: Container(
                height: itemHeight,
                padding: EdgeInsets.symmetric(horizontal: 12,vertical: 5),
                margin: EdgeInsets.only(
                  bottom: isLast ? 0 : 1, // 最后一项不需要下边距
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Color(0x33FF9027) : Colors.white, // #FF9027 20% 透明度 (0x33 = 20%)
                  borderRadius: BorderRadius.circular(4), 
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        reason.label,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? Color(0xFFFF9027) : Color(0xFF333333),
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        size: 16,
                        color: Color(0xFFFF9027),
                      ),
                  ],
                ),
              ),
            );
          });
        },
      );
    });
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
    for (var tabTables in tabDataList) {
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
        // 关桌和撤桌状态下只能单选，清空其他选择
        if (widget.operationType == 'close' || widget.operationType == 'remove') {
          selectedTableIds.clear();
        }
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
      final id = tableId;
      return allTables.firstWhere((table) => table.tableId == id);
    } catch (e) {
      return null;
    }
  }

  /// 确认操作（并桌/关桌/撤桌）
  Future<void> _confirmMerge() async {
    final minTablesRequired = _needAtLeastTwoTables() ? 2 : 1;
    if (selectedTableIds.length < minTablesRequired) {
      if (widget.operationType == 'merge' || widget.operationType == null) {
        GlobalToast.error(context.l10n.pleaseSelectAtLeastTwoTables);
      } else {
        GlobalToast.error(context.l10n.pleaseSelectAtLeastOneTable);
      }
      return;
    }

    if (_isMerging) {
      return; // 防止重复点击
    }

    setState(() {
      _isMerging = true;
    });

    try {
      // 根据类型显示不同的加载提示
      if (widget.operationType == 'close') {
        GlobalToast.message(context.l10n.closingTable);
      } else if (widget.operationType == 'remove') {
        GlobalToast.message(context.l10n.removingTable);
      } else {
        GlobalToast.message(context.l10n.merging);
      }

      // 根据操作类型执行不同的逻辑
      if (widget.operationType == 'close') {
        // 关桌操作：调用changeTableStatus API
        final tableId = selectedTableIds.first; // 关桌只能单选
        final reasonId = selectedCloseReason.value?.value;
        
        if (reasonId == null) {
          GlobalToast.error(context.l10n.selectReason);
          return;
        }
        
        final result = await _baseApi.changeTableStatus(
          tableId: tableId,
          status: 5, // 5 = Unavailable (不可用)
          reasonId: reasonId,
        );

        if (result.isSuccess) {
          GlobalToast.success(context.l10n.tableClosingSuccessful);
          // 关桌成功后，清空选中状态，刷新大厅列表和桌台列表，停留在当前页面
          setState(() {
            selectedTableIds.clear();
          });
          // 刷新大厅列表数据
          await _initializeData();
        } else {
          GlobalToast.error(
            result.msg ?? Get.context!.l10n.tableClosingFailedPleaseRetry,
          );
        }
      } else if (widget.operationType == 'remove') {
        // 撤桌操作：调用unmergeTables API
        final tableId = selectedTableIds.first; // 撤桌只能单选
        
        // 检查是否选择了要移除的桌台
        if (selectedRemoveTableIds.isEmpty) {
          GlobalToast.error('请至少选择一个要移除的桌台');
          return;
        }
        
        final result = await _baseApi.unmergeTables(
          tableId: tableId,
          unmergeTableIds: selectedRemoveTableIds,
        );

        if (result.isSuccess) {
          GlobalToast.success(context.l10n.tableRemovalSuccessful);
          // 撤桌成功后，清空选中状态，刷新大厅列表和桌台列表，停留在当前页面
          setState(() {
            selectedTableIds.clear();
            selectedRemoveTableIds.clear();
          });
          // 刷新大厅列表数据
          await _initializeData();
        } else {
          GlobalToast.error(
            result.msg ?? Get.context!.l10n.tableRemovalFailedPleaseRetry,
          );
        }
      } else {
        // 并桌操作：调用mergeTables API
      // 转换桌台ID为整数列表
      final tableIds = selectedTableIds.map((id) => int.parse(id)).toList();

      final result = await _baseApi.mergeTables(
        tableIds: tableIds.map((id) => id.toString()).toList(),
      );

      if (result.isSuccess && result.data != null) {
        // 操作成功，直接使用返回的桌台详情
        await _handleMergeSuccess(result.data!);
      } else {
        // 操作失败，显示错误
          GlobalToast.error(
            result.msg ?? Get.context!.l10n.mergeFailedPleaseRetry,
          );
        }
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

  /// 处理操作成功后的逻辑
  Future<void> _handleMergeSuccess(TableListModel mergedTable) async {
    try {
      // 根据类型显示不同的成功提示
      if (widget.operationType == 'close') {
        GlobalToast.success(context.l10n.tableClosingSuccessful);
      } else if (widget.operationType == 'remove') {
        GlobalToast.success(context.l10n.tableRemovalSuccessful);
      } else {
        GlobalToast.success(context.l10n.mergeSuccessful);
      }

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
      'adult_count': mergedTable.currentAdult > 0
          ? mergedTable.currentAdult.toInt()
          : mergedTable.standardAdult.toInt(),
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

  /// 获取页面标题
  String _getPageTitle(BuildContext context) {
    switch (widget.operationType) {
      case 'close':
        return context.l10n.closeTable;
      case 'remove':
        return context.l10n.clearTable;
      case 'merge':
      default:
        return context.l10n.mergeTables;
    }
  }

  /// 获取确认按钮文本
  String _getConfirmButtonText(BuildContext context) {
    switch (widget.operationType) {
      case 'close':
        return context.l10n.closeTable;
      case 'remove':
        return context.l10n.clearTable;
      case 'merge':
      default:
        return context.l10n.confirm;
    }
  }

  /// 判断是否需要至少2个桌台
  bool _needAtLeastTwoTables() {
    // 并桌需要至少2个，关桌和撤桌只需要1个
    return widget.operationType == 'merge' || widget.operationType == null;
  }

  @override
  Widget build(BuildContext context) {
    final minTablesRequired = _needAtLeastTwoTables() ? 2 : 1;
    final canConfirm =
        selectedTableIds.length >= minTablesRequired && !_isMerging;

    return Stack(
      children: [
        // 主界面
        Scaffold(
      backgroundColor: GlobalColors.primaryBackground,
      appBar: AppBar(
        title: Text(_getPageTitle(context)),
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
              // 关桌状态下不显示右上角确认按钮
              if (widget.operationType != 'close')
          GestureDetector(
            onTap: canConfirm ? _confirmMerge : null,
            child: Container(
              margin: EdgeInsets.only(right: 15),
              padding: EdgeInsets.symmetric(horizontal: 12),
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: canConfirm ? Color(0xffFF9027) : Color(0xffCCCCCC),
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
                      _getConfirmButtonText(context),
                      style: TextStyle(
                        color: canConfirm ? Colors.white : Color(0xff999999),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: _buildMergeTablesPageBody(),
        ),
        // 灰色半透明背景层（只在关桌页面、选中桌台且抽屉显示时覆盖整个屏幕包括导航栏）
        if (widget.operationType == 'close' && selectedTableIds.isNotEmpty)
          Obx(() {
            if (!isReasonDrawerVisible.value) {
              return SizedBox.shrink();
            }
            return Positioned.fill(
              child: GestureDetector(
                onTap: _hideReasonDrawer,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            );
          }),
        // 底部关桌信息抽屉（浮在最上层，覆盖灰色背景，只在选中桌台后显示）
        if (widget.operationType == 'close' && selectedTableIds.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildCloseTableInfo(),
          ),
        // 底部撤桌信息模块（只在撤桌状态且选中桌台后显示）
        if (widget.operationType == 'remove' && selectedTableIds.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildRemoveTableInfo(),
          ),
        // 原因选择抽屉 - 提升到最外层Stack，确保在灰色背景之上（只在选中桌台且抽屉显示时显示）
        if (widget.operationType == 'close' && selectedTableIds.isNotEmpty)
          Obx(() {
            if (!isReasonDrawerVisible.value) {
              return SizedBox.shrink();
            }
            
            const itemHeight = 48.0;
            final drawerItemCount = closeReasonList.length.clamp(0, 5);
            final drawerHeight = drawerItemCount * itemHeight;
            const drawerBottomPosition = 160 - 30 - 10.0; // 底部容器高度 - 原因输入框高度 - 间距
            
            return Stack(
              children: [
                // 原因选择抽屉
                Positioned(
                  left: 70,
                  right: 16,
                  bottom: drawerBottomPosition,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      // 阻止事件冒泡到父容器，避免关闭抽屉
                    },
                    child: Material(
                      color: Colors.transparent,
                      elevation: 8,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: drawerHeight,
                        ),
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, -2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildReasonDrawerContent(),
                      ),
                    ),
                  ),
                ),
                // 箭头指向图片（紧贴抽屉下方，间距为0）
                Positioned(
                  right: 20,
                  bottom: drawerBottomPosition - 6, // 抽屉下方，紧贴抽屉（间距为0）
                  child: Image.asset(
                    'assets/reason_arrow.webp',
                    width: 155,
                    height: 6,
                    fit: BoxFit.fill,
                  ),
                ),
              ],
            );
          }),
      ],
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
                  ? SliverFillRemaining(child: buildEmptyState())
                  : SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 13,
                        childAspectRatio: 1.4, // 调整宽高比以避免越界
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final table = data[index];
                        final isSelected = selectedTableIds.contains(
                          table.tableId.toString(),
                        );
                        final status = _getStatus(table.businessStatus.toInt());
                        // 不可用、维修中、已预定的桌台不能被选择
                        final isUnselectable =
                            status == TableStatus.Unavailable ||
                            status == TableStatus.Maintenance ||
                            status == TableStatus.Reserved;

                        return GestureDetector(
                          onTap: isUnselectable
                              ? null
                              : () => _toggleTableSelection(
                                  table.tableId.toString(),
                                ),
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
                      }, childCount: data.length),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(context.l10n.loadAgain, style: TextStyle(fontSize: 14)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(context.l10n.loadAgain, style: TextStyle(fontSize: 14)),
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

      // 关桌模式也使用 Column 结构，但底部留出抽屉空间
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
                  final hallName =
                      halls[index].hallName ?? context.l10n.unknown;
                  return Row(
                    children: [
                      SizedBox(width: 12),
                      _tabButton(hallName, index, halls[index].tableCount ?? 0),
                    ],
                  );
                }),
              ),
            ),
          ),
          // 已选桌台信息显示区域（关桌和撤桌状态下不显示）
          if (selectedTableIds.isNotEmpty && widget.operationType != 'close' && widget.operationType != 'remove') 
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
          // 关桌模式下，选中桌台后底部留出空间给抽屉
          if (widget.operationType == 'close' && selectedTableIds.isNotEmpty)
            SizedBox(height: 160),
          // 撤桌模式下，选中桌台后底部留出空间给抽屉
          if (widget.operationType == 'remove' && selectedTableIds.isNotEmpty)
            SizedBox(height: 150), // 撤桌模块高度
          ],
        );
      });
    }

  /// 构建底部关桌信息模块
  Widget _buildCloseTableInfo() {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
      onTap: () {
          // 点击底部区域本身不关闭抽屉
        },
        child: Stack(
          clipBehavior: Clip.none, // 允许子元素溢出
          children: [
            Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF999999).withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -10),
            ),
          ],
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
          children: [
            Text(
                  '${context.l10n.table}：',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Color(0xFF000000),
              ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedTableIds.isNotEmpty 
                      ? (_getTableById(selectedTableIds.first)?.tableName ?? selectedTableIds.first)
                      : '',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF000000),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${context.l10n.reason}:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF000000),
                  ),
                ),
                SizedBox(width: 18),
                Expanded(
                  child: GestureDetector(
                        onTap: () {
                          _toggleReasonDrawer();
                        },
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: Color(0x33FF9027),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFFFF9027), width: 1),
                          ),
                          padding: EdgeInsets.only(left: 12, right: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Obx(() => Text(
                            selectedCloseReason.value?.label ?? context.l10n.selectReason,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFFF9027),
                                ),
                              )),
                              Image(
                                image: AssetImage('assets/order_login_arrowD.webp'),
                                width: 16,
                                height: 16,
                                color: Color(0xFFFF9027),
                              ),
                            ],
                          ),
                        ),
                      ),
                ),
              ],
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [ 
                GestureDetector(
                  onTap: () {
                    // 取消选中桌台
                    setState(() {
                      selectedTableIds.clear();
                    });
                  },
                  child: Container(
                    width: 160,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Color(0xFF999999), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      context.l10n.cancel,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _confirmMerge();
                  },
                  child: Container(
                    width: 160,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(0xFFFF9027),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      context.l10n.confirm,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建底部撤桌信息模块
  Widget _buildRemoveTableInfo() {
    final selectedTable = selectedTableIds.isNotEmpty ? _getTableById(selectedTableIds.first) : null;
    final mergedTables = selectedTable?.mergedTables ?? [];
    
    return Material(
                              color: Colors.transparent,
                              child: Container(
        width: double.infinity,
        height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
                                  boxShadow: [
                                    BoxShadow(
              color: Color(0xFF999999).withOpacity(0.1),
                                      blurRadius: 10,
              offset: Offset(0, -10),
                                    ),
                                  ],
                                ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题文字
            Text(
              '选择要移除的桌台',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Color(0xFF000000),
              ),
            ),
            SizedBox(height: 15),
            // 多选框区域
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 30,
                  runSpacing: 12,
                  children: mergedTables.map((tableInfo) {
                    final isSelected = selectedRemoveTableIds.contains(tableInfo.tableId);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedRemoveTableIds.remove(tableInfo.tableId);
                          } else {
                            selectedRemoveTableIds.add(tableInfo.tableId);
                          }
                        });
                      },
                      child:Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 多选框
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                               
                                borderRadius: BorderRadius.circular(2),
                                
                              ),
                              child: isSelected
                                  ? Image.asset('assets/reback_tabel_sel.webp', width: 16, height: 16)
                                  : Image.asset('assets/reback_tabel_unsel.webp', width: 16, height: 16),
                            ),
                            SizedBox(width: 6),
                            // 桌名
                            Text(
                              tableInfo.tableName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: isSelected ? Color(0xFFFF9027) : Color(0xFF000000),
                  ),
                ),
              ],
            ),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 20),
            // 取消和确认按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    // 取消选中桌台
                    setState(() {
                      selectedTableIds.clear();
                      selectedRemoveTableIds.clear();
                    });
                  },
                  child: Container(
                  width: 160,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Color(0xFF999999), width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                      context.l10n.cancel,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
                ),
                GestureDetector(
                  onTap: () {
                    _confirmMerge();
                  },
                  child: Container(
                  width: 160,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF9027),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                      context.l10n.confirm,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
            constraints: BoxConstraints(maxHeight: maxHeight),
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
    final textColor = Color(0xff333333);

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
            Icon(Icons.close, size: 16, color: textColor),
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
      bool currentTabHasError =
          hasNetworkError && data.isEmpty && !_preloadedTabs.contains(tabIndex);

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
