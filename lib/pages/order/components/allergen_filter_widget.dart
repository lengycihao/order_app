import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:order_app/pages/order/order_element/models.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/utils/l10n_utils.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';

/// 敏感物筛选组件
class AllergenFilterWidget {
  /// 显示敏感物筛选弹窗
  static void showAllergenModal(BuildContext context) {
    final controller = Get.find<OrderController>();

    // 同步临时选择状态
    controller.cancelAllergenSelection();

    // 如果敏感物数据为空且不在加载中，自动重新加载
    if (controller.allAllergens.isEmpty &&
        !controller.isLoadingAllergens.value) {
      controller.loadAllergens();
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            minHeight: 370,
          ),
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
        ),
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

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: const Color(0xFF999999), width: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.allergens,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // 只清空临时选择状态，保留敏感物数据
                          controller.cancelAllergenSelection();
                          Get.back();
                        },
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    child: Text(
                      context.l10n.excludeDishesWithAllergens,
                      style: TextStyle(fontSize: 12, color: Color(0xff666666)),
                    ),
                  ),
                ],
              ),
            ),
            // 内容区域
            Column(
              children: [
            // 说明文字

            // 重新获取敏感物数据按钮
            if (controller.allAllergens.isEmpty &&
                !controller.isLoadingAllergens.value)
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(context.l10n.noData),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => controller.loadAllergens(),
                      child: Text(context.l10n.loadAgain),
                    ),
                  ],
                ),
              ),
            // 敏感物列表 - 固定高度265px
            Container(
              height: 265,
              child: controller.isLoadingAllergens.value
                  ? Center(
                      child: RestaurantLoadingWidget(
                        message: context.l10n.loadingData,
                        size: 40.0,
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      itemCount: controller.allAllergens.length,
                      itemBuilder: (context, index) {
                        final allergen = controller.allAllergens[index];
                        final isSelected = controller.tempSelectedAllergens
                            .contains(allergen.id);

                        return _AllergenItem(
                          allergen: allergen,
                          isSelected: isSelected,
                          onTap: () =>
                              controller.toggleTempAllergen(allergen.id),
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: Color(0xff999999)),
            SizedBox(height: 8),
            // 已选敏感物显示 - 最多3行，超过可滚动
            if (controller.tempSelectedAllergens.isNotEmpty)
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: 70, // 最多3行的高度 (12px * 3 + padding)
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SingleChildScrollView(
                  child: Text(
                    '${context.l10n.selected} ${controller.tempSelectedAllergens.map((id) {
                      final allergen = controller.allAllergens.firstWhereOrNull((a) => a.id == id);
                      return allergen?.label ?? '';
                    }).where((name) => name.isNotEmpty).join(', ')}',
                    style: TextStyle(fontSize: 12, color: Color(0xff333333)),
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
                  width: 180,
                  height: 32,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(24),
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
              ],
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
        padding: EdgeInsets.symmetric(vertical: 5,horizontal: 16),
        margin: EdgeInsets.symmetric(vertical: 2),
        color: isSelected ? Color(0xffFF9027).withOpacity(0.2) : Colors.white,
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
              Icon(Icons.warning, size: 24, color: Colors.orange),
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
              Image(
                image: AssetImage("assets/order_allergen_sel.webp"),
                width: 14,
              )
            else
              Image(
                image: AssetImage("assets/order_allergen_unsel.webp"),
                width: 14,
              ),
          ],
        ),
      ),
    );
  }
}
