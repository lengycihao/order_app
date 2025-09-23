import 'package:flutter/material.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:lib_domain/entrity/home/lobby_list_model/lobby_list_model.dart';
import 'package:order_app/utils/snackbar_utils.dart';
import '../../../constants/global_colors.dart';
import 'package:lib_domain/api/base_api.dart';
import 'package:order_app/pages/table/sub_page/select_menu_page.dart';
import 'package:order_app/pages/order/order_main_page.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/table/card/table_card.dart';

class MergeTablesPage extends StatefulWidget {
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

class _MergeTablesPageState extends State<MergeTablesPage> with TickerProviderStateMixin {
  final List<String> selectedTableIds = [];
  final BaseApi _baseApi = BaseApi();
  bool _isMerging = false;
  
  // Tab相关
  late TabController _tabController;
  var lobbyListModel = LobbyListModel(halls: []).obs;
  var tabDataList = <RxList<TableListModel>>[].obs;
  var selectedTab = 0.obs;
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  @override
  void initState() {
    super.initState();
    // 如果传入了已合并的桌台，自动选中
    if (widget.mergedTable != null) {
      selectedTableIds.add(widget.mergedTable!.tableId.toString());
    }
    
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
    });
    
    // 获取第一个tab的数据
    _fetchDataForTab(0);
  }
  
  /// 获取指定tab的数据
  Future<void> _fetchDataForTab(int index) async {
    if (index >= tabDataList.length) return;
    
    isLoading.value = true;
    hasError.value = false;
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
        hasError.value = false;
      } else {
        hasError.value = true;
        errorMessage.value = result.msg ?? '数据加载失败';
        tabDataList[index].value = [];
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = '网络连接异常，请检查网络后重试';
      tabDataList[index].value = [];
    }
    
    isLoading.value = false;
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      SnackbarUtils.showWarning(context, '请至少选择2个桌台进行合并');
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
      SnackbarUtils.showTemporary(context, '正在合并桌台...', color: Colors.blue);

      // 转换桌台ID为整数列表
      final tableIds = selectedTableIds.map((id) => int.parse(id)).toList();

      // 调用并桌API
      final result = await _baseApi.mergeTables(tableIds: tableIds);

      if (result.isSuccess && result.data != null) {
        // 并桌成功，直接使用返回的桌台详情
        await _handleMergeSuccess(result.data!);
      } else {
        // 并桌失败，取消之前的提示并显示错误
        SnackbarUtils.dismissCurrentSafely(context);
        SnackbarUtils.showError(context, result.msg ?? '并桌失败');
      }
    } catch (e) {
      // 网络错误，取消之前的提示并显示错误
      SnackbarUtils.dismissCurrentSafely(context);
      SnackbarUtils.showError(context, '并桌操作失败: $e');
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
      // 取消之前的加载提示，显示成功提示
      SnackbarUtils.dismissCurrentSafely(context);
      SnackbarUtils.showSuccess(context, '桌台合并成功');

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
      // 跳转异常，取消之前的提示并显示错误
      SnackbarUtils.dismissCurrentSafely(context);
      SnackbarUtils.showError(context, '跳转失败: $e');
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
      SnackbarUtils.showError(context, '无法获取菜单信息');
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
      body: Obx(() {
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
                  return _buildRefreshableGrid(
                    tabDataList[index],
                    index,
                  );
                }),
              ),
            ),
          ],
        );
      }),
    );
  }
  
  /// Tab 按钮 - 与桌台页面相同的样式
  Widget _tabButton(String title, int index, int tableCount) {
    return Obx(() {
      bool selected = selectedTab.value == index;
      return GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          _fetchDataForTab(index);
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
      return RefreshIndicator(
        onRefresh: () async {
          await _fetchDataForTab(tabIndex);
        },
        child: CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: data.isEmpty
                  ? SliverFillRemaining(
                      child: isLoading.value
                          ? Center(child: CircularProgressIndicator())
                          : (hasError.value ? _buildNetworkErrorState() : _buildEmptyState()),
                    )
                  : SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 13,
                        childAspectRatio: 1.2,
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
          SizedBox(height: 8),
          Text(
            '暂无桌台',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFFF9027),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建网络错误状态
  Widget _buildNetworkErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/order_nonet.webp',
            width: 180,
            height: 100,
          ),
          SizedBox(height: 8),
          Text(
            '暂无网络',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFFF9027),
            ),
          ),
        ],
      ),
    );
  }
}
