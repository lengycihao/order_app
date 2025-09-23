import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:order_app/pages/order/model/dish.dart';
import 'package:order_app/pages/order/order_element/models.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import '../../constants/global_colors.dart';
import 'package:order_app/pages/order/components/specification_modal_widget.dart';
import 'package:order_app/pages/order/components/order_submit_dialog.dart';
import 'package:order_app/widgets/keyboard_input_widget.dart';
import 'package:order_app/pages/order/ordered_page.dart';
import 'package:order_app/pages/takeaway/takeaway_order_success_page.dart';
import 'package:order_app/utils/image_cache_config.dart';
import 'dish_detail_controller.dart';

class DishDetailPage extends StatefulWidget {
  final int dishId;
  final int menuId;
  final int? initialCartCount; // 从外部传入的已添加数量

  const DishDetailPage({
    super.key,
    required this.dishId,
    required this.menuId,
    this.initialCartCount,
  });

  @override
  State<DishDetailPage> createState() => _DishDetailPageState();
}

class _DishDetailPageState extends State<DishDetailPage> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<DishDetailController>(
      init: DishDetailController(
        dishId: widget.dishId, 
        menuId: widget.menuId,
        initialCartCount: widget.initialCartCount,
      ),
      builder: (controller) => Scaffold(
        backgroundColor: GlobalColors.primaryBackground,
        body: Stack(
          children: [
            // 内容区域
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 菜品图片（紧贴顶部）
                  _buildDishImage(controller),
                  // 菜品信息
                  _buildDishInfo(controller),
                  // 敏感物信息
                  _buildAllergenSection(controller),
                  // 价格和数量控制
                  _buildPriceAndQuantity(controller),
                  const SizedBox(height: 100), // 给底部购物车留空间
                ],
              ),
            ),
            // 覆盖在图片上的返回按钮
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: _buildBackButton(),
            ),
          ],
        ),
        // 底部购物车
        bottomNavigationBar: _buildBottomCart(controller),
      ),
    );
  }

  /// 构建返回按钮
  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  /// 构建菜品图片
  Widget _buildDishImage(DishDetailController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Container(
          width: double.infinity,
          height: 300,
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final dish = controller.dish.value;
      if (dish == null) {
        return Container(
          width: double.infinity,
          height: 300,
          color: Colors.grey.shade200,
          child: const Center(
            child: Text('图片加载失败'),
          ),
        );
      }

      return AspectRatio(
        aspectRatio: 16 / 9,
        child: CachedNetworkImage(
          imageUrl: dish.image ?? '',
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: double.infinity,
            height: 300,
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: double.infinity,
            height: 300,
            color: Colors.grey.shade200,
            child: const Center(
              child: Text('图片加载失败'),
            ),
          ),
          memCacheWidth: ImageCacheConfig.dishMemCacheWidth,
          memCacheHeight: ImageCacheConfig.dishMemCacheHeight,
          maxWidthDiskCache: ImageCacheConfig.dishMaxWidthDiskCache,
          maxHeightDiskCache: ImageCacheConfig.dishMaxHeightDiskCache,
        ),
      );
    });
  }

  /// 构建菜品信息
  Widget _buildDishInfo(DishDetailController controller) {
    return Obx(() {
      final dish = controller.dish.value;
      if (dish == null) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 菜品名称
            Text(
              dish.name ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 8),
            // 菜品描述
            if (dish.description != null && dish.description!.isNotEmpty) ...[
              Text(
                dish.description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      );
    });
  }

  /// 构建敏感物信息
  Widget _buildAllergenSection(DishDetailController controller) {
    return Obx(() {
      final dish = controller.dish.value;
      if (dish == null || dish.allergens == null || dish.allergens!.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '敏感物',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: dish.allergens!.map((allergen) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (allergen.icon != null)
                      CachedNetworkImage(
                        imageUrl: allergen.icon!,
                        width: 16,
                        height: 16,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.warning, size: 16, color: Colors.orange),
                      ),
                    if (allergen.icon != null) const SizedBox(width: 4),
                    Text(
                      allergen.label ?? '',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF3D3D3D)),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    });
  }

  /// 构建价格和数量控制
  Widget _buildPriceAndQuantity(DishDetailController controller) {
    return Obx(() {
      final dish = controller.dish.value;
      if (dish == null) return const SizedBox.shrink();

      final dishModel = controller.convertToDishModel();
      final cartCount = controller.cartCount.value;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // 价格信息
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '￥${dish.price ?? '0'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const TextSpan(
                      text: '/份',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 数量控制
            _buildQuantityControls(controller, dishModel, cartCount),
          ],
        ),
      );
    });
  }

  /// 构建数量控制
  Widget _buildQuantityControls(
    DishDetailController controller,
    Dish dishModel,
    int cartCount,
  ) {
    final orderController = Get.find<OrderController>();

    if (cartCount > 0) {
      // 已添加到购物车，显示数量控制
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              // 找到对应的购物车项进行删除
              CartItem? targetCartItem;
              for (var entry in orderController.cart.entries) {
                if (entry.key.dish.id == dishModel.id && entry.key.selectedOptions.isEmpty) {
                  targetCartItem = entry.key;
                  break;
                }
              }
              if (targetCartItem != null) {
                orderController.removeFromCart(targetCartItem);
              }
            },
            child: const Icon(
              Icons.remove_circle_outline,
              color: Colors.orange,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showQuantityInputDialog(dishModel, cartCount),
            child: Text(
              '$cartCount',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => orderController.addToCart(dishModel),
            child: const Icon(
              Icons.add_circle,
              color: Colors.orange,
              size: 22,
            ),
          ),
        ],
      );
    } else {
      // 未添加到购物车，显示添加按钮或规格选择
      if (dishModel.hasOptions) {
        return Obx(() {
          // 重新计算规格项数量，确保响应式更新
          int currentSpecCount = 0;
          for (var entry in orderController.cart.entries) {
            if (entry.key.dish.id == dishModel.id && entry.key.selectedOptions.isNotEmpty) {
              currentSpecCount += entry.value;
            }
          }
          
          return GestureDetector(
            onTap: () {
              SpecificationModalWidget.showSpecificationModal(
                Get.context!,
                dishModel,
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
                if (currentSpecCount > 0)
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
                        '$currentSpecCount',
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
      } else {
        return GestureDetector(
          onTap: () => orderController.addToCart(dishModel),
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
  }

  /// 构建底部购物车
  Widget _buildBottomCart(DishDetailController controller) {
    final orderController = Get.find<OrderController>();
    
    return Obx(() {
      final totalCount = orderController.totalCount;
      final totalPrice = orderController.totalPrice;
      
      if (totalCount == 0) {
        return const SizedBox.shrink();
      }

      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // 购物车图标和数量
            GestureDetector(
              onTap: () {
                if (totalCount > 0) {
                  _showCartModal();
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    'assets/order_shop_car.webp.webp',
                    width: 50,
                    height: 50,
                    color: totalCount > 0 ? null : Colors.grey,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '$totalCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 价格信息
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '￥',
                          style: TextStyle(
                            color: Color(0xFFFF1010),
                            fontSize: 12,
                          ),
                        ),
                        TextSpan(
                          text: '${totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Color(0xFFFF1010),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '共$totalCount件商品',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            // 下单按钮
            ElevatedButton(
              onPressed: () => _handleSubmitOrder(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                '下单',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 显示购物车弹窗
  void _showCartModal() {
    final orderController = Get.find<OrderController>();
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // 拖拽指示器
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      '购物车',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // 购物车内容
              Expanded(
                child: orderController.cart.isEmpty
                    ? const Center(
                        child: Text('购物车是空的'),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: orderController.cart.length,
                        itemBuilder: (context, index) {
                          final entry = orderController.cart.entries.elementAt(index);
                          final cartItem = entry.key;
                          final count = entry.value;
                          return _buildCartItem(cartItem, count);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建购物车项
  Widget _buildCartItem(dynamic cartItem, int count) {
    final orderController = Get.find<OrderController>();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 菜品图片
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: cartItem.dish.image,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 60,
                height: 60,
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                width: 60,
                height: 60,
                color: Colors.grey.shade200,
                child: const Icon(Icons.error),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 菜品信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.dish.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (cartItem.specificationText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    cartItem.specificationText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '￥${cartItem.dish.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          // 数量控制
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => orderController.removeFromCart(cartItem),
                child: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => orderController.addCartItemQuantity(cartItem),
                child: const Icon(
                  Icons.add_circle,
                  color: Colors.orange,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 处理提交订单
  Future<void> _handleSubmitOrder() async {
    if (!mounted) return;
    
    final orderController = Get.find<OrderController>();
    
    // 根据来源决定跳转页面
    if (orderController.source.value == 'takeaway') {
      // 外卖订单，先清空购物车，然后跳转到外卖下单成功页面
      orderController.clearCart();
      print('🧹 外卖订单提交前清空购物车数据');
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TakeawayOrderSuccessPage(),
          settings: RouteSettings(
            arguments: {
              'tableId': orderController.table.value?.tableId ?? 0,
            },
          ),
        ),
      );
    } else {
      // 堂食订单，需要提交订单
      try {
        // 显示纯动画加载弹窗（无文字）
        OrderSubmitDialog.showLoadingOnly(context);
        
        // 提交订单
        final result = await orderController.submitOrder();
        
        if (!mounted) return;
        
        // 关闭加载弹窗
        Navigator.of(context).pop();
        
        if (result['success'] == true) {
          // 返回到上一页
          Navigator.of(context).pop();
          
          // 跳转到已点页面
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OrderedPage()),
          );
        } else {
          // 下单失败，显示具体错误信息
          await OrderSubmitDialog.showError(
            context,
            message: result['message'] ?? '订单提交失败，请重试',
          );
        }
      } catch (e) {
        print('❌ 提交订单异常: $e');
        if (mounted) {
          // 显示错误弹窗（自动关闭加载弹窗）
          await OrderSubmitDialog.showError(
            context,
            message: '提交订单时发生错误，请重试',
          );
        }
      }
    }
  }

  /// 显示数量输入对话框
  void _showQuantityInputDialog(Dish dishModel, int currentQuantity) {
    KeyboardInputManager.show(
      context: context,
      initialValue: currentQuantity.toString(),
      hintText: '请输入数量',
      dishName: dishModel.name, // 传递菜品名称
      onConfirm: (inputText) {
        final newQuantity = int.tryParse(inputText.trim());
        
        // 验证输入
        if (newQuantity == null || newQuantity < 0) {
          Get.dialog(
            AlertDialog(
              title: Text('输入无效'),
              content: Text('请输入有效的数量（非负整数）'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('确定'),
                ),
              ],
            ),
          );
          return;
        }
        
        if (newQuantity == currentQuantity) {
          // 数量没有变化，直接返回
          return;
        }
        
        if (newQuantity == 0) {
          // 数量为0，删除商品
          _showDeleteConfirmDialog(dishModel);
          return;
        }
        
        // 执行数量更新
        _updateDishQuantity(dishModel, newQuantity);
      },
      onCancel: () {
        // 取消编辑，不做任何操作
      },
      keyboardType: TextInputType.number,
      maxLength: 3, // 限制最大3位数
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(Dish dishModel) {
    Get.dialog(
      AlertDialog(
        title: Text('删除商品'),
        content: Text('确定要删除 "${dishModel.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _deleteDishFromCart(dishModel);
            },
            child: Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 删除菜品
  void _deleteDishFromCart(Dish dishModel) {
    final orderController = Get.find<OrderController>();
    
    // 找到对应的购物车项进行删除
    CartItem? targetCartItem;
    for (var entry in orderController.cart.entries) {
      if (entry.key.dish.id == dishModel.id && entry.key.selectedOptions.isEmpty) {
        targetCartItem = entry.key;
        break;
      }
    }
    
    if (targetCartItem != null) {
      orderController.removeFromCart(targetCartItem);
    }
  }

  /// 更新菜品数量
  void _updateDishQuantity(Dish dishModel, int newQuantity) {
    final orderController = Get.find<OrderController>();
    
    // 找到对应的购物车项
    CartItem? targetCartItem;
    for (var entry in orderController.cart.entries) {
      if (entry.key.dish.id == dishModel.id && entry.key.selectedOptions.isEmpty) {
        targetCartItem = entry.key;
        break;
      }
    }
    
    if (targetCartItem != null) {
      // 执行WebSocket操作
      orderController.updateCartItemQuantity(
        cartItem: targetCartItem,
        newQuantity: newQuantity,
        onSuccess: () {
          // 更新成功，UI会自动刷新
        },
        onError: (code, message) {
          if (code == 409) {
            _showDoubleConfirmDialog(dishModel, newQuantity);
          } else {
            Get.dialog(
              AlertDialog(
                title: Text('操作失败'),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('确定'),
                  ),
                ],
              ),
            );
          }
        },
      );
    }
  }

  /// 显示二次确认对话框（409错误）
  void _showDoubleConfirmDialog(Dish dishModel, int newQuantity) {
    Get.dialog(
      AlertDialog(
        title: Text('操作冲突'),
        content: Text('检测到其他用户正在修改此商品，是否继续更新数量为 $newQuantity？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // 延迟执行更新，确保对话框完全关闭
              Future.delayed(Duration(milliseconds: 100), () {
                _updateDishQuantity(dishModel, newQuantity);
              });
            },
            child: Text('继续'),
          ),
        ],
      ),
    );
  }
}
