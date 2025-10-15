import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/order/model/dish.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
// import 'package:order_app/pages/order/components/parabolic_animation_widget.dart';
import 'package:order_app/utils/cart_animation_registry.dart';
import 'package:order_app/utils/l10n_utils.dart';
import 'package:order_app/widgets/robust_image_widget.dart';

/// 菜品列表项组件
class DishItemWidget extends StatelessWidget {
  final Dish dish;
  final VoidCallback? onSpecificationTap;
  final VoidCallback? onAddTap;
  final VoidCallback? onRemoveTap;
  final VoidCallback? onDishTap;
  final GlobalKey? cartButtonKey;
  
  // 为每个菜品组件创建独立的加号按钮Key
  late final GlobalKey _addButtonKey = GlobalKey();

  DishItemWidget({
    Key? key,
    required this.dish,
    this.onSpecificationTap,
    this.onAddTap,
    this.onRemoveTap,
    this.onDishTap,
    this.cartButtonKey,
  }) : super(key: key);

  /// 优化：获取该菜品在购物车中的数量
  int _getDishCount(OrderController controller) {
    int count = 0;
    for (var entry in controller.cart.entries) {
      if (entry.key.dish.id == dish.id) {
        count += entry.value;
      }
    }
    return count;
  }

  // 处理添加到购物车：改为登记动画 + 发送WS
  void _handleAddToCart(BuildContext context) {
     
    // 计算并登记动画坐标（不立即播放）
    if (cartButtonKey != null) {
      try {
        final RenderBox? addBox = _addButtonKey.currentContext?.findRenderObject() as RenderBox?;
        final RenderBox? cartBox = cartButtonKey!.currentContext?.findRenderObject() as RenderBox?;
        if (addBox != null && cartBox != null) {
          final addPos = addBox.localToGlobal(Offset.zero) + Offset(addBox.size.width * 0.2, addBox.size.height * 0.2);
          final cartPos = cartBox.localToGlobal(Offset.zero) + Offset(cartBox.size.width / 2, cartBox.size.height / 2);
           CartAnimationRegistry.enqueue(addPos, cartPos);
        } else {
          debugPrint('❌ 无法获取按钮位置: addBox=$addBox, cartBox=$cartBox');
        }
      } catch (e) {
        debugPrint('❌ 登记动画坐标异常: $e');
      }
    } else {
      debugPrint('❌ cartButtonKey为空，无法登记动画');
    }

    // 发送添加操作（由控制器WS发送），由回执触发展示动画
    onAddTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrderController>();
    
    // 使用更精确的监听，只监听购物车变化
    return Obx(() {
      // 优化：只监听该菜品的数量变化，而不是整个购物车
      int count = _getDishCount(controller);
      
      return Container(
        color: Colors.white,
        padding: EdgeInsets.only(left: 10, right: 15, top: 8, bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 菜品图片 - 只有这里可以点击进入详情
            _buildDishImage(),
            SizedBox(width: 8),
            // 菜品信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 菜品名称和过敏图标
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 菜品名称
                      Text(
                        dish.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // 过敏图标
                      _buildAllergenIcons(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 价格和操作按钮
                  _buildPriceAndActions(count),
                ],
              ),
            ),
          ],
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
    
    return GestureDetector(
      onTap: onDishTap,
      behavior: HitTestBehavior.opaque, // 确保点击区域覆盖整个图片
      child: DishImageWidget(
        imageUrl: dish.image,
        width: 100,
        height: 100,
        fit: BoxFit.contain,
        borderRadius: BorderRadius.circular(8),
        onImageLoaded: () {
          // 图片加载成功，可以在这里添加统计或日志
          // print('✅ 菜品图片加载成功: ${dish.name}');
        },
        onImageError: () {
          // 图片加载失败，可以在这里添加统计或日志
          // print('❌ 菜品图片加载失败: ${dish.name}');
        },
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
            children: validAllergens.map((allergen) {
              return RobustImageWidget(
                imageUrl: allergen.icon!,
                width: 12,
                height: 12,
                fit: BoxFit.contain,
                placeholder: Image.asset(
                  'assets/order_minganwu_place.webp',
                  width: 12,
                  height: 12,
                  fit: BoxFit.contain,
                ),
                errorWidget: Image.asset(
                  'assets/order_minganwu_place.webp',
                  width: 12,
                  height: 12,
                  fit: BoxFit.contain,
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
        widgets.add(SizedBox(height: 8,));
        widgets.add(
          Wrap(
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
        // 价格显示：￥（8pt 000000）价格（16pt 000000）
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              "€",
              style: TextStyle(
                fontSize: 8,
                color: Color(0xFF000000),
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              "${dish.price}",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF000000),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
      behavior: HitTestBehavior.opaque, // 阻止事件穿透
      child: Container(
        padding: EdgeInsets.all(8), // 增大点击区域
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
                Get.context!.l10n.selectSpecification,
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
      ),
    );
  }

  /// 构建数量控制按钮
  Widget _buildQuantityControls(int count) {
    final controller = Get.find<OrderController>();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 减号按钮
        if (count > 0)
          Obx(() {
            final isLoading = controller.isDishLoading(dish.id);
            return GestureDetector(
              onTap: isLoading ? null : onRemoveTap,
              behavior: HitTestBehavior.opaque, // 阻止事件穿透
              child: Container(
                padding: EdgeInsets.all(8), // 增大点击区域
                child: Opacity(
                  opacity: isLoading ? 0.3 : 1.0, // loading时置灰
                  child: Image(
                    image: AssetImage('assets/order_reduce_num.webp'),
                    width: 22,
                    height: 22,
                  ),
                ),
              ),
            );
          }),
        // if (count > 0) SizedBox(width: 5),
        // 数量显示
        if (count > 0)
          Text(
            "$count",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        // if (count > 0) SizedBox(width: 5),
        // 加号按钮 - 添加loading状态和14005错误状态检查
        Builder(
          builder: (BuildContext buttonContext) {
            return Obx(() {
              final isLoading = controller.isDishLoading(dish.id);
              final isAddDisabled = controller.isDishAddDisabled(dish.id);
              final isDisabled = isLoading || isAddDisabled;
              
              return GestureDetector(
                key: _addButtonKey,
                onTap: isDisabled ? null : () => _handleAddToCart(buttonContext),
                behavior: HitTestBehavior.opaque, // 阻止事件穿透
                child: Container(
                  padding: EdgeInsets.all(8), // 增大点击区域
                  child: Opacity(
                    opacity: isAddDisabled ? 0.3 : 1.0, // 14005错误时置灰
                    child: Image(
                      image: AssetImage('assets/order_add_num.webp'),
                      width: 22,
                      height: 22,
                    ),
                  ),
                ),
              );
            });
          },
        ),
      ],
    );
  }
}
