import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:order_app/pages/order/order_element/models.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/utils/modal_utils.dart';
import 'package:order_app/components/skeleton_widget.dart';

/// 统一的购物车弹窗组件
class UnifiedCartWidget {
  /// 显示购物车弹窗
  static void showCartModal(BuildContext context, {VoidCallback? onSubmitOrder}) {
    ModalUtils.showBottomModal(
      context: context,
      isScrollControlled: true,
      child: CartModalContainer(
        title: ' ',
        onClear: () => _showClearCartDialog(context),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 200, // 最小高度200px
            maxHeight: MediaQuery.of(context).size.height * 0.6, // 最大高度60%，自适应
          ),
          child: _CartModalContent(onSubmitOrder: onSubmitOrder),
        ),
      ),
    );
  }

  /// 显示清空购物车对话框
  static void _showClearCartDialog(BuildContext context) {
    ModalUtils.showConfirmDialog(
      context: context,
      message: '是否清空购物车？',
      confirmText: '清空',
      cancelText: '取消',
      confirmColor: Colors.red,
      onConfirm: () {
        final controller = Get.find<OrderController>();
        controller.clearCart();
      },
    );
  }
}


/// 购物车弹窗内容
class _CartModalContent extends StatelessWidget {
  final VoidCallback? onSubmitOrder;
  
