import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:order_app/pages/order/model/dish.dart';
import '../../constants/global_colors.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/pages/order/order_element/models.dart';
import 'package:order_app/pages/order/components/unified_cart_widget.dart';
import 'package:order_app/pages/order/components/order_submit_dialog.dart';
import 'package:order_app/pages/order/components/specification_modal_widget.dart';
import 'package:order_app/utils/image_cache_config.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:order_app/pages/takeaway/takeaway_order_success_page.dart';
import 'dish_detail_controller.dart';

class DishDetailPage extends StatefulWidget {
  final int? dishId;
  final int? menuId;
  final int? initialCartCount; // 从外部传入的已添加数量
  final Dish? dishData; // 直接传入的菜品数据

  const DishDetailPage({
    super.key,
    this.dishId,
    this.menuId,
    this.initialCartCount,
    this.dishData,
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
        dishData: widget.dishData,
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
                  // 菜品信息和敏感物
                  _buildDishInfoWithAllergen(controller),
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
        bottomNavigationBar: _buildBottomCartButton(),
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

  /// 构建菜品信息和敏感物
  Widget _buildDishInfoWithAllergen(DishDetailController controller) {
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
            // 敏感物信息（紧接着菜品名称）
            if (dish.allergens != null && dish.allergens!.isNotEmpty) ...[
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

  /// 构建价格和数量控制
  Widget _buildPriceAndQuantity(DishDetailController controller) {
    return Obx(() {
      final dish = controller.dish.value;
      if (dish == null) return const SizedBox.shrink();

      final dishModel = controller.convertToDishModel();
      final orderController = Get.find<OrderController>();

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
            // 数量控制 - 使用与列表页面相同的逻辑
            _buildQuantityControl(dishModel, orderController),
          ],
        ),
      );
    });
  }

  /// 构建数量控制组件 - 与列表页面完全一致
  Widget _buildQuantityControl(Dish dish, OrderController orderController) {
    return Obx(() {
      // 计算该菜品在购物车中的总数量
      int totalCount = 0;
      for (var entry in orderController.cart.entries) {
        if (entry.key.dish.id == dish.id) {
          totalCount += entry.value;
        }
      }

      // 根据hasOptions决定显示加减按钮还是选规格按钮 - 与列表页面完全一致
      if (dish.hasOptions) {
        return _buildSpecificationButton(dish, orderController, totalCount);
      } else {
        return _buildQuantityControls(totalCount, dish, orderController);
      }
    });
  }

  /// 构建数量控制按钮 - 与列表页面完全一致
  Widget _buildQuantityControls(int count, Dish dish, OrderController orderController) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 减号按钮 - 只在有数量时显示
        if (count > 0)
          GestureDetector(
            onTap: () {
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
        // 数量显示 - 只在有数量时显示
        if (count > 0) ...[
          const SizedBox(width: 12),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
        ],
        // 加号按钮
        GestureDetector(
          onTap: () {
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

  /// 构建选规格按钮 - 与列表页面完全一致
  Widget _buildSpecificationButton(Dish dish, OrderController orderController, int totalCount) {
    return GestureDetector(
      onTap: () {
        // 导入选规格弹窗组件
        SpecificationModalWidget.showSpecificationModal(
          context,
          dish,
        );
      },
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
          // 角标 - 显示该菜品在购物车中的总数量
          if (totalCount > 0)
            Positioned(
              right: -3,
              top: -6,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: totalCount > 99 ? 4 : 2,
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
                  '$totalCount',
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


  /// 构建底部购物车按钮
  Widget _buildBottomCartButton() {
    return GetBuilder<OrderController>(
      builder: (controller) {
        final totalCount = controller.totalCount;
        final totalPrice = controller.totalPrice;
        
        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 购物车图标和数量角标
              GestureDetector(
                onTap: () => UnifiedCartWidget.showCartModal(
                  context,
                  onSubmitOrder: _handleSubmitOrder,
                ),
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/order_shop_car.webp',
                      width: 44,
                      height: 44,
                    ),
                    if (totalCount > 0)
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
                            totalCount > 99 ? '99+' : totalCount.toString(),
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
              const SizedBox(width: 12),
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
                      totalCount > 0 ? '$totalPrice' : '0',
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
                onTap: _handleSubmitOrder,
                child: Container(
                  width: 80,
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
        );
      },
    );
  }

  /// 处理提交订单
  Future<void> _handleSubmitOrder() async {
    if (!mounted) return;
    
    final controller = Get.find<OrderController>();
    
    // 根据订单来源判断处理方式
    if (controller.source.value == 'takeaway') {
      // 外卖订单：跳转到预约时间页面
      _navigateToAppointmentPage(controller);
    } else {
      // 桌台订单：直接提交订单
      _submitTableOrder(controller);
    }
  }

  /// 跳转到预约时间页面
  void _navigateToAppointmentPage(OrderController controller) {
    if (!mounted) return;
    
    try {
      // 跳转到预约时间页面，传递桌台ID
      Get.to(
        () => TakeawayOrderSuccessPage(),
        arguments: {
          'tableId': controller.table.value?.tableId,
        },
      );
    } catch (e) {
      print('❌ 跳转预约时间页面失败: $e');
      GlobalToast.error('跳转失败，请重试');
    }
  }

  /// 提交桌台订单
  Future<void> _submitTableOrder(OrderController controller) async {
    if (!mounted) return;
    
    try {
      // 显示纯动画加载弹窗（无文字）
      OrderSubmitDialog.showLoadingOnly(context);
      
      final result = await controller.submitOrder();
      
      if (!mounted) return;
      
      // 关闭加载弹窗
      Navigator.of(context).pop();
      
      if (result['success'] == true) {
        // 下单成功，显示成功提示
        GlobalToast.success('订单已提交成功！');
        // 设置标记，表示需要切换到已点页面
        controller.justSubmittedOrder.value = true;
        // 立即返回到点餐页面，点餐页面会检测到这个标记并自动切换到已点页面
        Get.back(result: 'order_submitted');
        // 异步刷新已点订单数据（不阻塞跳转）
        controller.loadCurrentOrder(showLoading: false);
      } else {
        // 下单失败，显示真实接口返回的错误信息
        GlobalToast.error(result['message'] ?? '订单提交失败，请重试');
      }
    } catch (e) {
      print('❌ 提交订单异常: $e');
      if (mounted) {
        // 关闭加载弹窗
        Navigator.of(context).pop();
        // 显示错误提示
        GlobalToast.error('提交订单时发生错误，请重试');
      }
    }
  }
}