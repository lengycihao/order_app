import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/pages/order/components/modal_utils.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';
import 'package:order_app/pages/order/components/error_notification_manager.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/menu_fixed_cost.dart';
import 'package:lib_domain/api/base_api.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
      title: '更多',
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
                    title: '更换桌子',
                    onTap: () {
                      Get.back();
                      _showChangeTableModal(context);
                    },
                  ),
                  SizedBox(height: 30),
                  _MoreOptionItem(
                    title: '更换菜单',
                    onTap: () {
                      Get.back();
                      _showChangeMenuModal(context);
                    },
                  ),
                  SizedBox(height: 30),
                  _MoreOptionItem(
                    title: '更换人数',
                    onTap: () {
                      Get.back();
                      _showChangePeopleModal(context);
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
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: _ChangeTableModalContent(),
        ),
      ),
    );
  }

  /// 显示更换菜单弹窗
  void _showChangeMenuModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: _ChangeMenuModalContent(),
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
        // padding: EdgeInsets.symmetric( horizontal: 20),
        margin: EdgeInsets.symmetric(horizontal: 25),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            color: Color(0xff666666),
            fontWeight: FontWeight.w500,
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
        ErrorNotificationManager().showErrorNotification(
          title: '错误', 
          message: '获取桌台列表失败',
          errorCode: 'get_table_list_failed',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ErrorNotificationManager().showErrorNotification(
        title: '错误', 
        message: '获取桌台列表异常：$e',
        errorCode: 'get_table_list_exception',
      );
    }
  }

  /// 执行换桌操作
  Future<void> _performChangeTable() async {
    if (_selectedTableId == null) {
      ErrorNotificationManager().showWarningNotification(
        title: '提示', 
        message: '请选择需要更换的桌台',
        warningCode: 'no_table_selected',
      );
      return;
    }

    final controller = Get.find<OrderController>();
    final currentTableId = controller.table.value?.tableId.toInt();

    if (currentTableId == null) {
      ErrorNotificationManager().showErrorNotification(
        title: '错误', 
        message: '当前桌台信息错误',
        errorCode: 'invalid_table_info',
      );
      return;
    }

    try {
      final result = await _api.changeTable(
        tableId: currentTableId,
        newTableId: _selectedTableId!,
      );

      // 无论成功失败都先关闭弹窗
      Get.back();

      if (result.isSuccess) {
        // 更新controller中的桌台信息
        final newTable = _availableTables.firstWhere(
          (table) => table.tableId.toInt() == _selectedTableId,
        );
        controller.table.value = newTable;

        ErrorNotificationManager().showSuccessNotification(
          title: '成功', 
          message: '已成功更换桌台',
          successCode: 'change_table_success',
        );
      } else {
        ErrorNotificationManager().showErrorNotification(
          title: '失败', 
          message: result.msg ?? '换桌失败',
          errorCode: 'change_table_failed',
        );
      }
    } catch (e) {
      // 异常情况下也要关闭弹窗
      Get.back();
      ErrorNotificationManager().showErrorNotification(
        title: '错误', 
        message: '换桌操作异常：$e',
        errorCode: 'change_table_exception',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalContainerWithMargin(
      title: '更换桌子',
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 桌子列表
          Flexible(
            child: Container(
              padding: EdgeInsets.all(16),
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
                            '暂无可用桌台',
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
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 124 / 150,
                      ),
                      itemCount: _availableTables.length,
                      itemBuilder: (context, index) {
                        final table = _availableTables[index];
                        final tableName =
                            '${table.hallName ?? ''}-${table.tableName ?? ''}';
                        final isSelected =
                            _selectedTableId == table.tableId.toInt();

                        return _TableItem(
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
          ),
          // 确认按钮
          Container(
            padding: EdgeInsets.all(16),
            child: GestureDetector(
              onTap: _performChangeTable,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '确认',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
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
  final bool isSelected;
  final VoidCallback onTap;

  const _TableItem({
    Key? key,
    required this.tableName,
    this.adultCount = 0,
    this.childCount = 0,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Color(0x33000000) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
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
                        fontWeight: FontWeight.bold,
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
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '$adultCount',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.child_care,
                            size: 10,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '$childCount',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
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
                  '空闲中',
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
  @override
  State<_ChangeMenuModalContent> createState() =>
      _ChangeMenuModalContentState();
}

class _ChangeMenuModalContentState extends State<_ChangeMenuModalContent> {
  List<TableMenuListModel> _menuList = [];
  int? _selectedMenuId;
  bool _isLoading = true;
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
        ErrorNotificationManager().showErrorNotification(
          title: '错误', 
          message: '获取菜单列表失败',
          errorCode: 'get_menu_list_failed',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ErrorNotificationManager().showErrorNotification(
        title: '错误', 
        message: '获取菜单列表异常：$e',
        errorCode: 'get_menu_list_exception',
      );
    }
  }

  /// 设置默认选中当前使用的菜单
  void _setDefaultSelectedMenu() {
    try {
      final controller = Get.find<OrderController>();
      final currentMenu = controller.menu.value;

      if (currentMenu != null && currentMenu.menuId != null) {
        // 在菜单列表中查找当前菜单
        final currentMenuIndex = _menuList.indexWhere(
          (menu) => menu.menuId == currentMenu.menuId,
        );

        if (currentMenuIndex != -1) {
          _selectedMenuId = currentMenu.menuId;
          print(
            '✅ 默认选中当前菜单: ${currentMenu.menuName} (ID: ${currentMenu.menuId})',
          );
        } else {
          print(
            '⚠️ 当前菜单在列表中未找到: ${currentMenu.menuName} (ID: ${currentMenu.menuId})',
          );
        }
      } else {
        print('⚠️ 当前菜单信息为空');
      }
    } catch (e) {
      print('❌ 设置默认选中菜单时出错: $e');
    }
  }

  /// 执行更换菜单操作
  Future<void> _performChangeMenu() async {
    if (_selectedMenuId == null) {
      ErrorNotificationManager().showWarningNotification(
        title: '提示', 
        message: '请选择需要更换的菜单',
        warningCode: 'no_menu_selected',
      );
      return;
    }

    final controller = Get.find<OrderController>();
    final currentTableId = controller.table.value?.tableId.toInt();

    if (currentTableId == null) {
      ErrorNotificationManager().showErrorNotification(
        title: '错误', 
        message: '当前桌台信息错误',
        errorCode: 'invalid_table_info',
      );
      return;
    }

    try {
      final result = await _api.changeMenu(
        tableId: currentTableId,
        menuId: _selectedMenuId!,
      );

      // 无论成功失败都先关闭弹窗
      Get.back();

      if (result.isSuccess) {
        // 更新controller中的菜单信息
        final newMenu = _menuList.firstWhere(
          (menu) => menu.menuId == _selectedMenuId,
        );
        controller.menu.value = newMenu;

        // 刷新点餐页面数据
        await controller.refreshOrderData();

        ErrorNotificationManager().showSuccessNotification(
          title: '成功', 
          message: '已成功更换菜单',
          successCode: 'change_menu_success',
        );
      } else {
        ErrorNotificationManager().showErrorNotification(
          title: '失败', 
          message: result.msg ?? '更换菜单失败',
          errorCode: 'change_menu_failed',
        );
      }
    } catch (e) {
      // 异常情况下也要关闭弹窗
      Get.back();
      ErrorNotificationManager().showErrorNotification(
        title: '错误', 
        message: '更换菜单操作异常：$e',
        errorCode: 'change_menu_exception',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalContainerWithMargin(
      title: '更换菜单',
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 菜单列表
          Flexible(
            child: Container(
              padding: EdgeInsets.all(16),
              child: _isLoading
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
                            '暂无可用菜单',
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
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 150 / 170,
                      ),
                      itemCount: _menuList.length,
                      itemBuilder: (context, index) {
                        final menu = _menuList[index];
                        final isSelected = _selectedMenuId == menu.menuId;

                        return _MenuItem(
                          imageUrl: menu.menuImage ?? '',
                          menuName: menu.menuName ?? '未知菜单',
                          adultPrice:
                              int.tryParse(menu.adultPackagePrice ?? '0') ?? 0,
                          childPrice:
                              int.tryParse(menu.childPackagePrice ?? '0') ?? 0,
                          menuFixedCosts: menu.menuFixedCosts,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedMenuId = menu.menuId;
                            });
                          },
                        );
                      },
                    ),
            ),
          ),
          // 确认按钮
          Container(
            padding: EdgeInsets.all(16),
            child: GestureDetector(
              onTap: _performChangeMenu,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '确认',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
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

/// 菜单项
class _MenuItem extends StatelessWidget {
  final String menuName;
  final String imageUrl; // 这里可以添加图片URL字段
  final int adultPrice;
  final int childPrice;
  final List<MenuFixedCost>? menuFixedCosts;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuItem({
    Key? key,
    required this.menuName,
    required this.adultPrice,
    required this.imageUrl,
    required this.childPrice,
    this.menuFixedCosts,
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '成人: ¥$adultPrice',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '儿童: ¥$childPrice',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(margin: EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    // 图片区域 - 占用大部分空间，但允许文本自适应
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade100,
                              child: Icon(
                                Icons.restaurant_menu,
                                size: 32,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 价格信息 - 自适应内容
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: _buildPriceInfo(),
                    ),
                  ],
                ),
                // 菜单名称标签
                
              ],
            ),
          ),
          Positioned(
              top: 0,
              left: 0,
              child: Container(
                
                padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange : Color(0xffE4E4E4),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.elliptical(35, 30), // 左上角椭圆半径
                    bottomRight: Radius.elliptical(35, 30), // 右下角椭圆半径
                  ),
                ),
                alignment: Alignment.center,
                child: Center(
                  child: Text(
                    menuName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Color(0xff666666),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
  late int maxAdultCount;
  late int maxChildCount;
  final _api = BaseApi();

  // 用于跟踪是否已经显示过提示
  bool _hasShownAdultMaxToast = false;
  bool _hasShownChildMaxToast = false;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<OrderController>();
    adultCount = controller.adultCount.value;
    childCount = controller.childCount.value;

    // 从桌台信息获取最大人数限制
    final table = controller.table.value;
    maxAdultCount = table?.standardAdult.toInt() ?? 10;
    maxChildCount = table?.standardChild.toInt() ?? 5;
  }

  /// 执行更换人数操作
  Future<void> _performChangePeopleCount() async {
    final controller = Get.find<OrderController>();
    final currentTableId = controller.table.value?.tableId.toInt();

    if (currentTableId == null) {
      Get.back(); // 关闭弹窗
      ErrorNotificationManager().showErrorNotification(
        title: '错误', 
        message: '当前桌台信息错误',
        errorCode: 'invalid_table_info',
      );
      return;
    }

    // 检查人数是否有变化，如果没有变化直接关闭弹窗
    if (adultCount == controller.adultCount.value &&
        childCount == controller.childCount.value) {
      Get.back(); // 关闭弹窗
      return;
    }

    // 先关闭弹窗
    Get.back();

    try {
      // 直接调用桌台详情API更新数据
      await _updateTableDetailAndRefresh(currentTableId);
    } catch (e) {
      ErrorNotificationManager().showErrorNotification(
        title: '错误', 
        message: '更换人数操作异常：$e',
        errorCode: 'update_people_exception',
      );
    }
  }

  /// 更新桌台详情并刷新数据
  Future<void> _updateTableDetailAndRefresh(int tableId) async {
    try {
      // 调用桌台详情API获取最新数据
      final result = await _api.getTableDetail(tableId: tableId);
      
      if (result.isSuccess && result.data != null) {
        final controller = Get.find<OrderController>();
        final latestTable = result.data!;
        
        // 更新桌台信息
        controller.table.value = latestTable;
        
        // 更新人数信息
        controller.adultCount.value = adultCount;
        controller.childCount.value = childCount;

        // 刷新点餐页面数据
        await controller.refreshOrderData();

        ErrorNotificationManager().showSuccessNotification(
          title: '成功', 
          message: '已成功更新人数',
          successCode: 'update_people_success',
        );
      } else {
        ErrorNotificationManager().showErrorNotification(
          title: '失败', 
          message: '获取桌台详情失败',
          errorCode: 'get_table_detail_failed',
        );
      }
    } catch (e) {
      ErrorNotificationManager().showErrorNotification(
        title: '错误', 
        message: '更新桌台数据异常：$e',
        errorCode: 'update_table_data_exception',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalContainerWithMargin(
      title: '更换人数',
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 当前人数显示
          Container(
            padding: EdgeInsets.all(16),
            child: Text(
              '当前人数 成人$adultCount 儿童$childCount',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ),
          // 人数选择
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PeopleCountSelector(
                    label: '成人',
                    count: adultCount,
                    maxCount: maxAdultCount,
                    onIncrement: () {
                      if (adultCount < maxAdultCount) {
                        setState(() {
                          adultCount++;
                          // 重置提示状态，因为数量增加了
                          _hasShownAdultMaxToast = false;
                        });
                      } else if (!_hasShownAdultMaxToast) {
                        // 只在第一次达到上限时显示提示
                        _hasShownAdultMaxToast = true;
                        ErrorNotificationManager().showWarningNotification(
                          title: '提示',
                          message: '成人数量不能超过$maxAdultCount人',
                          warningCode: 'adult_max_exceeded',
                        );
                      }
                    },
                    onDecrement: () {
                      if (adultCount > 1) {
                        setState(() {
                          adultCount--;
                          // 重置提示状态，因为数量减少了
                          _hasShownAdultMaxToast = false;
                        });
                      } else {
                        ModalUtils.showSnackBar(
                          title: '提示',
                          message: '成人数量最少1人',
                        );
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  _PeopleCountSelector(
                    label: '儿童',
                    count: childCount,
                    maxCount: maxChildCount,
                    onIncrement: () {
                      if (childCount < maxChildCount) {
                        setState(() {
                          childCount++;
                          // 重置提示状态，因为数量增加了
                          _hasShownChildMaxToast = false;
                        });
                      } else if (!_hasShownChildMaxToast) {
                        // 只在第一次达到上限时显示提示
                        _hasShownChildMaxToast = true;
                        ErrorNotificationManager().showWarningNotification(
                          title: '提示',
                          message: '儿童数量不能超过$maxChildCount人',
                          warningCode: 'child_max_exceeded',
                        );
                      }
                    },
                    onDecrement: () {
                      if (childCount > 0) {
                        setState(() {
                          childCount--;
                          // 重置提示状态，因为数量减少了
                          _hasShownChildMaxToast = false;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          // 确认按钮
          Container(
            padding: EdgeInsets.all(16),
            child: GestureDetector(
              onTap: _performChangePeopleCount,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '确认',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
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
  final int maxCount;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _PeopleCountSelector({
    Key? key,
    required this.label,
    required this.count,
    required this.maxCount,
    required this.onIncrement,
    required this.onDecrement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text(
              '最多$maxCount人',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        Spacer(),
        GestureDetector(
          onTap: onDecrement,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  (label == '成人' && count > 1) || (label == '儿童' && count > 0)
                  ? Colors.orange
                  : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.remove, color: Colors.white, size: 16),
          ),
        ),
        SizedBox(width: 16),
        Text(
          '$count',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 16),
        GestureDetector(
          onTap: onIncrement,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: count < maxCount ? Colors.orange : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}
