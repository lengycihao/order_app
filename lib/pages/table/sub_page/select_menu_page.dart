import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'select_menu_controller.dart';

class SelectMenuPage extends GetView<SelectMenuController> {
  const SelectMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 确保控制器已初始化
    Get.put(SelectMenuController());
    return Scaffold(
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
      body: SingleChildScrollView(
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
    );
  }

  /// 构建选择人数卡片
  Widget _buildPersonCountCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '选择人数',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 成人数量选择
            _buildCountRow(
              '成人',
              controller.adultCount,
              controller.increaseAdultCount,
              controller.decreaseAdultCount,
            ),

            // 儿童数量选择
            _buildCountRow(
              '儿童',
              controller.childCount,
              controller.increaseChildCount,
              controller.decreaseChildCount,
            ),
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
    // 获取最大人数限制
    final maxCount = label == '成人'
        ? controller.table.value.standardAdult.toInt()
        : controller.table.value.standardChild.toInt();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 15)),
            Text(
              '最多$maxCount人',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: onDecrease,
            ),
            Obx(
              () => Text(
                '${count.value}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onIncrease,
            ),
          ],
        ),
      ],
    );
  }

  /// 构建菜单选择卡片
  Widget _buildMenuSelectionCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
              ),
            ),
            const SizedBox(height: 8),

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

      return GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.menu.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: controller.getMenuBorderColor(isSelected),
                      width: controller.getMenuBorderWidth(isSelected),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // 菜单标签

                      // 菜单图片
                      Expanded(
                        child: Image.network(
                          item.menuImage ?? '',
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Image.asset(
                              'assets/order_table_menu.webp',
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/order_table_menu.webp',
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 价格信息
                      _buildPriceInfo(item),
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
            Text(
              '${cost.name}: ${cost.amount}/${cost.unit}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xff666666),
              ),
              textAlign: TextAlign.center,
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
    return Text(
      '成人：${item.adultPackagePrice}/位\n儿童：${item.childPackagePrice}/位',
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xff666666),
      ),
      textAlign: TextAlign.center,
    );
  }
}
