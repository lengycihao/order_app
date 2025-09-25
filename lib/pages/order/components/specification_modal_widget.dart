import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:order_app/pages/order/model/dish.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/utils/toast_utils.dart';

/// 规格选择弹窗组件
class SpecificationModalWidget {
  /// 显示规格选择弹窗
  static void showSpecificationModal(BuildContext context, Dish dish) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6, // 使用屏幕高度的60%
          child: _SpecificationModalContent(dish: dish),
        ),
      ),
    );
  }
}

/// 规格选择弹窗内容
class _SpecificationModalContent extends StatefulWidget {
  final Dish dish;

  const _SpecificationModalContent({Key? key, required this.dish})
    : super(key: key);

  @override
  State<_SpecificationModalContent> createState() =>
      _SpecificationModalContentState();
}

class _SpecificationModalContentState
    extends State<_SpecificationModalContent> {
  Map<int, List<int>> selectedOptions = {}; // 规格ID -> 选中的选项ID列表
  int quantity = 1;
  double totalPrice = 0;
  late TextEditingController _quantityController;
  late FocusNode _quantityFocusNode;

  @override
  void initState() {
    super.initState();
    totalPrice = widget.dish.price;
    _quantityController = TextEditingController(text: '$quantity');
    _quantityFocusNode = FocusNode();
    
    // 监听焦点变化，处理键盘抬起时的偏移和光标释放
    _quantityFocusNode.addListener(() {
      if (_quantityFocusNode.hasFocus) {
        // 键盘弹起时，延迟一点时间让弹窗向上偏移
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            // 滚动到输入框位置，确保不被键盘遮挡
            Scrollable.ensureVisible(
              _quantityFocusNode.context!,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      } else {
        // 焦点丢失时，确保光标完全释放
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // 强制清除焦点，确保光标消失
            FocusScope.of(context).unfocus();
            _quantityFocusNode.unfocus();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _quantityFocusNode.dispose();
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
        children: [
          // 标题栏
          Container(
            padding: EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.dish.name,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Icon(Icons.close, size: 24, color: Color(0xff666666)),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          // 可滚动的内容区域
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: 16, bottom: 16),

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
                      SizedBox(height: 10),
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
          '敏感物',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xff666666),
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: widget.dish.allergens!.map((allergen) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (allergen.icon != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: allergen.icon!,
                      width: 16,
                      height: 16,
                      errorWidget: (context, url, error) =>
                          Icon(Icons.warning, size: 16, color: Colors.orange),
                    ),
                  ),
                if (allergen.icon != null) SizedBox(width: 4),
                Text(
                  allergen.label ?? '',
                  style: TextStyle(fontSize: 12, color: Color(0xff3D3D3D)),
                ),
              ],
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
                    fontWeight: FontWeight.bold,
                    color: Color(0xff666666),
                  ),
                ),
                SizedBox(height: 8),
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
                selectedOptions[option.id]!.remove(item.id);
              } else {
                selectedOptions[option.id]!.add(item.id!);
              }
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                fontSize: 14,
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
              selectedOptions[option.id!] = [item.id!];
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                fontSize: 14,
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
    return Text(
      '已选规格: ${_getSelectedSpecsText()}',
      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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

  /// 从输入框更新数量
  void _updateQuantityFromInput(String value) {
    final inputValue = int.tryParse(value);
    if (inputValue != null && inputValue > 0) {
      setState(() {
        quantity = inputValue;
        _quantityController.text = '$quantity';
      });
    } else {
      // 输入无效，恢复原值
      _quantityController.text = '$quantity';
      GlobalToast.error('请输入有效的数量');
    }
  }

  /// 构建底部区域（数量选择 + 购物车按钮）
  Widget _buildBottomSection() {
    return Container(
       padding: EdgeInsets.only(bottom: 15),
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
                '数量',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
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
                            _quantityController.text = '$quantity';
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
                    // 数字显示区域 - 可编辑输入框
                    Container(
                      width: 32,
                      height: 24,
                      color: Colors.white,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            _quantityFocusNode.requestFocus();
                          },
                          child: TextField(
                            controller: _quantityController,
                            focusNode: _quantityFocusNode,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                              alignLabelWithHint: true,
                            ),
                            cursorColor: Colors.black54,
                            showCursor: true,
                            enableInteractiveSelection: false,
                            onSubmitted: (value) {
                              _updateQuantityFromInput(value);
                              // 提交后释放焦点
                              _quantityFocusNode.unfocus();
                              FocusScope.of(context).unfocus();
                            },
                            onChanged: (value) {
                              // 实时更新显示，但只在提交时验证
                            },
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
                          _quantityController.text = '$quantity';
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
          ), SizedBox(height: 10),Divider(height: 1, color: Colors.grey.shade200), SizedBox(height: 10),
          if (selectedOptions.isNotEmpty) ...[
                      _buildSelectedSpecsText(),
                    ],

          SizedBox(height: 10),
          // 价格和购物车按钮
          Row(
            children: [
              Text(
                '￥',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
              Text(
                totalPrice.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Spacer(),

              GestureDetector(
                onTap: _addToCart,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+购物车',
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
      }
    }

    if (missingOptionName == null) {
      // 添加到购物车
      final controller = Get.find<OrderController>();
      
      // 构建选择的规格选项 - 直接传递optionId和itemIds
      Map<String, List<String>> selectedOptionsMap = {};
      selectedOptions.forEach((optionId, selectedItemIds) {
        if (selectedItemIds.isNotEmpty) {
          // 直接使用optionId作为key，itemIds作为value
          selectedOptionsMap[optionId.toString()] = selectedItemIds.map((id) => id.toString()).toList();
        }
      });
      
      for (int i = 0; i < quantity; i++) {
        controller.addToCart(widget.dish, selectedOptions: selectedOptionsMap);
      }
      Navigator.of(context).pop();
      // 移除本地成功提示，等待服务器确认后再显示
    } else {
      GlobalToast.error('请选择$missingOptionName');
    }
  }
}
