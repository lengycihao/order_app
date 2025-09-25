import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'select_menu_controller.dart';
import 'package:order_app/utils/keyboard_utils.dart';

class SelectMenuPage extends GetView<SelectMenuController> {
  const SelectMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 确保控制器已初始化
    Get.put(SelectMenuController());
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
        title: Text(controller.table.value.hallName ?? '大厅名称'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: KeyboardUtils.buildDismissiblePage(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 选择人数卡片
              _buildPersonCountCard(),

              // 选择菜单卡片
              _buildMenuSelectionCard(),

              const SizedBox(height: 80), // 给底部按钮留空间
              // 底部按钮
              _buildBottomButton(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建选择人数卡片
  Widget _buildPersonCountCard() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(left: 32, right: 32, top: 12, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: const Text(
                '选择人数',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 18),

            // 成人数量选择
            _buildCountRow(
              '大人',
              controller.adultCount,
              controller.increaseAdultCount,
              controller.decreaseAdultCount,
            ),
SizedBox(height: 12,),
            // 儿童数量选择
            _buildCountRow(
              '小孩',
              controller.childCount,
              controller.increaseChildCount,
              controller.decreaseChildCount,
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
  Widget _buildMenuSelectionCard() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: const Text(
                '选择菜单',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 18),

            // 菜单网格
            _buildMenuGrid(),
          ],
        ),
      ),
    );
  }

  /// 构建菜单网格
  Widget _buildMenuGrid() {
    return Obx(() {
      if (controller.menu.isEmpty) {
        return const SizedBox(
          height: 200,
          child: Center(child: Text('暂无菜单数据')),
        );
      }

      final selectedIndex = controller.selectedMenuIndex.value; // 在Obx作用域内获取值
      
      // 检查是否有menuType为2的菜单（只显示图片）
      final hasImageOnlyMenus = controller.menu.any((menu) => menu.menuType == 2);
      final hasRegularMenus = controller.menu.any((menu) => menu.menuType != 2);
      
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
                            imageUrl: item.menuImage ?? '',
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
                      if (item.menuType != 2) ...[
                        const SizedBox(height: 6),
                        // 价格信息 - 文字可换行
                        Expanded(
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
      );
    });
  }

  /// 构建底部按钮
  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF9027),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => controller.startOrdering(),
          child: const Text(
            '开始点餐',
            style: TextStyle(
              fontSize: 18,
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
                  fontSize: 11,
                  color: Color(0xff666666),
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
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: costWidgets,
        );
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
