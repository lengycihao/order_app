import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/utils/modal_utils.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:order_app/utils/screen_adaptation.dart';
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
                      Navigator.of(context).pop(); // 关闭更多选项弹窗
                      // 延迟显示更换桌台弹窗，确保导航栈稳定
                      Future.delayed(Duration(milliseconds: 100), () {
                        _showChangeTableModal(context);
                      });
                    },
                  ),
                  SizedBox(height: 30),
                  _MoreOptionItem(
                    title: '更换菜单',
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
                    title: '更换人数',
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
        GlobalToast.error('获取桌台列表失败');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      GlobalToast.error('获取桌台列表异常：$e');
    }
  }

  /// 执行换桌操作
  Future<void> _performChangeTable() async {
    if (_selectedTableId == null) {
      GlobalToast.error('请选择需要更换的桌台');
      return;
    }

    final controller = Get.find<OrderController>();
    final currentTableId = controller.table.value?.tableId.toInt();

    if (currentTableId == null) {
      GlobalToast.error('当前桌台信息错误');
      return;
    }

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

        GlobalToast.success('已成功更换桌台');
      } else {
        GlobalToast.error(result.msg ?? '换桌失败');
      }
    } catch (e) {
      // 异常情况下也要关闭弹窗
      if (mounted) {
        Navigator.of(context).pop();
      }
      GlobalToast.error('换桌操作异常：$e');
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
          // 桌子列表 - 自适应高度，最小220px，最大500px
          Container(
            constraints: BoxConstraints(
              minHeight: 220,
              maxHeight: ScreenAdaptation.adaptHeight(context, 500),
            ),
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
                    physics: ClampingScrollPhysics(),
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
          // 确认按钮
          Container(
            padding: EdgeInsets.all(16),
            child: Center(
              child: GestureDetector(
                onTap: _performChangeTable,
                child: Container(
                  width: 180,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '确认',
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

  /// 构建菜单网格
  Widget _buildMenuGrid() {
    // 检查是否有menuType为2的菜单（只显示图片）
    final hasImageOnlyMenus = _menuList.any((menu) => menu.menuType == 2);
    final hasRegularMenus = _menuList.any((menu) => menu.menuType != 2);
    
    // 根据菜单类型动态设置高度
    double itemHeight;
    if (hasImageOnlyMenus && hasRegularMenus) {
      // 混合类型，使用较大高度适配两种类型
      itemHeight = 200;
    } else if (hasImageOnlyMenus && !hasRegularMenus) {
      // 全部是图片类型，使用较小高度
      itemHeight = 120; // 88px图片 + 16px padding + 16px余量
    } else {
      // 全部是带价格信息的类型，使用标准高度
      itemHeight = 200;
    }

    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _menuList.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: itemHeight,
      ),
      itemBuilder: (context, index) {
        final menu = _menuList[index];
        final isSelected = _selectedMenuId == menu.menuId;

        return _MenuItem(
          imageUrl: menu.menuImage ?? '',
          menuName: menu.menuName ?? '未知菜单',
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
          // 菜单列表 - 自适应高度，最小220px
          Container(
            constraints: BoxConstraints(
              minHeight: 220,
            ),
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
                : _buildMenuGrid(),
          ),
          // 确认按钮
          Container(
            padding: EdgeInsets.all(16),
            child: Center(
              child: GestureDetector(
                onTap: _performChangeMenu,
                child: Container(
                  width: 180,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '确认',
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
            width: 157, // 固定宽度157，自适应屏幕
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
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
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 菜单图片 - 147*88 自适应屏幕
                Container(
                  width: 147,
                  height: 88,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 147,
                      height: 88,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Image.asset(
                        'assets/order_menu_placeholder.webp',
                        width: 147,
                        height: 88,
                        fit: BoxFit.contain,
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/order_menu_placeholder.webp',
                        width: 147,
                        height: 88,
                        fit: BoxFit.contain,
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
            top: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(15, 3, 15, 3),
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange : Colors.grey.shade400,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.elliptical(35, 30), // 左上角椭圆半径
                  bottomRight: Radius.elliptical(35, 35), // 右下角椭圆半径
                ),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                menuName,
                style: const TextStyle(fontSize: 14, color: Colors.white),
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
    final controller = Get.find<OrderController>();
    final currentTableId = controller.table.value?.tableId.toInt();

    if (currentTableId == null) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭弹窗
      }
      GlobalToast.error('当前桌台信息错误');
      return;
    }

    // 检查是否有人数变化，只有当任何一个大于1的时候才发WS消息
    if (adultCount <= 0 && childCount <= 0) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭弹窗
      }
      GlobalToast.error('请至少选择1人');
      return;
    }

    // 先关闭弹窗
    if (mounted) {
      Navigator.of(context).pop();
    }

    try {
      // 计算新的人数（现有人数 + 新增人数）
      final controller = Get.find<OrderController>();
      final newAdultCount = controller.adultCount.value + adultCount;
      final newChildCount = controller.childCount.value + childCount;
      
      // 直接调用桌台详情API更新数据
      await _updateTableDetailAndRefresh(currentTableId, newAdultCount, newChildCount);
    } catch (e) {
      GlobalToast.error('更换人数操作异常：$e');
    }
  }

  /// 更新桌台详情并刷新数据
  Future<void> _updateTableDetailAndRefresh(int tableId, int newAdultCount, int newChildCount) async {
    try {
      // 调用桌台详情API获取最新数据
      final result = await _api.getTableDetail(tableId: tableId);
      
      if (result.isSuccess && result.data != null) {
        final controller = Get.find<OrderController>();
        final latestTable = result.data!;
        
        // 更新桌台信息
        controller.table.value = latestTable;
        
        // 更新人数信息（现有人数 + 新增人数）
        controller.adultCount.value = newAdultCount;
        controller.childCount.value = newChildCount;

        // 刷新点餐页面数据
        await controller.refreshOrderData();

        GlobalToast.success('已成功更新人数');
      } else {
        GlobalToast.error('获取桌台详情失败');
      }
    } catch (e) {
      GlobalToast.error('更新桌台数据异常：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalContainerWithMargin(
      title: '增加人数',
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
                    label: '大人',
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
                    label: '小孩',
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
                      '确认',
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
