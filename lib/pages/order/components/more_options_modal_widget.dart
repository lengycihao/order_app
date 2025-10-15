import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/utils/l10n_utils.dart';
import 'package:order_app/utils/modal_utils.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:order_app/utils/screen_adaptation.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/menu_fixed_cost.dart';
import 'package:lib_domain/api/base_api.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lib_base/logging/logging.dart';
import 'package:lib_base/utils/websocket_manager.dart';

/// 更多功能弹窗组件
class MoreOptionsModalWidget {
  /// 显示更多功能弹窗
  static void showMoreModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.4, // 使用屏幕高度的40%
          ),
          child: _MoreOptionsModalContent(),
        ),
      ),
    );
  }
}

/// 更多功能弹窗内容
class _MoreOptionsModalContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModalContainerWithMargin(
      title: context.l10n.more,
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MoreOptionItem(
                    title: context.l10n.changeTable,
                    onTap: () {
                      Navigator.of(context).pop(); // 关闭更多选项弹窗
                      // 延迟显示更换桌台弹窗，确保导航栈稳定
                      Future.delayed(Duration(milliseconds: 100), () {
                        _showChangeTableModal(context);
                      });
                    },
                  ),
                  SizedBox(height: 30),
                  _MoreOptionItem(
                    title: context.l10n.changeMenu,
                    onTap: () {
                      Navigator.of(context).pop(); // 关闭更多选项弹窗
                      // 延迟显示更换菜单弹窗，确保导航栈稳定
                      Future.delayed(Duration(milliseconds: 100), () {
                        _showChangeMenuModal(context);
                      });
                    },
                  ),
                  SizedBox(height: 30),
                  _MoreOptionItem(
                    title: context.l10n.increaseNumberOfPeople,
                    onTap: () {
                      Navigator.of(context).pop(); // 关闭更多选项弹窗
                      // 延迟显示更换人数弹窗，确保导航栈稳定
                      Future.delayed(Duration(milliseconds: 100), () {
                        _showChangePeopleModal(context);
                      });
                    },
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示更换桌子弹窗
  void _showChangeTableModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: _ChangeTableModalContent(),
        ),
      ),
    );
  }

  /// 显示更换菜单弹窗
  void _showChangeMenuModal(BuildContext context) {
    // 获取当前菜单信息
    final controller = Get.find<OrderController>();
    final currentMenu = controller.menu.value;
    final currentMenuId = controller.menuId.value;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: _ChangeMenuModalContent(
            currentMenu: currentMenu,
            currentMenuId: currentMenuId,
          ),
        ),
      ),
    );
  }

  /// 显示更换人数弹窗
  void _showChangePeopleModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: _ChangePeopleModalContent(),
        ),
      ),
    );
  }
}

