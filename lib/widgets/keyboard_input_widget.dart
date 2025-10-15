import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 键盘顶部输入框组件
class KeyboardInputWidget extends StatefulWidget {
  final String initialValue;
  final String hintText;
  final Function(String) onConfirm;
  final VoidCallback? onCancel;
  final TextInputType keyboardType;
  final int? maxLength;
  final String? dishName; // 添加菜品名称参数

  const KeyboardInputWidget({
    Key? key,
    required this.initialValue,
    required this.hintText,
    required this.onConfirm,
    this.onCancel,
    this.keyboardType = TextInputType.number,
    this.maxLength,
    this.dishName, // 菜品名称
  }) : super(key: key);

  @override
  State<KeyboardInputWidget> createState() => _KeyboardInputWidgetState();
}

class _KeyboardInputWidgetState extends State<KeyboardInputWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    
    // 延迟聚焦，确保组件完全构建后再请求焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted && _focusNode.canRequestFocus) {
          _focusNode.requestFocus();
          _controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controller.text.length,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) {
      widget.onConfirm(value);
    } else {
      widget.onCancel?.call();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.white, width: 0.5),
        ),
         
      ),
      child: Row(
        children: [
          // 菜品名称（如果有）
          if (widget.dishName != null) ...[
            Container(
              constraints: BoxConstraints(maxWidth: 120),
              child: Text(
                widget.dishName!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none, // 移除下划线
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(width: 8),
          ],
          // 输入框
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                 border: Border.all(color: Colors.grey.shade300),
                 borderRadius: BorderRadius.circular(5)
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: widget.keyboardType,
                maxLength: widget.maxLength,
                obscureText: true, // 改为密码输入框
                inputFormatters: widget.keyboardType == TextInputType.number
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 16,
                    decoration: TextDecoration.none, // 移除下划线
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  counterText: '', // 隐藏字符计数
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  decoration: TextDecoration.none, // 移除下划线
                ),
                textAlign: TextAlign.center,
                onSubmitted: (_) => _handleConfirm(),
              ),
            ),
          ),
          SizedBox(width: 12),
          // 确认按钮
          GestureDetector(
            onTap: _handleConfirm,
            child: Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                child: Text(
                  '确认',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none, // 移除下划线
                    height: 1.0, // 设置行高为1，去掉上下边距
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 键盘输入管理器
class KeyboardInputManager with WidgetsBindingObserver {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;
  static KeyboardInputManager? _instance;
  static double _lastKeyboardHeight = 0;
  static DateTime? _lastKeyboardCheck;

  /// 显示键盘输入框
  static void show({
    required BuildContext context,
    required String initialValue,
    required String hintText,
    required Function(String) onConfirm,
    VoidCallback? onCancel,
    TextInputType keyboardType = TextInputType.number,
    int? maxLength,
    String? dishName, // 添加菜品名称参数
  }) {
    if (_isShowing) {
      hide();
    }

    _isShowing = true;
    
    // 重置键盘高度记录
    _lastKeyboardHeight = 0;
    
    // 初始化单例并添加键盘监听
    _instance ??= KeyboardInputManager();
    WidgetsBinding.instance.addObserver(_instance!);
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: KeyboardInputWidget(
          initialValue: initialValue,
          hintText: hintText,
          onConfirm: (value) {
            onConfirm(value);
            hide();
          },
          onCancel: () {
            onCancel?.call();
            hide();
          },
          keyboardType: keyboardType,
          maxLength: maxLength,
          dishName: dishName, // 传递菜品名称
        ),
      ),
    );

    final overlay = Overlay.maybeOf(context);
    if (overlay != null) {
      overlay.insert(_overlayEntry!);
    } else {
      print('⚠️ [KeyboardInput] 未找到Overlay widget，无法显示键盘输入框');
    }
  }

  /// 隐藏键盘输入框
  static void hide() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _isShowing = false;
    
    // 移除键盘监听
    if (_instance != null) {
      WidgetsBinding.instance.removeObserver(_instance!);
    }
  }

  /// 检查是否正在显示
  static bool get isShowing => _isShowing;
  
  /// 监听键盘状态变化
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    
    // 防抖机制：避免频繁检查
    final now = DateTime.now();
    if (_lastKeyboardCheck != null && 
        now.difference(_lastKeyboardCheck!).inMilliseconds < 100) {
      return;
    }
    _lastKeyboardCheck = now;
    
    // 检查键盘是否收起
    final keyboardHeight = WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    
    // 只有当键盘高度真正发生变化且从有高度变为0时才隐藏
    if (keyboardHeight == 0 && _lastKeyboardHeight > 0 && _isShowing) {
      // 延迟隐藏，确保键盘完全收起
      Future.delayed(Duration(milliseconds: 50), () {
        if (_isShowing) {
          hide();
        }
      });
    }
    
    _lastKeyboardHeight = keyboardHeight;
  }
}
