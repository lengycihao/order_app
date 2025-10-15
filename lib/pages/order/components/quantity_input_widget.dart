import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/order/order_element/models.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/utils/modal_utils.dart';

/// 可点击数量输入组件
class QuantityInputWidget extends StatefulWidget {
  final CartItem cartItem;
  final int currentQuantity;
  final VoidCallback? onQuantityChanged;
  final bool isInCartModal;
  final Function(CartItem, int)? onStartEditing;

  const QuantityInputWidget({
    Key? key,
    required this.cartItem,
    required this.currentQuantity,
    this.onQuantityChanged,
    this.isInCartModal = false,
    this.onStartEditing,
  }) : super(key: key);

  @override
  State<QuantityInputWidget> createState() => _QuantityInputWidgetState();
}

class _QuantityInputWidgetState extends State<QuantityInputWidget> {
  bool _isEditing = false;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController.text = widget.currentQuantity.toString();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 开始编辑
  void _startEditing() {
    if (_isEditing || !mounted) return;
    
    if (widget.isInCartModal) {
      // 在购物车弹窗中，直接显示键盘输入
      _showKeyboardInput();
    } else {
      // 在普通页面中，通过回调通知父组件显示键盘输入组件
      setState(() {
        _isEditing = true;
      });
      
      if (widget.onStartEditing != null) {
        widget.onStartEditing!(widget.cartItem, widget.currentQuantity);
      }
    }
  }

  /// 显示键盘输入
  void _showKeyboardInput() {
    _textController.text = widget.currentQuantity.toString();
    
    // 显示键盘输入组件，紧贴键盘顶部
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildKeyboardInputBottomSheet(),
    );
  }

  /// 构建键盘输入底部弹窗
  Widget _buildKeyboardInputBottomSheet() {
    return StatefulBuilder(
      builder: (context, setState) {
        // 自动聚焦到输入框
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey[300]!, width: 0.5),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Row(
              children: [
                // 数量标签
                const Text(
                  '数量:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 12),
                
                // 数量输入框
                Container(
                  width: 80,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      // 实时更新数量
                      final quantity = int.tryParse(value) ?? 1;
                      if (quantity > 0) {
                        _updateQuantity(quantity);
                      }
                    },
                    onSubmitted: (value) => _confirmInput(),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // 取消按钮
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                
                const SizedBox(width: 8),
                
                // 确认按钮
                ElevatedButton(
                  onPressed: _confirmInput,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                  child: const Text(
                    '确认',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 确认输入
  void _confirmInput() {
    final inputText = _textController.text.trim();
    final newQuantity = int.tryParse(inputText);
    
    // 验证输入
    if (newQuantity == null || newQuantity < 0) {
      _showInvalidInputDialog();
      return;
    }
    
    if (newQuantity == widget.currentQuantity) {
      // 数量没有变化，直接关闭
      Navigator.of(context).pop();
      return;
    }
    
    if (newQuantity == 0) {
      // 数量为0，删除商品
      _showDeleteConfirmDialog();
      return;
    }
    
    // 执行数量更新
    _updateQuantity(newQuantity);
  }

  /// 更新数量
  void _updateQuantity(int newQuantity) {
    final controller = Get.find<OrderController>();
    
    // 直接设置目标数量
    controller.updateCartItemQuantity(
      cartItem: widget.cartItem,
      newQuantity: newQuantity,
      onSuccess: () {
        // 刷新UI
        if (widget.onQuantityChanged != null) {
          widget.onQuantityChanged!();
        }
        Navigator.of(context).pop();
      },
      onError: (code, message) {
        // 显示错误信息
        ModalUtils.showAlertDialog(
          context: context,
          message: '更新数量失败: $message',
          confirmText: '确定',
        );
      },
    );
  }

  /// 显示无效输入对话框
  void _showInvalidInputDialog() {
    ModalUtils.showAlertDialog(
      context: context,
      message: '输入无效\n请输入有效的数量',
      confirmText: '确定',
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog() {
    ModalUtils.showConfirmDialog(
      context: context,
      message: '是否删除菜品？',
      confirmText: '删除',
      cancelText: '取消',
      confirmColor: Colors.red,
      onConfirm: () {
        _deleteItem();
      },
    );
  }

  /// 删除商品
  void _deleteItem() {
    final controller = Get.find<OrderController>();
    controller.removeFromCart(widget.cartItem);
    
    // 刷新UI
    if (widget.onQuantityChanged != null) {
      widget.onQuantityChanged!();
    }
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _startEditing,
      child: Text(
        '${widget.currentQuantity}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }
}