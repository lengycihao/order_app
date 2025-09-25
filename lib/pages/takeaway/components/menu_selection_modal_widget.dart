import 'package:flutter/material.dart';
import 'package:order_app/utils/l10n_utils.dart';
import 'package:order_app/utils/modal_utils.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/menu_fixed_cost.dart';
import 'package:lib_domain/api/base_api.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 菜单选择弹窗组件
class MenuSelectionModalWidget {
  /// 显示菜单选择弹窗
  static Future<TableMenuListModel?> showMenuSelectionModal(
    BuildContext context, {
    TableMenuListModel? currentMenu,
  }) async {
    return await showDialog<TableMenuListModel?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8, // 最大高度限制
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: _MenuSelectionModalContent(currentMenu: currentMenu),
        ),
      ),
    );
  }
}

/// 菜单选择弹窗内容
class _MenuSelectionModalContent extends StatefulWidget {
  final TableMenuListModel? currentMenu;
  
  const _MenuSelectionModalContent({
    Key? key,
    this.currentMenu,
  }) : super(key: key);

  @override
  _MenuSelectionModalContentState createState() => _MenuSelectionModalContentState();
}

class _MenuSelectionModalContentState extends State<_MenuSelectionModalContent> {
  bool _isLoading = true;
  List<TableMenuListModel> _menuList = [];
  TableMenuListModel? _selectedMenu;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 设置当前选中的菜单
    _selectedMenu = widget.currentMenu;
    _loadMenuList();
  }

  /// 加载菜单列表
  Future<void> _loadMenuList() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await BaseApi().getTableMenuList();
      
      if (result.isSuccess && result.data != null) {
        setState(() {
          _menuList = result.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result.msg ?? '加载菜单失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载菜单时发生错误: $e';
        _isLoading = false;
      });
      
      GlobalToast.error('加载菜单失败');
    }
  }

  /// 确认选择菜单
  void _confirmSelection() {
    if (_selectedMenu != null) {
      Navigator.of(context).pop(_selectedMenu);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalContainerWithMargin(
      title: '选择菜单',
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
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red.shade600,
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadMenuList,
                            child: Text(context.l10n.more),
                          ),
                        ],
                      ),
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
                            context.l10n.noData,
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
          ),
          // 确认按钮
          Container(
            padding: EdgeInsets.all(16),
            child: Center(
              child: GestureDetector(
                onTap: _confirmSelection,
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

  /// 构建菜单网格
  Widget _buildMenuGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85, // 调整比例以适应新的尺寸
      ),
      itemCount: _menuList.length,
      itemBuilder: (context, index) {
        final menu = _menuList[index];
        final isSelected = _selectedMenu?.menuId == menu.menuId;

        return _MenuItem(
          imageUrl: menu.menuImage ?? '',
          menuName: menu.menuName ?? '未知菜单',
          menuFixedCosts: menu.menuFixedCosts,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _selectedMenu = menu;
            });
          },
        );
      },
    );
  }
}

/// 菜单项
class _MenuItem extends StatelessWidget {
  final String menuName;
  final String imageUrl; // 这里可以添加图片URL字段
  final List<MenuFixedCost>? menuFixedCosts;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuItem({
    Key? key,
    required this.menuName,
    required this.imageUrl,
    this.menuFixedCosts,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  /// 构建价格信息
  Widget _buildPriceInfo(BuildContext context) {
    if (menuFixedCosts == null || menuFixedCosts!.isEmpty) {
      return SizedBox.shrink();
    }

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

    if (costWidgets.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: costWidgets,
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
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Image.asset(
                        'assets/order_menu_placeholder.webp',
                        width: 147,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/order_menu_placeholder.webp',
                        width: 147,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 价格信息 - 文字可换行
                _buildPriceInfo(context),
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
