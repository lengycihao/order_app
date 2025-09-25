import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/order/model/dish.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/pages/order/order_element/models.dart';
import 'package:order_app/pages/order/components/specification_modal_widget.dart';

/// 统一的数量控制组件
/// 用于菜品详情页面和菜品列表页面，保持UI和逻辑完全一致
class UnifiedQuantityControlWidget extends StatelessWidget {
  final Dish dish;
  final VoidCallback? onSpecificationTap;
  final VoidCallback? onAddTap;
  final VoidCallback? onRemoveTap;

  const UnifiedQuantityControlWidget({
    Key? key,
    required this.dish,
    this.onSpecificationTap,
    this.onAddTap,
    this.onRemoveTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderController = Get.find<OrderController>();
    
    return Obx(() {
      // 计算该菜品在购物车中的总数量
      int totalCount = 0;
      for (var entry in orderController.cart.entries) {
        if (entry.key.dish.id == dish.id) {
          totalCount += entry.value;
        }
      }

      if (totalCount > 0) {
        // 已添加到购物车，显示数量控制
        return _buildQuantityControls(totalCount);
      } else {
        // 未添加到购物车，显示添加按钮或规格选择
        if (dish.hasOptions) {
          return _buildSpecificationButton();
        } else {
          return _buildAddButton();
        }
      }
    });
  }

  /// 构建数量控制按钮
  Widget _buildQuantityControls(int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 减号按钮
        GestureDetector(
          onTap: onRemoveTap ?? () {
            final orderController = Get.find<OrderController>();
            // 找到对应的购物车项进行删除
            CartItem? targetCartItem;
            for (var entry in orderController.cart.entries) {
              if (entry.key.dish.id == dish.id && entry.key.selectedOptions.isEmpty) {
                targetCartItem = entry.key;
                break;
              }
            }
            if (targetCartItem != null) {
              orderController.removeFromCart(targetCartItem);
            }
          },
          child: Image(
            image: AssetImage('assets/order_reduce_num.webp'),
            width: 22,
            height: 22,
          ),
        ),
        const SizedBox(width: 12),
        // 数量显示
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 12),
        // 加号按钮
        GestureDetector(
          onTap: onAddTap ?? () {
            final orderController = Get.find<OrderController>();
            orderController.addToCart(dish);
          },
          child: Image(
            image: AssetImage('assets/order_add_num.webp'),
            width: 22,
            height: 22,
          ),
        ),
      ],
    );
  }

  /// 构建选规格按钮
  Widget _buildSpecificationButton() {
    final orderController = Get.find<OrderController>();
    
    return Obx(() {
      // 计算规格项的数量
      int specCount = 0;
      for (var entry in orderController.cart.entries) {
        if (entry.key.dish.id == dish.id && entry.key.selectedOptions.isNotEmpty) {
          specCount += entry.value;
        }
      }
      
      return GestureDetector(
        onTap: onSpecificationTap ?? () {
          SpecificationModalWidget.showSpecificationModal(
            Get.context!,
            dish,
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '选规格',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // 角标
            if (specCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$specCount',
                    style: const TextStyle(
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
    });
  }

  /// 构建添加按钮
  Widget _buildAddButton() {
    return GestureDetector(
      onTap: onAddTap ?? () {
        final orderController = Get.find<OrderController>();
        orderController.addToCart(dish);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          '加入购物车',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
