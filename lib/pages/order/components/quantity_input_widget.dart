import 'package:flutter/material.dart';
import 'package:order_app/pages/order/order_element/models.dart';
import 'package:order_app/pages/order/components/keyboard_quantity_input_widget.dart';

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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 开始编辑
  void _startEditing() {
    if (_isEditing || !mounted) return;
    
    setState(() {
      _isEditing = true;
    });
    
    // 通过回调通知父组件显示键盘输入组件
    if (widget.onStartEditing != null) {
      widget.onStartEditing!(widget.cartItem, widget.currentQuantity);
    }
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
