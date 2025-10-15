import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/pages/order/order_element/models.dart';
import 'package:order_app/utils/modal_utils.dart';

/// 键盘上方的数量输入组件
class KeyboardQuantityInputWidget extends StatefulWidget {
  final CartItem cartItem;
  final int currentQuantity;
  final VoidCallback? onQuantityChanged;
  final VoidCallback? onDismiss;

  const KeyboardQuantityInputWidget({
    Key? key,
    required this.cartItem,
    required this.currentQuantity,
    this.onQuantityChanged,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<KeyboardQuantityInputWidget> createState() => _KeyboardQuantityInputWidgetState();
}

class _KeyboardQuantityInputWidgetState extends State<KeyboardQuantityInputWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController.text = widget.currentQuantity.toString();
    
    // 自动获取焦点并显示键盘
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
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
      _dismiss();
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
        _dismiss();
      },
      onError: (code, message) {
        // 显示错误信息
        _showInvalidInputDialog();
      },
    );
  }

  /// 显示无效输入对话框
  void _showInvalidInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('输入无效'),
        content: Text('请输入有效的数量'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _dismiss();
            },
            child: Text('确定'),
          ),
        ],
      ),
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
      onCancel: () {
        _dismiss();
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
    
    _dismiss();
  }

  /// 关闭输入组件
  void _dismiss() {
    _focusNode.unfocus();
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取键盘高度
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      bottom: keyboardHeight > 0 ? 0 : -100, // 键盘显示时在底部，隐藏时移出屏幕
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 菜品名字
            Container(
              width: 120,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.cartItem.dish.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 输入框
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  hintText: '请输入数量',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (value) => _confirmInput(),
              ),
            ),
            SizedBox(width: 16),
            // 确认按钮
            Container(
              width: 60,
              child: ElevatedButton(
                onPressed: _confirmInput,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '确认',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
