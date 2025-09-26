import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';

/// 基于餐厅loading动画的自定义下拉刷新指示器
class RestaurantRefreshIndicator extends StatefulWidget {
  final Widget child;
  final IndicatorController? controller;
  final Future<void> Function() onRefresh;
  final double? offsetToArmed;
  final Color? loadingColor;

  const RestaurantRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.controller,
    this.offsetToArmed,
    this.loadingColor,
  });

  @override
  State<RestaurantRefreshIndicator> createState() => _RestaurantRefreshIndicatorState();
}

class _RestaurantRefreshIndicatorState extends State<RestaurantRefreshIndicator>
    with TickerProviderStateMixin {
  static const _indicatorSize = 70.0; // 优化回弹位置：动画组件高度(60) + 上下边距(10)
  static const _loadingSize = 60.0;

  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late AnimationController _completionController;
  late AnimationController _iconTransitionController;
  
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _completionAnimation;

  @override
  void initState() {
    super.initState();
    
    // 旋转动画控制器 - 延长持续时间
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // 脉冲动画控制器
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // 缩放动画控制器
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // 完成动画控制器 - 用于刷新完成后的反馈
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 1200), // 延长到1.2秒，更明显
      vsync: this,
    );
    
    // 图标切换动画控制器
    _iconTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300), // 图标切换动画
      vsync: this,
    );
    
    // 旋转动画
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // 脉冲动画
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // 完成动画 - 用于刷新完成后的视觉反馈
    _completionAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3, // 适度的放大效果
    ).animate(CurvedAnimation(
      parent: _completionController,
      curve: Curves.elasticOut, // 使用弹性效果
    ));
    
    
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    _completionController.dispose();
    _iconTransitionController.dispose();
    super.dispose();
  }

  /// 带最小持续时间的刷新方法
  Future<void> _onRefreshWithMinDuration() async {
    final startTime = DateTime.now();
    
    // 执行实际的刷新操作
    await widget.onRefresh();
    
    // 计算已经过去的时间
    final elapsed = DateTime.now().difference(startTime);
    
    // 确保最小持续时间为2秒（1秒动画 + 1.2秒完成动画）
    const minDuration = Duration(milliseconds: 2000);
    
    if (elapsed < minDuration) {
      final remaining = minDuration - elapsed;
      await Future.delayed(remaining);
    }
  }

  /// 显示完成动画
  void _showCompletionAnimation() {
    if (!mounted) return;
    
    // 先切换图标到完成状态
    _iconTransitionController.forward().then((_) {
      if (mounted) {
        // 图标切换完成后，播放完成动画
        _completionController.forward().then((_) {
          if (mounted) {
            // 完成动画播放完后，延迟一下再隐藏，让用户感受到完成
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _scaleController.reverse();
                _completionController.reset();
                _iconTransitionController.reset();
              }
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      controller: widget.controller,
      offsetToArmed: widget.offsetToArmed ?? _indicatorSize,
      onRefresh: _onRefreshWithMinDuration,
      autoRebuild: false,
      child: widget.child,
      onStateChanged: (change) {
        if (change.didChange(to: IndicatorState.loading)) {
          // 开始加载动画，从当前角度开始旋转
          _rotationController.value = 0.0; // 重置到0，但会从0.5开始显示
          _rotationController.repeat();
          _pulseController.repeat(reverse: true);
          _scaleController.forward();
          
          // 1秒后停止旋转并显示完成动画
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              _rotationController.stop();
              _pulseController.stop();
              _showCompletionAnimation();
            }
          });
        } else if (change.didChange(to: IndicatorState.idle)) {
          // 重置所有动画
          _rotationController.reset();
          _pulseController.reset();
          _scaleController.value = 0.0;
          _completionController.reset();
          _iconTransitionController.reset();
        }
      },
      builder: (
        BuildContext context,
        Widget child,
        IndicatorController controller,
      ) {
        return Stack(
          children: <Widget>[
            // 自定义刷新指示器
            AnimatedBuilder(
              animation: Listenable.merge([controller, _rotationController, _pulseController, _scaleController, _completionController, _iconTransitionController]),
              builder: (BuildContext context, Widget? _) {
                // 计算下拉进度
                final progress = controller.value.clamp(0.0, 1.0);
                
                // 根据下拉进度计算动画参数
                final isDragging = controller.state == IndicatorState.dragging;
                final isArmed = controller.state == IndicatorState.armed;
                final isLoading = controller.state == IndicatorState.loading;
                final isCompleting = _completionController.isAnimating;
                final isIconTransitioning = _iconTransitionController.isAnimating;
                
                // 下拉时的动画参数
                double opacity = 0.0;
                double scale = 0.0;
                double rotation = 0.0;
                double pulse = 1.0;
                
                if (isDragging) {
                  // 下拉时：根据进度逐帧显示
                  opacity = (progress * 2.0).clamp(0.0, 1.0);
                  scale = (progress * 1.5).clamp(0.0, 1.0);
                  rotation = progress * 0.5; // 下拉时轻微旋转
                } else if (isArmed) {
                  // 准备刷新时：完全显示，为加载状态做准备
                  opacity = 1.0;
                  scale = 1.0;
                  rotation = 0.5; // 保持与下拉时一致的旋转角度
                } else if (isLoading) {
                  // 加载时：平滑过渡到动画状态
                  opacity = 1.0;
                  scale = 1.0;
                  // 从0.5开始，然后持续旋转，避免跳跃
                  rotation = 0.5 + _rotationAnimation.value;
                  pulse = _pulseAnimation.value;
                } else if (isIconTransitioning || isCompleting) {
                  // 图标切换或完成时：播放完成反馈动画
                  opacity = 1.0;
                  scale = isCompleting ? _completionAnimation.value : 1.0;
                  rotation = 0.5; // 保持最后的角度
                  pulse = 1.0;
                } else {
                  // 其他状态：使用缩放控制器的值
                  opacity = _scaleController.value;
                  scale = _scaleController.value;
                  rotation = 0.0;
                  pulse = 1.0;
                }
                
                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: controller.value * _indicatorSize,
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale * pulse,
                        child: Transform.rotate(
                          angle: rotation * 2 * 3.14159,
                          child: _buildRestaurantIcon(isIconTransitioning || isCompleting),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // 内容区域
            AnimatedBuilder(
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(0.0, controller.value * _indicatorSize),
                  child: child,
                );
              },
              animation: controller,
            ),
          ],
        );
      },
    );
  }

  /// 构建餐厅图标
  Widget _buildRestaurantIcon([bool isCompleted = false]) {
    return Container(
      width: _loadingSize,
      height: _loadingSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            (widget.loadingColor ?? const Color(0xFFFF9027)).withOpacity(0.3),
            (widget.loadingColor ?? const Color(0xFFFF9027)).withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: Container(
            key: ValueKey(isCompleted),
            width: _loadingSize * 0.6,
            height: _loadingSize * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted 
                ? Colors.green 
                : (widget.loadingColor ?? const Color(0xFFFF9027)),
              boxShadow: [
                BoxShadow(
                  color: (isCompleted 
                    ? Colors.green 
                    : (widget.loadingColor ?? const Color(0xFFFF9027))).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: isCompleted 
              ? Transform.rotate(
                  angle: 1.2217, // 70度 = 90度 - 20度，逆时针调整20度
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: _loadingSize * 0.3,
                  ),
                )
              : Icon(
                  Icons.restaurant,
                  color: Colors.white,
                  size: _loadingSize * 0.3,
                ),
          ),
        ),
      ),
    );
  }
}
