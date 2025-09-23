import 'package:flutter/material.dart';

/// 统一的Toast提示组件
class ToastComponent extends StatelessWidget {
  final String message;
  final ToastType type;
  final double? width;
  final double? height;

  const ToastComponent({
    Key? key,
    required this.message,
    required this.type,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 270,
      height: height ?? 36,
      constraints: BoxConstraints(
        minHeight: 36,
        maxWidth: 270,
      ),
      decoration: BoxDecoration(
        color: type == ToastType.error ? const Color(0xFFFFF0F0) : const Color(0xFFF0FFF0),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图标
          Image.asset(
            type == ToastType.error ? 'assets/order_error.webp' : 'assets/order_success.webp',
            width: 16,
            height: 16,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          // 消息文本
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF333333),
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Toast类型枚举
enum ToastType {
  error,
  success,
}

/// Toast显示位置
enum ToastPosition {
  center,
  top,
  bottom,
}

/// Toast工具类
class ToastUtils {
  static OverlayEntry? _currentOverlay;
  static bool _isShowing = false;

  /// 显示错误提示
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    ToastPosition position = ToastPosition.center,
  }) {
    _showToast(
      context,
      message,
      ToastType.error,
      duration: duration,
      position: position,
    );
  }

  /// 显示成功提示
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    ToastPosition position = ToastPosition.center,
  }) {
    _showToast(
      context,
      message,
      ToastType.success,
      duration: duration,
      position: position,
    );
  }

  /// 显示Toast
  static void _showToast(
    BuildContext context,
    String message,
    ToastType type, {
    Duration duration = const Duration(seconds: 2),
    ToastPosition position = ToastPosition.center,
  }) {
    // 如果已经有Toast在显示，先隐藏
    if (_isShowing) {
      hide();
    }

    _isShowing = true;

    // 创建OverlayEntry
    _currentOverlay = OverlayEntry(
      builder: (context) => _ToastOverlay(
        message: message,
        type: type,
        position: position,
        onDismiss: () {
          hide();
        },
      ),
    );

    // 显示Toast
    Overlay.of(context).insert(_currentOverlay!);

    // 自动隐藏
    Future.delayed(duration, () {
      hide();
    });
  }

  /// 隐藏Toast
  static void hide() {
    if (_currentOverlay != null && _isShowing) {
      _currentOverlay!.remove();
      _currentOverlay = null;
      _isShowing = false;
    }
  }
}

/// Toast覆盖层组件
class _ToastOverlay extends StatefulWidget {
  final String message;
  final ToastType type;
  final ToastPosition position;
  final VoidCallback onDismiss;

  const _ToastOverlay({
    required this.message,
    required this.type,
    required this.position,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // 根据位置设置滑动动画
    switch (widget.position) {
      case ToastPosition.top:
        _slideAnimation = Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        ));
        break;
      case ToastPosition.bottom:
        _slideAnimation = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        ));
        break;
      case ToastPosition.center:
        _slideAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        ));
        break;
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 背景遮罩（点击隐藏）
          GestureDetector(
            onTap: () {
              _hideToast();
            },
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Toast内容
          Positioned(
            left: 0,
            right: 0,
            top: widget.position == ToastPosition.top
                ? MediaQuery.of(context).padding.top + 20
                : widget.position == ToastPosition.bottom
                    ? null
                    : null,
            bottom: widget.position == ToastPosition.bottom
                ? MediaQuery.of(context).padding.bottom + 20
                : null,
            child: Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: GestureDetector(
                        onTap: () {
                          _hideToast();
                        },
                        child: ToastComponent(
                          message: widget.message,
                          type: widget.type,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _hideToast() {
    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }
}
