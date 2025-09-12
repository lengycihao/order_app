import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:order_app/pages/order/order_element/models.dart';
import 'package:order_app/utils/focus_manager.dart';

/// 可点击数量输入组件
class QuantityInputWidget extends StatefulWidget {
  final CartItem cartItem;
  final int currentQuantity;
  final VoidCallback? onQuantityChanged;
  final bool isInCartModal;

  const QuantityInputWidget({
    Key? key,
    required this.cartItem,
    required this.currentQuantity,
    this.onQuantityChanged,
    this.isInCartModal = false,
  }) : super(key: key);

  @override
  State<QuantityInputWidget> createState() => _QuantityInputWidgetState();
}

class _QuantityInputWidgetState extends State<QuantityInputWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;
  String _inputValue = '';

  @override
  void initState() {
    super.initState();
    _inputValue = widget.currentQuantity.toString();
    _textController.text = _inputValue;
    
    // 注册到全局焦点管理器
    GlobalFocusManager().registerQuantityInput(_focusNode);
    
    // 监听焦点变化
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        // 如果失去焦点，检查是否是用户主动提交
        if (_textController.text.trim().isNotEmpty) {
          _handleInputComplete();
        } else {
          // 如果输入为空，恢复到原值
          forceCancelEditing();
        }
      }
    });
  }

  @override
  void dispose() {
    // 从全局焦点管理器中注销
    GlobalFocusManager().unregisterQuantityInput(_focusNode);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(QuantityInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentQuantity != widget.currentQuantity) {
      _inputValue = widget.currentQuantity.toString();
      _textController.text = _inputValue;
    }
  }

  /// 开始编辑
  void _startEditing() {
    if (_isEditing || !mounted) return;
    
    setState(() {
      _isEditing = true;
      _inputValue = widget.currentQuantity.toString();
      _textController.text = _inputValue;
    });
    
    // 选中所有文本
    _textController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _textController.text.length,
    );
    
    // 显示键盘
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  /// 处理输入完成
  void _handleInputComplete() {
    if (!_isEditing || !mounted) return;
    
    final inputText = _textController.text.trim();
    final newQuantity = int.tryParse(inputText);
    
    // 验证输入
    if (newQuantity == null || newQuantity < 0) {
      _showInvalidInputDialog();
      return;
    }
    
    if (newQuantity == widget.currentQuantity) {
      // 数量没有变化，直接取消编辑
      _cancelEditing();
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
    
    // 收起键盘
    _focusNode.unfocus();
    
    // 执行WebSocket操作
    controller.updateCartItemQuantity(
      cartItem: widget.cartItem,
      newQuantity: newQuantity,
      onSuccess: () {
        _cancelEditing();
        widget.onQuantityChanged?.call();
      },
      onError: (code, message) {
        _cancelEditing();
        if (code == 409) {
          _showDoubleConfirmDialog(newQuantity);
        } else {
          _showErrorDialog(message);
        }
      },
    );
  }

  /// 取消编辑
  void _cancelEditing() {
    if (mounted) {
      setState(() {
        _isEditing = false;
        _inputValue = widget.currentQuantity.toString();
        _textController.text = _inputValue;
      });
    }
    _focusNode.unfocus();
  }

  /// 强制取消编辑并恢复原值
  void forceCancelEditing() {
    if (mounted) {
      setState(() {
        _isEditing = false;
        _inputValue = widget.currentQuantity.toString();
        _textController.text = _inputValue;
      });
    }
    _focusNode.unfocus();
  }

  /// 显示无效输入对话框
  void _showInvalidInputDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('输入无效'),
        content: Text('请输入有效的数量（非负整数）'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _cancelEditing();
            },
            child: Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('删除商品'),
        content: Text('确定要删除 "${widget.cartItem.dish.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _cancelEditing();
            },
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _deleteItem();
            },
            child: Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 删除商品
  void _deleteItem() {
    final controller = Get.find<OrderController>();
    controller.deleteCartItem(widget.cartItem);
    widget.onQuantityChanged?.call();
  }

  /// 显示二次确认对话框（409错误）
  void _showDoubleConfirmDialog(int newQuantity) {
    Get.dialog(
      AlertDialog(
        title: Text('操作冲突'),
        content: Text('检测到其他用户正在修改此商品，是否继续更新数量为 $newQuantity？'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _cancelEditing();
            },
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // 延迟执行更新，确保对话框完全关闭
              Future.delayed(Duration(milliseconds: 100), () {
                if (mounted) {
                  _updateQuantity(newQuantity);
                }
              });
            },
            child: Text('继续'),
          ),
        ],
      ),
    );
  }

  /// 显示错误对话框
  void _showErrorDialog(String message) {
    Get.dialog(
      AlertDialog(
        title: Text('操作失败'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _startEditing,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: _isEditing ? Colors.orange : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: _isEditing
            ? SizedBox(
                width: 40,
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done, // 设置键盘右下角为确认按钮
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onSubmitted: (value) {
                    _handleInputComplete();
                  },
                  onChanged: (value) {
                    _inputValue = value;
                  },
                ),
              )
            : Text(
                '${widget.currentQuantity}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _isEditing ? Colors.orange : Colors.black,
                ),
              ),
      ),
    );
  }
}
