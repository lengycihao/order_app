import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:order_app/utils/l10n_utils.dart';
import 'select_menu_controller.dart';
import 'package:order_app/utils/keyboard_utils.dart';

class SelectMenuPage extends StatelessWidget {
  const SelectMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 清理可能存在的旧实例
    if (Get.isRegistered<SelectMenuController>(tag: 'select_menu_page')) {
      Get.delete<SelectMenuController>(tag: 'select_menu_page');
    }
    
    // 创建新的控制器实例
    final controller = Get.put(SelectMenuController(), tag: 'select_menu_page');
    
    return Scaffold(
      backgroundColor: Color(0xffF9F9F9),
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset(
            'assets/order_arrow_back.webp',
            width: 24,
            height: 24,
          ),
          onPressed: controller.goBack,
        ),
        title: Obx(() => Text(
          controller.table.value.tableName ?? context.l10n.table,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        )),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: KeyboardUtils.buildDismissiblePage(
        child: Stack(
          children: [
            // 主要内容区域
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 选择人数卡片
                  _buildPersonCountCard(context),

                  // 选择菜单卡片
                  _buildMenuSelectionCard(context),

                  const SizedBox(height: 80), // 给底部按钮留空间
                ],
              ),
            ),
            
            // 固定在底部的按钮
            Positioned(
              left: 0,
              right: 0,
              bottom: 30, // 距离底部30px
              child: _buildBottomButton(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建选择人数卡片
  Widget _buildPersonCountCard(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(left: 32, right: 32,   bottom: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 10, bottom: 8, left: 8, right: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child:   Text(
                context.l10n.selectPeople,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF000000),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 18),

            // 成人数量选择
            _buildCountRow(
              context.l10n.adults,
              Get.find<SelectMenuController>(tag: 'select_menu_page').adultCount,
              Get.find<SelectMenuController>(tag: 'select_menu_page').increaseAdultCount,
              Get.find<SelectMenuController>(tag: 'select_menu_page').decreaseAdultCount,
            ),
SizedBox(height: 12,),
            // 儿童数量选择
            _buildCountRow(
              context.l10n.children,
              Get.find<SelectMenuController>(tag: 'select_menu_page').childCount,
              Get.find<SelectMenuController>(tag: 'select_menu_page').increaseChildCount,
              Get.find<SelectMenuController>(tag: 'select_menu_page').decreaseChildCount,
            ),SizedBox(height: 10,),
          ],
        ),
      ),
    );
  }

  /// 构建数量选择行
  Widget _buildCountRow(
    String label,
    RxInt count,
    VoidCallback onIncrease,
    VoidCallback onDecrease,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        _buildStepperWidget(count, onIncrease, onDecrease),
      ],
    );
  }

  /// 构建步进器组件
  Widget _buildStepperWidget(RxInt count, VoidCallback onIncrease, VoidCallback onDecrease) {
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
            onTap: onDecrease,
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
          // 数字显示区域 - 可编辑输入框
          Container(
            width: 32,
            height: 24,
            color: Colors.white,
            child: Center(
              child: Obx(
                () => SizedBox(
                  width: 32,
                  child: TextField(
                    controller: TextEditingController(text: '${count.value}'),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      alignLabelWithHint: true,
                    ),
                            cursorColor: Colors.black54,
                            showCursor: true,
                            enableInteractiveSelection: false,
                    onSubmitted: (value) {
                      final inputValue = int.tryParse(value);
                      if (inputValue != null && inputValue > 0) {
                        count.value = inputValue;
                      }
                    },
                    onChanged: (value) {
                      // 实时更新，但只在输入完成时验证
                    },
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
          // 增加按钮
          GestureDetector(
            onTap: onIncrease,
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


  /// 构建菜单选择卡片
  Widget _buildMenuSelectionCard(BuildContext context) {
    return Container(
      width: 343,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题行 - 选择菜单居中显示
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                width: double.infinity,
                  child: Text(
                    context.l10n.selectMenu,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1,
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 10), // 更换菜单距离上面10
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 10), // 分割线与更换菜单间距10
            // 菜单网格
            _buildMenuGrid(context),
          ],
        ),
      ),
    );
  }

  /// 构建菜单网格
  Widget _buildMenuGrid(BuildContext context) {
    final controller = Get.find<SelectMenuController>(tag: 'select_menu_page');
    
    return Obx(() {
      if (controller.isLoadingDishes.value) {
        return  SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(context.l10n.loadingData),
              ],
            ),
          ),
        );
      }
      
      if (controller.menu.isEmpty) {
        return   SizedBox(
          height: 200,
          child: Center(child: Text(context.l10n.noData)),
        );
      }

      final selectedIndex = controller.selectedMenuIndex.value; // 在Obx作用域内获取值
      
      // 固定菜品卡片高度
      const double itemHeight = 160;
      int crossAxisCount = (343 / 200).ceil(); // 根据容器宽度计算每行数量
      int rowCount = (controller.menu.length / crossAxisCount).ceil(); // 计算行数

      return Container(
        height: rowCount * itemHeight + (rowCount - 1) * 12, // 动态计算总高度
        child: GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.menu.length,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: itemHeight,
          ),
        itemBuilder: (context, index) {
          final item = controller.menu[index];
          final isSelected = selectedIndex == index; // 使用在Obx作用域内获取的值

              return GestureDetector(
            onTap: () => controller.selectMenu(index),
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 15),
                  width: 157, // 固定宽度157，自适应屏幕
                  height: 160, // 固定高度160
                  decoration: BoxDecoration(
                    color: Colors.white,
                  
                    border: Border.all(
                      color: controller.getMenuBorderColor(isSelected),
                      width: controller.getMenuBorderWidth(isSelected),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 菜单图片 - 固定尺寸容器
                      Container(
                        width: 142,
                        height: 88,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: item.menuImage ?? '',
                            width: 142,
                            height: 88,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Image.asset(
                              'assets/order_table_menu.webp',
                              width: 142,
                              height: 88,
                              fit: BoxFit.cover,
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/order_table_menu.webp',
                              width: 142,
                              height: 88,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      // 根据菜单类型决定是否显示价格信息
                      if (item.menuType != 2) ...[
                        const SizedBox(height: 3),
                        // 价格信息 - 文字可换行，使用 Flexible 避免溢出
                        Flexible(
                          child: _buildPriceInfo(item),
                        ),
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
                      item.menuName ?? '',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      );
    });
  }

  /// 构建底部按钮
  Widget _buildBottomButton(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 253, // 固定宽度253px
        height: 40,  // 固定高度40px
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF9027),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // 调整圆角以适应新尺寸
            ),
            padding: EdgeInsets.zero, // 移除内边距，使用固定尺寸
          ),
          onPressed: () => Get.find<SelectMenuController>(tag: 'select_menu_page').startOrdering(),
          child:   Text(
             context.l10n.startOrdering,
            style: TextStyle(
              fontSize: 16, // 调整字体大小以适应新尺寸
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建价格信息
  Widget _buildPriceInfo(dynamic item) {
    // 检查是否有menu_fixed_costs字段
    if (item.menuFixedCosts != null && item.menuFixedCosts.isNotEmpty) {
      // 构建固定费用信息列表
      List<Widget> costWidgets = [];
      
      for (var cost in item.menuFixedCosts) {
        if (cost.name != null && cost.amount != null && cost.unit != null) {
          costWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                '${cost.name}: ${cost.amount}/${cost.unit}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xff3D3D3D),
                ),
                textAlign: TextAlign.center,
                maxLines: 1, // 限制为单行
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }
      }

      if (costWidgets.isNotEmpty) {
        // 如果价格信息超过2行，使用可滑动的SingleChildScrollView
        if (costWidgets.length > 2) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: costWidgets,
            ),
          );
        } else {
          // 2行或以下，直接展示
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: costWidgets,
          );
        }
      }
    }

    // 如果没有固定费用信息，显示默认的成人和儿童价格
    return Text(
      '成人：${item.adultPackagePrice}/位\n儿童：${item.childPackagePrice}/位',
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xff666666),
      ),
      textAlign: TextAlign.center,
      maxLines: 2, // 允许换行
      overflow: TextOverflow.ellipsis,
    );
  }
}