/// 更多选项项
class _MoreOptionItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _MoreOptionItem({Key? key, required this.title, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 44,
        padding: EdgeInsets.symmetric( horizontal: 12),
        margin: EdgeInsets.symmetric(horizontal: 25),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontSize: 20,
              color: Color(0xff666666),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// 更换桌子弹窗内容
class _ChangeTableModalContent extends StatefulWidget {
  @override
  State<_ChangeTableModalContent> createState() =>
      _ChangeTableModalContentState();
}

class _ChangeTableModalContentState extends State<_ChangeTableModalContent> {
  List<TableListModel> _availableTables = [];
  int? _selectedTableId;
  bool _isLoading = true;
  bool _isProcessing = false; // 添加处理状态防止重复点击
  final _api = BaseApi();

  @override
  void initState() {
    super.initState();
    _loadAvailableTables();
  }

  /// 加载可用桌台列表
  Future<void> _loadAvailableTables() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await _api.getTableList(hallId: "0", queryType: "2");

      if (result.isSuccess && result.data != null) {
        setState(() {
          _availableTables = result.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        GlobalToast.error(Get.context!.l10n.getTableFailed);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      GlobalToast.error('${Get.context!.l10n.getTableFailed}: $e');
    }
  }

  /// 执行换桌操作
  Future<void> _performChangeTable() async {
    // 防止重复点击
    if (_isProcessing) {
      return;
    }

    if (_selectedTableId == null) {
      GlobalToast.error(Get.context!.l10n.pleaseSelectTable);
      return;
    }

    final controller = Get.find<OrderController>();
    final currentTableId = controller.table.value?.tableId.toInt();

    if (currentTableId == null) {
      GlobalToast.error(Get.context!.l10n.pleaseExitAndInAdain);
      return;
    }

    // 设置处理状态
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _api.changeTable(
        tableId: currentTableId,
        newTableId: _selectedTableId!,
      );

      // 无论成功失败都先关闭弹窗
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result.isSuccess) {
        // 更新controller中的桌台信息
        final newTable = _availableTables.firstWhere(
          (table) => table.tableId.toInt() == _selectedTableId,
        );
        controller.table.value = newTable;

        // 发送WebSocket消息通知其他客户端
        final websocketManager = WebSocketManager();
        await websocketManager.sendChangeTable(
          tableId: currentTableId.toString(),
          newTableId: _selectedTableId!,
          newTableName: newTable.tableName ?? '',
        );

        GlobalToast.success(Get.context!.l10n.success);
      } else {
        GlobalToast.error(result.msg ?? Get.context!.l10n.failed);
      }
    } catch (e) {
      // 异常情况下也要关闭弹窗
      if (mounted) {
        Navigator.of(context).pop();
      }
      GlobalToast.error('${Get.context!.l10n.failed}: $e');
    } finally {
      // 重置处理状态
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalContainerWithMargin(
      title: context.l10n.changeTable,
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 桌子列表 - 自适应高度，最小220px，最大500px
          Container(
            constraints: BoxConstraints(
              minHeight: 220,
              maxHeight: ScreenAdaptation.adaptHeight(context, 500),
            ),
            padding: EdgeInsets.all(12).copyWith(bottom: 0),
            child: _isLoading
                ? Center(
                    child: RestaurantLoadingWidget(size: 30),
                  )
                : _availableTables.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.table_restaurant_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          context.l10n.noCanUseTable,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 10,
                      childAspectRatio: 150 / 124,
                    ),
                    itemCount: _availableTables.length,
                    itemBuilder: (context, index) {
                      final table = _availableTables[index];
                      final tableName =
                          '${table.hallName ?? ''}-${table.tableName ?? ''}';
                      final isSelected =
                          _selectedTableId == table.tableId.toInt();

                      return _TableItem(
                        businessStatusName: table.businessStatusName ?? '',
                        tableName: tableName,
                        adultCount: table.standardAdult.toInt(),
                        childCount: table.standardChild.toInt(),
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedTableId = table.tableId.toInt();
                          });
                        },
                      );
                    },
                  ),
          ),
          // 确认按钮
          Container(
            padding: EdgeInsets.all(10),
             decoration: BoxDecoration(
              color: Color(0xffffffff),
              boxShadow: [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 3,
                  offset: Offset(0, -2),
                ),
              ],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: GestureDetector(
                onTap: _performChangeTable,
                child: Container(
                  width: 120,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      context.l10n.confirm,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 桌子项
class _TableItem extends StatelessWidget {
  final String tableName;
  final int adultCount;
  final int childCount;
  final String businessStatusName;
  final bool isSelected;
  final VoidCallback onTap;

  const _TableItem({
    Key? key,
    required this.tableName,
    this.adultCount = 0,
    this.childCount = 0,
    required this.isSelected,
    required this.onTap, required this.businessStatusName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Color(0x33000000) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
          
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                //  mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      tableName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 10,
                            color: Colors.black,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '$adultCount',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.child_care,
                            size: 10,
                            color: Colors.black,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '$childCount',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: Container(
                height: 21,
                padding: EdgeInsets.only(left: 6, right: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Color(0x66000000) : Color(0xffE4E4E4),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  businessStatusName,
                  style: TextStyle(fontSize: 12, color: Colors.black),
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                right: 0,

                bottom: 0,
                child: Image(
                  image: AssetImage("assets/order_table_bz_sel.webp"),
                  width: 30,
                  height: 30,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 更换菜单弹窗内容
class _ChangeMenuModalContent extends StatefulWidget {
  final TableMenuListModel? currentMenu;
  final int currentMenuId;
  
  const _ChangeMenuModalContent({
    Key? key,
    this.currentMenu,
    required this.currentMenuId,
  }) : super(key: key);

  @override
  State<_ChangeMenuModalContent> createState() =>
      _ChangeMenuModalContentState();
}

class _ChangeMenuModalContentState extends State<_ChangeMenuModalContent> {
  List<TableMenuListModel> _menuList = [];
  int? _selectedMenuId;
  bool _isLoading = true;
  bool _isProcessing = false; // 添加处理状态防止重复点击
  final _api = BaseApi();

  @override
  void initState() {
    super.initState();
    _loadMenuList();
  }

  /// 加载菜单列表
  Future<void> _loadMenuList() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await _api.getTableMenuList();

      if (result.isSuccess && result.data != null) {
        setState(() {
          _menuList = result.data!;
          _isLoading = false;

          // 设置默认选中当前使用的菜单
          _setDefaultSelectedMenu();
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        GlobalToast.error('获取菜单列表失败');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      GlobalToast.error('获取菜单列表异常：$e');
    }
  }

  /// 设置默认选中当前使用的菜单
  void _setDefaultSelectedMenu() {
    try {
      // 优先使用 currentMenuId 进行匹配
      if (widget.currentMenuId > 0) {
        // 在菜单列表中查找当前菜单
        final currentMenuIndex = _menuList.indexWhere(
          (menu) => menu.menuId == widget.currentMenuId,
        );

        if (currentMenuIndex != -1) {
          setState(() {
            _selectedMenuId = widget.currentMenuId;
          });
          final selectedMenu = _menuList[currentMenuIndex];
          logDebug(
            '默认选中当前菜单: ${selectedMenu.menuName} (ID: ${widget.currentMenuId})',
            tag: 'MoreOptionsModalWidget',
          );
        } else {
          logWarning(
            '当前菜单在列表中未找到: ID=${widget.currentMenuId}',
            tag: 'MoreOptionsModalWidget',
          );
        }
      } else if (widget.currentMenu != null && widget.currentMenu!.menuId != null) {
        // 备用方案：使用 currentMenu 对象进行匹配
        final currentMenuIndex = _menuList.indexWhere(
          (menu) => menu.menuId == widget.currentMenu!.menuId,
        );

        if (currentMenuIndex != -1) {
          setState(() {
            _selectedMenuId = widget.currentMenu!.menuId!;
          });
          logDebug(
            '默认选中当前菜单: ${widget.currentMenu!.menuName} (ID: ${widget.currentMenu!.menuId})',
            tag: 'MoreOptionsModalWidget',
          );
        } else {
          logWarning(
            '当前菜单在列表中未找到: ${widget.currentMenu!.menuName} (ID: ${widget.currentMenu!.menuId})',
            tag: 'MoreOptionsModalWidget',
          );
        }
      } else {
        logWarning('当前菜单信息为空', tag: 'MoreOptionsModalWidget');
      }
    } catch (e) {
      logError('设置默认选中菜单时出错: $e', tag: 'MoreOptionsModalWidget');
    }
  }

  /// 构建菜单网格
  Widget _buildMenuGrid() {

    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _menuList.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 150 / 156,
      ),
      itemBuilder: (context, index) {
        final menu = _menuList[index];
        final isSelected = _selectedMenuId == menu.menuId;

        return _MenuItem(
          imageUrl: menu.menuImage ?? '',
          menuName: menu.menuName ?? '',
          adultPrice: int.tryParse(menu.adultPackagePrice ?? '0') ?? 0,
          childPrice: int.tryParse(menu.childPackagePrice ?? '0') ?? 0,
          menuFixedCosts: menu.menuFixedCosts,
          menuType: menu.menuType,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _selectedMenuId = menu.menuId;
            });
          },
        );
      },
    );
  }

  /// 执行更换菜单操作
  Future<void> _performChangeMenu() async {
    // 防止重复点击
    if (_isProcessing) {
      return;
    }

    if (_selectedMenuId == null) {
      if (mounted) {
        GlobalToast.error('请选择需要更换的菜单');
      }
      return;
    }

    final controller = Get.find<OrderController>();
    final currentTableId = controller.table.value?.tableId.toInt();

    if (currentTableId == null) {
      if (mounted) {
        GlobalToast.error('当前桌台信息错误');
      }
      return;
    }

    // 设置处理状态
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _api.changeMenu(
        tableId: currentTableId,
        menuId: _selectedMenuId!,
      );

      // 无论成功失败都先关闭弹窗
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result.isSuccess) {
        // 更新controller中的菜单信息
        final newMenu = _menuList.firstWhere(
          (menu) => menu.menuId == _selectedMenuId,
        );
        controller.menu.value = newMenu;
        // 同步更新menuId，确保菜品数据能正确加载
        controller.menuId.value = newMenu.menuId ?? 0;

        // 发送WebSocket消息通知其他客户端
        final websocketManager = WebSocketManager();
        await websocketManager.sendChangeMenu(
          tableId: currentTableId.toString(),
          menuId: _selectedMenuId!,
        );

        // 刷新点餐页面数据
        await controller.refreshOrderData();

        if (mounted) {
          GlobalToast.success('更换成功');
        }
      } else {
        if (mounted) {
          GlobalToast.error(result.msg ?? '更换失败');
        }
      }
    } catch (e) {
      // 异常情况下也要关闭弹窗
      if (mounted) {
        Navigator.of(context).pop();
        GlobalToast.error('操作异常：$e');
      }
    } finally {
      // 重置处理状态
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 343,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题行 - 更换菜单左对齐，右边关闭按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.selectMenu,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1,
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 24,
                    height: 24,
                    // decoration: BoxDecoration(
                    //   color: Colors.grey.shade200,
                    //   shape: BoxShape.circle,
                    // ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xff666666),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10), // 更换菜单距离上面10
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 10), // 分割线与更换菜单间距10
            // 菜单列表
            _isLoading
                ? Center(
                    child: RestaurantLoadingWidget(size: 30),
                  )
                : _menuList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          context.l10n.noCanUseMenu,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildMenuGrid(),
            SizedBox(height: 24),
            // 确认按钮
            SizedBox(
              width: 120,
              height: 32,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF9027),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                onPressed: _performChangeMenu,
                child: Text(
                  context.l10n.confirm,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 菜单项
class _MenuItem extends StatelessWidget {
  final String menuName;
  final String imageUrl;
  final int adultPrice;
  final int childPrice;
  final List<MenuFixedCost>? menuFixedCosts;
  final int? menuType;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuItem({
    Key? key,
    required this.menuName,
    required this.adultPrice,
    required this.imageUrl,
    required this.childPrice,
    this.menuFixedCosts,
    this.menuType,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  /// 构建价格信息
  Widget _buildPriceInfo() {
    // 检查是否有menu_fixed_costs字段
    if (menuFixedCosts != null && menuFixedCosts!.isNotEmpty) {
      // 构建固定费用信息列表
      List<Widget> costWidgets = [];
      
      for (var cost in menuFixedCosts!) {
        if (cost.name != null && cost.amount != null && cost.unit != null) {
          costWidgets.add(
            Text(
              '${cost.name}: ${cost.amount}/${cost.unit}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff666666),
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // 允许换行
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
      }

      if (costWidgets.isNotEmpty) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: costWidgets,
        );
      }
    }

    // 如果没有固定费用信息，显示默认的成人和儿童价格
    return Text(
      '成人：$adultPrice/位\n儿童：$childPrice/位',
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xff666666),
      ),
      textAlign: TextAlign.center,
      maxLines: 2, // 允许换行
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 15),
            width: 150, // 固定宽度124，与选择菜单页面保持一致
            height: 156, // 固定高度150，与选择菜单页面保持一致
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.transparent,
                width: isSelected ? 1 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 菜单图片 - 108*88 适配容器宽度
                Container(
                  width: 141, // 调整为容器内容区域宽度
                  height: 88,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 141,
                      height: 88,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Image.asset(
                        'assets/order_table_menu.webp',
                        width: 141,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/order_table_menu.webp',
                        width: 141,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                // 根据菜单类型决定是否显示价格信息
                if (menuType != 2) ...[
                  const SizedBox(height: 4),
                  // 价格信息 - 文字可换行
                  _buildPriceInfo(),
                ],
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 2,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: (MediaQuery.of(context).size.width - 90) / 2,
                minWidth: 60, // 最小宽度
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange : Colors.grey.shade400,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.elliptical(35, 30), // 左上角椭圆半径
                  bottomRight: Radius.elliptical(35, 35), // 右下角椭圆半径
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final text = menuName;
                  final maxWidth = constraints.maxWidth;
                  
                  // 计算合适的字体大小
                  double fontSize = 14;
                  int maxLines = 1;
                  
                  // 测量文本宽度
                  final textPainter = TextPainter(
                    text: TextSpan(
                      text: text,
                      style: TextStyle(fontSize: fontSize, color: Colors.white),
                    ),
                    maxLines: maxLines,
                    textDirection: TextDirection.ltr,
                  );
                  textPainter.layout(maxWidth: maxWidth);
                  
                  // 如果文本超出宽度，尝试减小字体或增加行数
                  if (textPainter.didExceedMaxLines || textPainter.width > maxWidth) {
                    // 先尝试减小字体
                    fontSize = 12;
                    textPainter.text = TextSpan(
                      text: text,
                      style: TextStyle(fontSize: fontSize, color: Colors.white),
                    );
                    textPainter.layout(maxWidth: maxWidth);
                    
                    // 如果还是超出，再减小字体并允许换行
                    if (textPainter.didExceedMaxLines || textPainter.width > maxWidth) {
                      fontSize = 10;
                      maxLines = 2;
                    }
                  }
                  
                  return Text(
                    text,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: Colors.white,
                      height: 1.2, // 行高
                    ),
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 更换人数弹窗内容
class _ChangePeopleModalContent extends StatefulWidget {
  @override
  State<_ChangePeopleModalContent> createState() =>
      _ChangePeopleModalContentState();
}

class _ChangePeopleModalContentState extends State<_ChangePeopleModalContent> {
  late int adultCount;
  late int childCount;
  bool _isProcessing = false; // 添加处理状态防止重复点击
  final _api = BaseApi();

  @override
  void initState() {
    super.initState();
    // 默认值设为0
    adultCount = 0;
    childCount = 0;
  }

  /// 执行更换人数操作
  Future<void> _performChangePeopleCount() async {
    // 防止重复点击
    if (_isProcessing) {
      return;
    }

    final controller = Get.find<OrderController>();
    final currentTableId = controller.table.value?.tableId.toInt();

    if (currentTableId == null) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭弹窗
      }
      GlobalToast.error(Get.context!.l10n.pleaseExitAndInAdain);
      return;
    }

    // 检查是否有人数变化，只有当任何一个大于0的时候才发WS消息
    if (adultCount <= 0 && childCount <= 0) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭弹窗
      }
      GlobalToast.error(Get.context!.l10n.pleaseSelectAtLeastOnePerson);
      return;
    }

    // 设置处理状态
    setState(() {
      _isProcessing = true;
    });

    // 先关闭弹窗
    if (mounted) {
      Navigator.of(context).pop();
    }

    try {
      // 直接传递增量给接口和WebSocket
      await _updateTableDetailAndRefresh(currentTableId, adultCount, childCount);
    } catch (e) {
      GlobalToast.error('${Get.context!.l10n.networkErrorPleaseTryAgain}: $e');
    } finally {
      // 重置处理状态
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// 更新桌台详情并刷新数据
  Future<void> _updateTableDetailAndRefresh(int tableId, int adultCountIncrement, int childCountIncrement) async {
    try {
      // 先调用changePeopleCount接口更新服务器数据（传递增量）
      final changeResult = await _api.changePeopleCount(
        tableId: tableId,
        adultCount: adultCountIncrement,
        childCount: childCountIncrement,
      );
      
      if (!changeResult.isSuccess) {
        GlobalToast.error('${Get.context!.l10n.failed}: ${changeResult.msg}');
        return;
      }
      
      // 调用桌台详情API获取最新数据
      final result = await _api.getTableDetail(tableId: tableId);
      
      if (result.isSuccess && result.data != null) {
        final controller = Get.find<OrderController>();
        final latestTable = result.data!;
        
        // 更新桌台信息
        controller.table.value = latestTable;
        
        // 更新人数信息（直接使用服务器返回的最新数据）
        controller.adultCount.value = latestTable.currentAdult.toInt();
        controller.childCount.value = latestTable.currentChild.toInt();

        // 发送WebSocket消息通知其他客户端（传递增量）
        await wsManager.sendChangePeopleCount(
          tableId: tableId.toString(),
          adultCount: adultCountIncrement,
          childCount: childCountIncrement,
        );

        // 刷新点餐页面数据
        await controller.refreshOrderData();

        GlobalToast.success(Get.context!.l10n.success);
      } else {
        GlobalToast.error('${Get.context!.l10n.failed}: ${result.msg}');
      }
    } catch (e) {
      GlobalToast.error('${Get.context!.l10n.networkErrorPleaseTryAgain}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalContainerWithMargin(
      title: context.l10n.increaseNumberOfPeople,
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 人数选择
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 27,
                  ),
                  _PeopleCountSelector(
                    label: context.l10n.adults,
                    count: adultCount,
                    onIncrement: () {
                      setState(() {
                        adultCount++;
                      });
                    },
                    onDecrement: () {
                      if (adultCount > 0) {
                        setState(() {
                          adultCount--;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  _PeopleCountSelector(
                    label: context.l10n.children,
                    count: childCount,
                    onIncrement: () {
                      setState(() {
                        childCount++;
                      });
                    },
                    onDecrement: () {
                      if (childCount > 0) {
                        setState(() {
                          childCount--;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          // 确认按钮
          Container(
            padding: EdgeInsets.all(16),
            child: Center(
              child: GestureDetector(
                onTap: _performChangePeopleCount,
                child: Container(
                  width: 180,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      context.l10n.confirm,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 人数选择器
class _PeopleCountSelector extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _PeopleCountSelector({
    Key? key,
    required this.label,
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        _buildStepperWidget(),
      ],
    );
  }

  /// 构建步进器组件
  Widget _buildStepperWidget() {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 减少按钮
          GestureDetector(
            onTap: onDecrement,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: Center(
                child: Text(
                  '一',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff666666),
                  ),
                ),
              ),
            ),
          ),
          // 分割线
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          // 数字显示区域
          Container(
            width: 32,
            height: 24,
            color: Colors.white,
            child: Center(
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
          // 分割线
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          // 增加按钮 
          GestureDetector(
            onTap: onIncrement,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Center(
                child: Text(
                  '+',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff666666),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