  const _CartModalContent({this.onSubmitOrder});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = Get.find<OrderController>();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 购物车列表 - 只在初始加载时显示骨架图，操作时不显示
          controller.isLoadingCart.value && !controller.isCartOperationLoading.value
              ? const CartSkeleton()
              : controller.cart.isEmpty
                  ? Container(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '购物车是空的',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: controller.cart.length,
                        // 添加缓存和性能优化
                        cacheExtent: 200,
                        // 启用滚动功能
                        physics: ClampingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final entry = controller.cart.entries.elementAt(index);
                          final cartItem = entry.key;
                          final count = entry.value;
                          return _CartItem(
                            key: ValueKey('cart_item_${cartItem.cartSpecificationId ?? cartItem.dish.id}'),
                            cartItem: cartItem, 
                            count: count
                          );
                        },
                      ),
                    ),
          // 底部统计和下单
          if (controller.cart.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: Offset(0, -1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 购物车图标
                  Stack(
                    children: [
                      Image.asset(
                        'assets/order_shop_car.webp',
                        width: 50,
                        height: 50,
                      ),
                      // 角标
                      if (controller.cart.isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF1010),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              controller.cart.values.fold(0, (sum, count) => sum + count).toString(),
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
                  SizedBox(width: 12),
                  // 价格信息
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '￥',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1,
                            color: Color(0xFFFF1010),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${controller.totalPrice}',
                          style: TextStyle(
                            fontSize: 24,
                            height: 1,
                            color: Color(0xFFFF1010),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 下单按钮
                  GestureDetector(
                    onTap: () async {
                      // 先关闭购物车弹窗
                      Get.back();
                      // 然后执行下单逻辑（会显示新的加载弹窗）
                      if (onSubmitOrder != null) {
                        onSubmitOrder!();
                      }
                    },
                    child: Container(
                      width: 76,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9027),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: Text(
                          '下单',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}

/// 购物车项目
class _CartItem extends StatelessWidget {
  final CartItem cartItem;
  final int count;

  const _CartItem({
    Key? key,
    required this.cartItem,
    required this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrderController>();
    return Slidable(
      key: Key('cart_item_${cartItem.cartSpecificationId ?? cartItem.dish.id}'),
      // 使用更轻量的动画配置
      endActionPane: ActionPane(
        motion: const BehindMotion(), // 使用更简单的动画
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) {
              ModalUtils.showConfirmDialog(
                context: context,
                message: '是否删除菜品？',
                confirmText: '删除',
                cancelText: '取消',
                confirmColor: Colors.red,
                onConfirm: () {
                  controller.deleteCartItem(cartItem);
                },
              );
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '删除',
            borderRadius: BorderRadius.circular(8),
            // 添加性能优化
            flex: 1,
          ),
        ],
      ),
      // 添加性能优化配置
      closeOnScroll: true,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: cartItem.dish.image,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 46,
                  height: 46,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image, color: Colors.grey),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 46,
                  height: 46,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. 菜品名称
                  Text(
                    cartItem.dish.name,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  // 2. 敏感物图标（只显示图标，不显示文字，去除背景）
                  if (cartItem.dish.allergens != null && cartItem.dish.allergens?.isNotEmpty == true)
                    _AllergenIcons(allergens: cartItem.dish.allergens!),
                  // 3. 标签（tags）
                  if (cartItem.dish.tags != null && cartItem.dish.tags?.isNotEmpty == true)
                    Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: _DishTags(tags: cartItem.dish.tags!),
                    ),
                  SizedBox(height: 8),
                  // 4. 价格显示（单价）：￥（8pt 000000）价格（16pt 000000）/份（6pt #999999）
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "￥",
                        style: TextStyle(
                          fontSize: 8,
                          color: Color(0xFF000000),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      Text(
                        "${cartItem.dish.price}",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF000000),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "/份",
                        style: TextStyle(
                          fontSize: 6,
                          color: Color(0xFF999999),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => controller.removeFromCart(cartItem),
                    child: Icon(
                      Icons.remove_circle_outline,
                      color: Colors.orange,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => controller.addCartItemQuantity(cartItem),
                    child: Icon(
                      Icons.add_circle,
                      color: Colors.orange,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 购物车弹窗容器
class CartModalContainer extends StatelessWidget {
  final String title;
  final VoidCallback onClear;
  final Widget child;

  const CartModalContainer({
    Key? key,
    required this.title,
    required this.onClear,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖动指示条
          Container(
            padding: EdgeInsets.only(top: 8, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 顶部标题栏
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Spacer(),
                GestureDetector(
                  onTap: onClear,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/order_clear_icon.webp',
                        width: 16,
                        height: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '清空',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// 敏感物图标组件（优化性能）
class _AllergenIcons extends StatelessWidget {
  final List<dynamic> allergens;
  
  const _AllergenIcons({Key? key, required this.allergens}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final validAllergens = allergens.where((allergen) => 
      allergen.icon != null && allergen.icon!.isNotEmpty
    ).toList();
    
    if (validAllergens.isEmpty) return SizedBox.shrink();
    
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: validAllergens.map((allergen) {
        return CachedNetworkImage(
          imageUrl: allergen.icon!,
          width: 12,
          height: 12,
          fit: BoxFit.contain,
          placeholder: (context, url) => Image.asset(
            'assets/order_minganwu_place.webp',
            width: 12,
            height: 12,
            fit: BoxFit.contain,
          ),
          errorWidget: (context, url, error) => Image.asset(
            'assets/order_minganwu_place.webp',
            width: 12,
            height: 12,
            fit: BoxFit.contain,
          ),
        );
      }).toList(),
    );
  }
}

/// 菜品标签组件（优化性能）
class _DishTags extends StatelessWidget {
  final List<String> tags;
  
  const _DishTags({Key? key, required this.tags}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final validTags = tags.where((tag) => tag.isNotEmpty).toList();
    
    if (validTags.isEmpty) return SizedBox.shrink();
    
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: validTags.map((tag) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange[700]!),
            borderRadius: BorderRadius.circular(4),
          ),
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
    );
  }
}

/// 购物车骨架屏
class CartSkeleton extends StatelessWidget {
  const CartSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: List.generate(3, (index) => Container(
          margin: EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SkeletonPlaceholder(
                width: 46,
                height: 46,
                borderRadius: 8,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonPlaceholder(
                      width: double.infinity,
                      height: 16,
                      borderRadius: 4,
                    ),
                    SizedBox(height: 8),
                    SkeletonPlaceholder(
                      width: 80,
                      height: 12,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              SkeletonPlaceholder(
                width: 60,
                height: 24,
                borderRadius: 12,
              ),
            ],
          ),
        )),
      ),
    );
  }
}