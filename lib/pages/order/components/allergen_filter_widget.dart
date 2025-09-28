import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:order_app/pages/order/order_element/models.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/utils/modal_utils.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';

/// 敏感物筛选组件
class AllergenFilterWidget {
  /// 显示敏感物筛选弹窗
  static void showAllergenModal(BuildContext context) {
    final controller = Get.find<OrderController>();
    
    // 同步临时选择状态
    controller.cancelAllergenSelection();
    
    // 如果敏感物数据为空且不在加载中，自动重新加载
    if (controller.allAllergens.isEmpty && !controller.isLoadingAllergens.value) {
      controller.loadAllergens();
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 370,
          width: MediaQuery.of(context).size.width * 0.9,
          child: _AllergenModalContent(),
        ),
      ),
    );
  }

  /// 构建敏感物筛选按钮
  static Widget buildFilterButton(BuildContext context) {
    return GestureDetector(
      onTap: () => showAllergenModal(context),
      child: Container(
        width: 24,
        height: 24,
        
        child: Image.asset(
          'assets/order_allergen_icon.webp', // 👈 本地图片路径
          width: 20, // 👈 对应 Icon 的 size
          height: 20,
          fit: BoxFit.contain,
        )
      ),
    );
  }
}

/// 敏感物弹窗内容
class _AllergenModalContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = Get.find<OrderController>();
      
      return ModalContainerWithMargin(
        title: '敏感物',
        margin: EdgeInsets.zero,
        showCloseButton: true,
        onClose: () {
          // 只清空临时选择状态，保留敏感物数据
          controller.cancelAllergenSelection();
          Get.back();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 说明文字
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '筛选含有敏感物的菜品',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xff666666),
                ),
              ),
            ),
            // 重新获取敏感物数据按钮
            if (controller.allAllergens.isEmpty && !controller.isLoadingAllergens.value)
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('没有敏感物数据'),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => controller.loadAllergens(),
                      child: Text('重新获取'),
                    ),
                  ],
                ),
              ),
            // 敏感物列表
            Flexible(
              child: controller.isLoadingAllergens.value
                  ? Center(
                      child: RestaurantLoadingWidget(
                        message: '加载敏感物中...',
                        size: 40.0,
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: controller.allAllergens.length,
                      itemBuilder: (context, index) {
                        final allergen = controller.allAllergens[index];
                        final isSelected = controller.tempSelectedAllergens.contains(allergen.id);
                        
                        return _AllergenItem(
                          allergen: allergen,
                          isSelected: isSelected,
                          onTap: () => controller.toggleTempAllergen(allergen.id),
                        );
                      },
                    ),
            ),
            Divider(
              height: 1,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 8,),
            // 已选敏感物显示
            if (controller.tempSelectedAllergens.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '已选敏感物：${controller.tempSelectedAllergens.map((id) {
                    final allergen = controller.allAllergens.firstWhereOrNull((a) => a.id == id);
                    return allergen?.label ?? '';
                  }).where((name) => name.isNotEmpty).join('、')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xff333333),
                  ),
                ),
              ),
            // 底部确认按钮
            Center(
              child: GestureDetector(
                onTap: () {
                  controller.confirmAllergenSelection();
                  Get.back();
                },
                child: Container(
                  width: 200,
                  height: 40,
                  margin: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(24),
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
          ],
        ),
      );
    });
  }
}

/// 敏感物列表项
class _AllergenItem extends StatelessWidget {
  final Allergen allergen;
  final bool isSelected;
  final VoidCallback onTap;

  const _AllergenItem({
    Key? key,
    required this.allergen,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, ),
        child: Row(
          children: [
            // 敏感物图标
            if (allergen.icon != null)
              CachedNetworkImage(
                imageUrl: allergen.icon!,
                width: 30,
                height: 30,
                errorWidget: (context, url, error) => Image.asset(
                  'assets/order_minganwu_place.webp',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
              )
            else
              Icon(
                Icons.warning,
                size: 24,
                color: Colors.orange,
              ),
            SizedBox(width: 14),
            // 敏感物名称
            Expanded(
              child: Text(
                allergen.label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Color(0xffFF9027) : Colors.grey.shade600,
                ),
              ),
            ),
            // 选中状态
            if (isSelected)
              Image(image: AssetImage("assets/order_allergen_sel.webp"),width:14,)
            else
               Image(image: AssetImage("assets/order_allergen_unsel.webp"),width:14,)
          ],
        ),
      ),
    );
  }
}
