import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:order_app/pages/order/model/dish.dart';
import 'package:order_app/utils/l10n_utils.dart';
import '../../constants/global_colors.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/pages/order/order_element/models.dart';
import 'package:order_app/pages/order/components/unified_cart_widget.dart';
import 'package:order_app/pages/order/components/order_submit_dialog.dart';
import 'package:order_app/pages/order/components/specification_modal_widget.dart';
import 'package:order_app/pages/order/components/parabolic_animation_widget.dart';
import 'package:order_app/utils/image_cache_config.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:order_app/utils/modal_utils.dart';
import 'package:lib_base/lib_base.dart';
import 'package:lib_base/utils/navigation_manager.dart';
import 'package:order_app/pages/nav/screen_nav_page.dart';
import 'dish_detail_controller.dart';
import 'package:lib_base/logging/logging.dart';

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
  // 购物车按钮的GlobalKey，用于动画定位
  final GlobalKey _cartButtonKey = GlobalKey();
  
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
          child:   Center(
            child: Text(context.l10n.failed),
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
            child:   Center(
              child: Text(context.l10n.failed),
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
              //   Text(
              //   context.l10n.allergens,
              //   style: TextStyle(
              //     fontSize: 14,
              //     fontWeight: FontWeight.bold,
              //     color: Color(0xFF666666),
              //   ),
              // ),
              // const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: dish.allergens!.map((allergen) {
                  return Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (allergen.icon != null)
                        CachedNetworkImage(
                          imageUrl: allergen.icon!,
                          width: 16,
                          height: 16,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/order_minganwu_place.webp',
                            width: 16,
                            height: 16,
                            fit: BoxFit.contain,
                          ),
                        ),
                      if (allergen.icon != null) const SizedBox(width: 4),
                      Text(
                        allergen.label ?? '',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF3D3D3D)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                      text: '€${dish.price ?? '0'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000000),
                      ),
                    ),
                      TextSpan(
                      text: context.l10n.perPortion,
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

  /// 构建数量控制按钮 - 与列表页面完全一致，添加动画效果
  Widget _buildQuantityControls(int count, Dish dish, OrderController orderController) {
    // 为加号按钮创建独立的GlobalKey
    final GlobalKey addButtonKey = GlobalKey();
    
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
            behavior: HitTestBehavior.opaque, // 阻止事件穿透
            child: Container(
              padding: EdgeInsets.all(8), // 增大点击区域
              child: Image(
                image: AssetImage('assets/order_reduce_num.webp'),
                width: 22,
                height: 22,
              ),
            ),
          ),
        // 数量显示 - 只在有数量时显示
        if (count > 0) ...[
          const SizedBox(width: 5),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 5),
        ],
        // 加号按钮 - 添加动画效果和14005错误状态检查
        Obx(() {
          final isLoading = orderController.isDishLoading(dish.id);
          final isAddDisabled = orderController.isDishAddDisabled(dish.id);
          final isDisabled = isLoading || isAddDisabled;
          
          return GestureDetector(
            key: addButtonKey,
            onTap: isDisabled ? null : () {
              // 触发抛物线动画
              try {
                ParabolicAnimationManager.triggerAddToCartAnimation(
                  context: context,
                  addButtonKey: addButtonKey,
                  cartButtonKey: _cartButtonKey,
                );
              } catch (e) {
                print('❌ 抛物线动画错误: $e');
                // 动画失败不影响添加功能
              }
              
              // 添加到购物车
              orderController.addToCart(dish);
            },
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
        }),
      ],
    );
  }

  /// 构建选规格按钮 - 与列表页面完全一致，添加动画效果
  Widget _buildSpecificationButton(Dish dish, OrderController orderController, int totalCount) {
    return GestureDetector(
      onTap: () {
        // 导入选规格弹窗组件，传递购物车按钮key用于动画
        SpecificationModalWidget.showSpecificationModal(
          context,
          dish,
          cartButtonKey: _cartButtonKey,
        );
      },
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
                context.l10n.selectSpecification,
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
                key: _cartButtonKey, // 添加GlobalKey用于动画定位
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
                      '€',
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
                  child:   Center(
                    child: Text(
                      context.l10n.placeOrder,
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
    
    // 根据服务员设置决定是否显示确认弹窗
    if (controller.waiterSetting.value.confirmOrderBeforeSubmit) {
      // 显示确认下单弹窗 - 与退出登录弹窗保持完全一致
      final confirm = await ModalUtils.showConfirmDialog(
        context: context,
        message: context.l10n.confirmOrder,  // 使用message参数，不使用title
        confirmText: context.l10n.confirm,
        cancelText: context.l10n.cancel,
        confirmColor: Color(0xFFFF9027), // 使用橙色确认按钮，与退出登录一致
      );
      
      // 如果用户取消，直接返回
      if (confirm != true) return;
    }
    
    // 根据订单来源判断处理方式
    if (controller.source.value == 'takeaway') {
      // 外卖订单：直接提交订单（不跳转到备注页面）
      _submitTakeawayOrder(controller);
    } else {
      // 桌台订单：直接提交订单
      _submitTableOrder(controller);
    }
  }

  /// 提交外卖订单（直接提交，不跳转到备注页面）
  Future<void> _submitTakeawayOrder(OrderController controller) async {
    if (!mounted) return;
    
    try {
      // 显示纯动画加载弹窗（无文字）
      OrderSubmitDialog.showLoadingOnly(context);
      
      // 获取桌台ID
      final tableId = controller.table.value?.tableId;
      if (tableId == null || tableId <= 0) {
        if (mounted) {
          Navigator.of(context).pop();
          ToastUtils.showError(context, context.l10n.operationTooFrequentPleaseTryAgainLater);
        }
        return;
      }
      
      // 准备提交参数（包含备注）
      final params = {
        'table_id': tableId,
        'remark': controller.remark.value, // 提交备注
      };
      
      // 调用外卖订单提交API
      final result = await HttpManagerN.instance.executePost(
        '/api/waiter/cart/submit_takeout_order',
        jsonParam: params,
      );
      
      if (!mounted) return;
      
      // 关闭加载弹窗
      Navigator.of(context).pop();
      
      if (result.isSuccess) {
        // 下单成功，清空备注
        controller.clearRemark();
        // 显示成功提示
        ToastUtils.showSuccess(context, '订单提交成功');
        // 跳转到主页面并切换到外卖标签页，同时刷新桌台数据
        Get.offAll(() => ScreenNavPage(initialIndex: 1));
        // 延迟刷新桌台数据，确保页面切换完成
        Future.delayed(Duration(milliseconds: 500), () {
          NavigationManager.refreshTableData();
        });
      } else {
        // 下单失败，显示错误提示
        final errorMessage = result.msg ?? '订单提交失败';
        ToastUtils.showError(context, errorMessage);
      }
    } catch (e) {
      logError('❌ 提交外卖订单异常: $e', tag: 'DishDetailPage');
      if (mounted) {
        // 关闭加载弹窗
        Navigator.of(context).pop();
        // 显示错误提示
        ToastUtils.showError(context, '${context.l10n.networkErrorPleaseTryAgain}');
      }
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
        GlobalToast.error(result['message'] ?? context.l10n.orderPlacementFailedContactWaiter);
      }
    } catch (e) {
      logError('提交订单异常: $e', tag: 'DishDetailPage');
      if (mounted) {
        // 关闭加载弹窗
        Navigator.of(context).pop();
        // 显示错误提示
        GlobalToast.error(context.l10n.networkErrorPleaseTryAgain);
      }
    }
  }
}