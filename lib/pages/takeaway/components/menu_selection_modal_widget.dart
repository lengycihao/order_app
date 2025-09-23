import 'package:flutter/material.dart';
import 'package:order_app/utils/l10n_utils.dart';
import 'package:order_app/pages/order/components/modal_utils.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';
import 'package:order_app/pages/order/components/error_notification_manager.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/menu_fixed_cost.dart';
import 'package:lib_domain/api/base_api.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

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
      
      ErrorNotificationManager().showErrorNotification(
        title: '错误',
        message: '加载菜单失败',
        errorCode: 'load_menu_exception',
      );
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
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: ModalContainerWithMargin(
        title: '选择菜单',
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 菜单列表 - 使用固定高度避免IntrinsicHeight冲突
            Container(
              height: 400, // 设置固定高度
              padding: EdgeInsets.all(16),
              child: _isLoading
                  ? Container(
                      height: 120,
                      child: Center(
                        child: RestaurantLoadingWidget(size: 30),
                      ),
                    )
                  : _errorMessage != null
                  ? Container(
                      height: 200,
                      child: Center(
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
                      ),
                    )
                  : _menuList.isEmpty
                  ? Container(
                      height: 150,
                      child: Center(
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
                      ),
                    )
                  : _buildMenuGrid(),
            ),
            // 确认按钮
            Container(
              padding: EdgeInsets.all(16),
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
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建菜单网格
  Widget _buildMenuGrid() {
    return MasonryGridView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true, // 添加shrinkWrap以支持固定高度容器
      gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
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
      return Text(
        context.l10n.noData,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey,
        ),
        textAlign: TextAlign.center,
        maxLines: 2, // 允许最多2行
        overflow: TextOverflow.ellipsis,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: menuFixedCosts!.take(3).map((cost) { // 最多显示3个价格项
        return Padding(
          padding: EdgeInsets.only(bottom: 1),
          child: Text(
            '${cost.name ?? ''}：${cost.amount ?? ''} / ${cost.type ?? ''} ${cost.unit ?? ''}',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // 每个价格项允许最多2行
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 图片区域 - 固定尺寸，保持正方形
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        padding: EdgeInsets.all(4),
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
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: _buildPriceInfo(context),
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
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
