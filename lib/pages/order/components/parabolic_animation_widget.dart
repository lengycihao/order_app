import 'package:flutter/material.dart';

/// 抛物线动画组件
/// 实现从起始点到目标点的抛物线飞行动画，模拟主流点餐应用的加购动画效果
class ParabolicAnimationWidget extends StatefulWidget {
  /// 起始位置（全局坐标）
  final Offset startPosition;
  /// 目标位置（全局坐标） 
  final Offset targetPosition;
  /// 动画时长
  final Duration duration;
  /// 动画完成回调
  final VoidCallback? onAnimationComplete;
  /// 飞行的元素（通常是一个圆点或小图标）
  final Widget child;

  const ParabolicAnimationWidget({
    Key? key,
    required this.startPosition,
    required this.targetPosition,
    this.duration = const Duration(milliseconds: 1000), // 延长时间让抛物线更明显
    this.onAnimationComplete,
    required this.child,
  }) : super(key: key);

  @override
  State<ParabolicAnimationWidget> createState() => _ParabolicAnimationWidgetState();
}

class _ParabolicAnimationWidgetState extends State<ParabolicAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // 使用抛物线动画曲线 - 更适合抛物线运动的曲线
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut, // 模拟重力影响，开始快后面慢
    );

    // 抛物线路径通过_calculateParabolicPosition方法计算，不需要单独的动画

    // 缩放动画：开始时正常大小，结束时缩小消失
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));

    // 透明度动画：在最后阶段淡出
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
    ));

    // 监听动画完成
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });

    // 开始动画
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 计算抛物线位置 - 从左上角抛出的真实抛物线效果
  Offset _calculateParabolicPosition(double t) {
    // 水平方向：匀速运动
    final dx = widget.startPosition.dx + 
        (widget.targetPosition.dx - widget.startPosition.dx) * t;
    
    // 垂直方向：抛物线运动
    // 从起始点开始，先向上抛，然后受重力影响下降
    final startY = widget.startPosition.dy;
    final endY = widget.targetPosition.dy;
    
    // 计算抛物线高度：向上抛出约100像素的高度
    final throwHeight = 0.0;
    final peakY = startY - throwHeight; // 抛物线顶点比起始点高100像素
    
    // 使用二次函数模拟抛物线：y = a*t² + b*t + c
    // 在t=0时，y=startY；在t=0.5时，y=peakY；在t=1时，y=endY
    final a = 2 * (startY + endY - 2 * peakY);
    final b = 4 * peakY - 3 * startY - endY;
    final c = startY;
    
    final dy = a * t * t + b * t + c;
    
    return Offset(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final position = _calculateParabolicPosition(_animation.value);
        
        return Positioned(
          left: position.dx - 11, // 调整为widget中心
          top: position.dy - 11,  // 调整为widget中心
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// 抛物线动画管理器
/// 用于管理和触发抛物线动画，提供静态方法便于调用
class ParabolicAnimationManager {
  /// 触发加购抛物线动画 - 从左上角抛出的真实抛物线效果
  static void triggerAddToCartAnimation({
    required BuildContext context,
    required GlobalKey addButtonKey,
    required GlobalKey cartButtonKey,
    Duration duration = const Duration(milliseconds: 1000), // 稍微延长时间让抛物线更明显
    VoidCallback? onComplete,
  }) {
    // 获取起始位置（加号按钮）
    final RenderBox? addButtonBox = addButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (addButtonBox == null) return;
    
    final addButtonPosition = addButtonBox.localToGlobal(Offset.zero);
    // 从按钮左上角开始抛出，而不是中心点
    final addButtonStart = addButtonPosition + Offset(addButtonBox.size.width * 0.2, addButtonBox.size.height * 0.2);

    // 获取目标位置（购物车按钮）
    final RenderBox? cartButtonBox = cartButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (cartButtonBox == null) return;
    
    final cartButtonPosition = cartButtonBox.localToGlobal(Offset.zero);
    final cartButtonCenter = cartButtonPosition + Offset(cartButtonBox.size.width / 2, cartButtonBox.size.height / 2);

    // 创建飞行元素
    final flyingWidget = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.orange,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        Icons.add,
        color: Colors.white,
        size: 14,
      ),
    );

    // 获取overlay
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => ParabolicAnimationWidget(
        startPosition: addButtonStart,
        targetPosition: cartButtonCenter,
        duration: duration,
        onAnimationComplete: () {
          overlayEntry.remove();
          onComplete?.call();
        },
        child: flyingWidget,
      ),
    );

    overlay.insert(overlayEntry);
  }

  /// 触发规格选择的加购动画（针对选规格弹窗）
  static void triggerSpecificationAddAnimation({
    required BuildContext context,
    required GlobalKey addButtonKey,
    required GlobalKey cartButtonKey,
    Duration duration = const Duration(milliseconds: 800),
    VoidCallback? onComplete,
  }) {
    triggerAddToCartAnimation(
      context: context,
      addButtonKey: addButtonKey,
      cartButtonKey: cartButtonKey,
      duration: duration,
      onComplete: onComplete,
    );
  }

  /// 获取购物车按钮的GlobalKey（如果需要从外部获取）
  static GlobalKey<State<StatefulWidget>>? findCartButtonKey(BuildContext context) {
    // 这里可以实现从widget树中查找购物车按钮的逻辑
    // 暂时返回null，实际使用时需要传入正确的key
    return null;
  }
}
