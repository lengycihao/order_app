import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:order_app/pages/order/model/dish.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/utils/l10n_utils.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:lib_base/logging/logging.dart';
// import 'package:order_app/pages/order/components/parabolic_animation_widget.dart';
import 'package:order_app/utils/cart_animation_registry.dart';

/// 规格选择弹窗组件
class SpecificationModalWidget {
  /// 显示规格选择弹窗
  static void showSpecificationModal(
    BuildContext context,
    
    Dish dish, {
    GlobalKey? cartButtonKey,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: _SpecificationModalContent(
          dish: dish,
          cartButtonKey: cartButtonKey,
        ),
      ),
    );
  }
}

/// 规格选择弹窗内容
class _SpecificationModalContent extends StatefulWidget {
  final Dish dish;
  final GlobalKey? cartButtonKey;

  const _SpecificationModalContent({
    Key? key,
    required this.dish,
    this.cartButtonKey,
  }) : super(key: key);

  @override
  State<_SpecificationModalContent> createState() =>
      _SpecificationModalContentState();
}

class _SpecificationModalContentState
    extends State<_SpecificationModalContent> {
  Map<int, List<int>> selectedOptions = {}; // 规格ID -> 选中的选项ID列表
  int quantity = 1;
  double totalPrice = 0;
  // 已移除：_quantityController 和 _quantityFocusNode（禁用手动输入数量）
  final GlobalKey _addToCartButtonKey = GlobalKey(); // 加购按钮key用于动画

  @override
  void initState() {
    super.initState();
    totalPrice = widget.dish.price;
    // 初始化默认选中每个规格的第一个选项
    for (var option in widget.dish.options ?? []) {
      if (option.items != null && option.items!.isNotEmpty) {
        selectedOptions[option.id!] = [option.items!.first.id!];
      }
    }
    // 已移除：_quantityController 和 _quantityFocusNode 初始化（禁用手动输入数量）
  }

  @override
  void dispose() {
    // 已移除：_quantityController 和 _quantityFocusNode dispose（禁用手动输入数量）
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.only(left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 关键：只占用必要空间
        children: [
          // 标题栏
          Container(
            padding: EdgeInsets.only(top: 14, bottom: 2),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 24),
                    child: Text(
                      widget.dish.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Icon(Icons.close, size: 20, color: Color(0xff666666)),
                ),
              ],
            ),
          ),
          Container(width: double.infinity, height: 0.4, color: Color(0xffD8D8D8)),
          // 内容区域 - 固定高度，可滚动
          Container(
            height: 310, // 固定310px高度
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: 10, bottom: 16),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // 敏感物信息（不可选）
                    if (widget.dish.allergens != null &&
                        widget.dish.allergens!.isNotEmpty) ...[
                      _buildAllergenSection(),
                      SizedBox(height: 8),
                    ],
                    // 规格选项
                    if (widget.dish.options != null &&
                        widget.dish.options!.isNotEmpty) ...[
                      _buildOptionsSection(),
                      SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // 底部数量选择和购物车按钮
          _buildBottomSection(),
        ],
      ),
    );
  }

  /// 构建敏感物部分
  Widget _buildAllergenSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.allergens,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xff666666),
          ),
        ),
        SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: widget.dish.allergens!.map((allergen) {
            return Container(
              constraints: BoxConstraints(
                maxWidth: double.infinity, // 允许占满可用宽度
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (allergen.icon != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: allergen.icon!,
                        width: 16,
                        height: 16,
                        errorWidget: (context, url, error) => Image.asset(
                          'assets/order_minganwu_place.webp',
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  if (allergen.icon != null) SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      allergen.label ?? '',
                      style: TextStyle(fontSize: 12, color: Color(0xff3D3D3D)),
                      overflow: TextOverflow.visible, // 允许文字换行
                      softWrap: true, // 启用软换行
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建规格选项部分
  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.dish.options!
          .map<Widget>(
            (option) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.name ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff666666),
                  ),
                ),
                SizedBox(height: 6),
                if (option.isMultiple == true) ...[
                  _buildMultipleChoiceOptions(option),
                ] else ...[
                  _buildSingleChoiceOptions(option),
                ],
                SizedBox(height: 20),
              ],
            ),
          )
          .toList(),
    );
  }

  /// 构建多选选项
  Widget _buildMultipleChoiceOptions(dynamic option) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: (option.items ?? []).map<Widget>((item) {
        final isSelected =
            selectedOptions[option.id]?.contains(item.id) ?? false;
        return GestureDetector(
          onTap: () {
            setState(() {
              if (selectedOptions[option.id] == null) {
                selectedOptions[option.id!] = [];
              }
              if (isSelected) {
                // 如果是必选且只剩一个选项，不允许取消
                if (option.isRequired == true && selectedOptions[option.id]!.length == 1) {
                  return;
                }
                selectedOptions[option.id]!.remove(item.id);
              } else {
                selectedOptions[option.id]!.add(item.id!);
              }
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? Color(0x33FF9027) : Color(0xffF1F1F1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? Color(0xffFF9027) : Colors.transparent,
              ),
            ),
            child: Text(
              '${item.label ?? ''}',
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Color(0xffFF9027) : Colors.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建单选选项
  Widget _buildSingleChoiceOptions(dynamic option) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: (option.items ?? []).map<Widget>((item) {
        final isSelected =
            selectedOptions[option.id]?.contains(item.id) ?? false;
        return GestureDetector(
          onTap: () {
            setState(() {
              // 单选模式下，直接设置选中项
              selectedOptions[option.id!] = [item.id!];
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? Color(0x33FF9027) : Color(0xffF1F1F1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? Color(0xffFF9027) : Colors.transparent,
              ),
            ),
            child: Text(
              '${item.label ?? ''}',
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Color(0xffFF9027) : Colors.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建已选规格文本
  Widget _buildSelectedSpecsText() {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: 70, // 最多3行的高度 (12px * 3 + padding)
      ),
      padding: EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        child: Text(
          '${context.l10n.selected} ${_getSelectedSpecsText()}',
          style: TextStyle(fontSize: 12, color: Color(0xff666666)),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// 获取已选规格文本
  String _getSelectedSpecsText() {
    List<String> specs = [];
    for (var option in widget.dish.options ?? []) {
      if (selectedOptions[option.id]?.isNotEmpty == true) {
        List<String> optionNames = [];
        for (var item in option.items ?? []) {
          if (selectedOptions[option.id]!.contains(item.id)) {
            optionNames.add(item.label ?? '');
          }
        }
        if (optionNames.isNotEmpty) {
          // specs.add('${option.name}: ${optionNames.join(', ')}');
          specs.add(optionNames.join(', '));
        }
      }
    }
    return specs.join(', ');
  }

  // 已移除：_updateQuantityFromInput 方法（禁用手动输入数量）

  /// 构建底部区域（数量选择 + 购物车按钮）
  Widget _buildBottomSection() {
    return Container(
      padding: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        // border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 数量选择
          Row(
            children: [
              Text(
                context.l10n.quantity,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff666666),
                ),
              ),
              Spacer(),
              // 统一的步进器组件
              Container(
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 减少按钮
                    GestureDetector(
                      onTap: () {
                        if (quantity > 1) {
                          setState(() {
                            quantity--;
                          });
                        }
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4),
                            bottomLeft: Radius.circular(4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '一',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff666666),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 分割线
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.grey.shade300,
                    ),
                    // 数字显示区域 - 禁用手动输入，仅显示数量
                    Container(
                      width: 32,
                      height: 24,
                      color: Colors.white,
                      child: Center(
                        child: Text(
                          '$quantity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ),
                    // 分割线
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.grey.shade300,
                    ),
                    // 增加按钮
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          quantity++;
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '+',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff666666),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Container(
            
            width: MediaQuery.of(context).size.width, height: 0.4, color: Color(0xffD8D8D8)),
          
          if (selectedOptions.isNotEmpty) ...[_buildSelectedSpecsText()],

          SizedBox(height: 10),
          // 价格和购物车按钮
          Row(
            children: [
              Text(
                '€',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
              Text(
                '$totalPrice',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Spacer(),

              GestureDetector(
                key: _addToCartButtonKey,
                onTap: _addToCart,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+${context.l10n.cart}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 添加到购物车
  void _addToCart() {
    // 检查必选项
    String? missingOptionName;
    for (var option in widget.dish.options ?? []) {
      if (option.isRequired == true) {
        if (selectedOptions[option.id]?.isEmpty ?? true) {
          missingOptionName = option.name;
          break;
        }
        // 对于必选的多选规格，至少要选一个
        if (option.isMultiple == true && (selectedOptions[option.id]?.isEmpty ?? true)) {
          missingOptionName = option.name;
          break;
        }
      }
    }

    if (missingOptionName == null) {
      // 添加到购物车
      final controller = Get.find<OrderController>();

      // 计算并登记动画坐标（不立即播放）
      if (widget.cartButtonKey != null) {
        try {
          final RenderBox? addBox = _addToCartButtonKey.currentContext?.findRenderObject() as RenderBox?;
          final RenderBox? cartBox = widget.cartButtonKey!.currentContext?.findRenderObject() as RenderBox?;
          if (addBox != null && cartBox != null) {
            final addPos = addBox.localToGlobal(Offset.zero) + Offset(addBox.size.width * 0.2, addBox.size.height * 0.2);
            final cartPos = cartBox.localToGlobal(Offset.zero) + Offset(cartBox.size.width / 2, cartBox.size.height / 2);
            CartAnimationRegistry.enqueue(addPos, cartPos);
          }
        } catch (_) {}
      }

      // 构建选择的规格选项 - 直接传递optionId和itemIds
      Map<String, List<String>> selectedOptionsMap = {};
      selectedOptions.forEach((optionId, selectedItemIds) {
        if (selectedItemIds.isNotEmpty) {
          // 直接使用optionId作为key，itemIds作为value
          selectedOptionsMap[optionId.toString()] = selectedItemIds
              .map((id) => id.toString())
              .toList();
        }
      });

      logDebug('🔍 规格选择弹窗调试信息:', tag: 'SpecModal');
      logDebug('  菜品: ${widget.dish.name}', tag: 'SpecModal');
      logDebug('  数量: $quantity', tag: 'SpecModal');
      logDebug('  规格选项: $selectedOptionsMap', tag: 'SpecModal');
      logDebug('  当前购物车项数: ${controller.cart.length}', tag: 'SpecModal');

      // 直接添加指定数量的商品到购物车
      controller.addToCartWithQuantity(
        widget.dish,
        quantity: quantity,
        selectedOptions: selectedOptionsMap,
      );

      logDebug(
        '✅ 规格选择弹窗添加商品完成: ${widget.dish.name} x$quantity',
        tag: 'SpecModal',
      );

      Navigator.of(context).pop();
      // 移除本地成功提示，等待服务器确认后再显示
    } else {
      GlobalToast.error('${context.l10n.pleaseSelect}$missingOptionName');
    }
  }
}
