import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:order_app/pages/order/model/dish.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/pages/order/order_element/models.dart';
import 'package:order_app/pages/order/components/quantity_input_widget.dart';

/// 菜品列表项组件
class DishItemWidget extends StatelessWidget {
  final Dish dish;
  final VoidCallback? onSpecificationTap;
  final VoidCallback? onAddTap;
  final VoidCallback? onRemoveTap;
  final VoidCallback? onDishTap;

  const DishItemWidget({
    Key? key,
    required this.dish,
    this.onSpecificationTap,
    this.onAddTap,
    this.onRemoveTap,
    this.onDishTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = Get.find<OrderController>();
      // 计算该菜品在购物车中的总数量（包括所有规格）
      int count = 0;
      for (var entry in controller.cart.entries) {
        if (entry.key.dish.id == dish.id) {
          count += entry.value;
        }
      }
      
      return GestureDetector(
        onTap: onDishTap,
        child: Container(
          height: 116,
          color: Colors.white,
          padding: EdgeInsets.only(left: 10, right: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 菜品图片
              _buildDishImage(),
              SizedBox(width: 8),
              // 菜品信息
              Expanded(
                child: SizedBox(
                  height: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 菜品名称
                      Text(
                        dish.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 过敏图标
                      _buildAllergenIcons(),
                      const SizedBox(height: 6),
                      Spacer(),
                      // 价格和操作按钮
                      _buildPriceAndActions(count),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// 构建菜品图片
  Widget _buildDishImage() {
    // 如果图片URL为空，不显示任何内容
    if (dish.image.isEmpty) {
      return SizedBox.shrink();
    }
    
    return CachedNetworkImage(
      imageUrl: dish.image,
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      imageBuilder: (context, imageProvider) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image(
          image: imageProvider,
          fit: BoxFit.cover,
          width: 100,
          height: 100,
        ),
      ),
      placeholder: (context, url) => Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.image, color: Colors.grey),
      ),
      errorWidget: (context, url, error) => Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  /// 构建敏感物和标签
  Widget _buildAllergenIcons() {
    List<Widget> widgets = [];
    
    // 显示敏感物（allergens）- 只显示图标，不显示名字，无背景
    if (dish.allergens != null && dish.allergens!.isNotEmpty) {
      // 过滤掉空的敏感物数据
      final validAllergens = dish.allergens!.where((allergen) => 
        allergen.icon != null && allergen.icon!.isNotEmpty
      ).toList();
      
      if (validAllergens.isNotEmpty) {
        widgets.add(
          Wrap(
            spacing: 4,
            runSpacing: 2,
            children: validAllergens.take(3).map((allergen) {
              return Container(
                child: CachedNetworkImage(
                  imageUrl: allergen.icon!,
                  width: 16,
                  height: 16,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => SizedBox.shrink(),
                  errorWidget: (context, url, error) => SizedBox.shrink(),
                ),
              );
            }).toList(),
          ),
        );
      }
    }
    
    // 显示标签（tags）- 去掉背景
    if (dish.tags != null && dish.tags!.isNotEmpty) {
      // 过滤掉空的标签数据
      final validTags = dish.tags!.where((tag) => 
        tag.isNotEmpty
      ).toList();
      
      if (validTags.isNotEmpty) {
        widgets.add(
          Wrap(
            spacing: 4,
            runSpacing: 2,
            children: validTags.take(3).map((tag) {
              return Container(
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }
    }
    
    if (widgets.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// 构建价格和操作按钮
  Widget _buildPriceAndActions(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          "￥${dish.price.toStringAsFixed(0)}",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        Spacer(),
        SizedBox(width: 10),
        // 根据hasOptions决定显示加减按钮还是选规格按钮
        if (dish.hasOptions) ...[
          _buildSpecificationButton(count),
        ] else ...[
          _buildQuantityControls(count),
        ],
      ],
    );
  }

  /// 构建选规格按钮
  Widget _buildSpecificationButton(int count) {
    return GestureDetector(
      onTap: onSpecificationTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '选规格',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (count > 0)
            Positioned(
              right: -3,
              top: -6,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: count > 99 ? 4 : 2,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建数量控制按钮
  Widget _buildQuantityControls(int count) {
    final controller = Get.find<OrderController>();
    
    // 查找对应的购物车项
    CartItem? cartItem;
    for (var entry in controller.cart.entries) {
      if (entry.key.dish.id == dish.id && entry.key.selectedOptions.isEmpty) {
        cartItem = entry.key;
        break;
      }
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 减号按钮
        if (count > 0)
          GestureDetector(
            child: Icon(
              Icons.remove_circle_outline,
              color: Colors.orange,
              size: 22,
            ),
            onTap: onRemoveTap,
          ),
        if (count > 0) SizedBox(width: 5),
        // 数量显示 - 如果有购物车项则使用可点击输入
        if (count > 0)
          cartItem != null
              ? QuantityInputWidget(
                  cartItem: cartItem,
                  currentQuantity: count,
                  isInCartModal: false,
                  onQuantityChanged: () {
                    // 刷新UI
                    controller.update();
                  },
                )
              : Text(
                  "$count",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        if (count > 0) SizedBox(width: 5),
        // 加号按钮 - 直接显示，无loading状态
        GestureDetector(
          onTap: onAddTap,
          child: Icon(
            Icons.add_circle,
            color: Colors.orange,
            size: 22,
          ),
        ),
      ],
    );
  }
}
