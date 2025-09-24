import 'package:flutter/material.dart';

/// 通用骨架图组件
class SkeletonWidget extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration animationDuration;

  const SkeletonWidget({
    Key? key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
    this.animationDuration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<SkeletonWidget> createState() => _SkeletonWidgetState();
}

class _SkeletonWidgetState extends State<SkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor ?? const Color(0xFFE0E0E0),
                widget.highlightColor ?? const Color(0xFFF5F5F5),
                widget.baseColor ?? const Color(0xFFE0E0E0),
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// 骨架图占位符组件
class SkeletonPlaceholder extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const SkeletonPlaceholder({
    Key? key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.margin,
    this.padding,
  }) : super(key: key);

  @override
  State<SkeletonPlaceholder> createState() => _SkeletonPlaceholderState();
}

class _SkeletonPlaceholderState extends State<SkeletonPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFFE0E0E0),
                  const Color(0xFFF5F5F5),
                  const Color(0xFFE0E0E0),
                ],
                stops: [
                  _animation.value - 0.3,
                  _animation.value,
                  _animation.value + 0.3,
                ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
              ).createShader(bounds);
            },
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 点餐页面骨架图
class OrderPageSkeleton extends StatelessWidget {
  const OrderPageSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧分类骨架
        _buildCategorySkeleton(),
        // 右侧菜品列表骨架
        _buildDishListSkeleton(),
      ],
    );
  }

  /// 构建分类骨架
  Widget _buildCategorySkeleton() {
    return Container(
      width: 72,
      color: Colors.grey.shade50,
      child: Column(
        children: List.generate(6, (index) => _buildCategoryItemSkeleton()),
      ),
    );
  }

  /// 构建分类项骨架
  Widget _buildCategoryItemSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          SkeletonPlaceholder(
            height: 20,
            width: 40,
            borderRadius: 4,
          ),
          const SizedBox(height: 4),
          SkeletonPlaceholder(
            height: 12,
            width: 30,
            borderRadius: 6,
          ),
        ],
      ),
    );
  }

  /// 构建菜品列表骨架
  Widget _buildDishListSkeleton() {
    return Expanded(
      child: Container(
        color: Colors.white,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 8, // 显示8个菜品骨架
          itemBuilder: (context, index) => _buildDishItemSkeleton(),
        ),
      ),
    );
  }

  /// 构建菜品项骨架
  Widget _buildDishItemSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // 菜品图片骨架
          SkeletonPlaceholder(
            width: 80,
            height: 80,
            borderRadius: 8,
          ),
          const SizedBox(width: 12),
          // 菜品信息骨架
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonPlaceholder(
                  height: 18,
                  margin: const EdgeInsets.only(bottom: 8),
                ),
                SkeletonPlaceholder(
                  height: 14,
                  width: 120,
                  margin: const EdgeInsets.only(bottom: 8),
                ),
                SkeletonPlaceholder(
                  height: 14,
                  width: 80,
                  margin: const EdgeInsets.only(bottom: 8),
                ),
                // 使用Wrap替代Row，避免溢出
                Wrap(
                  spacing: 8,
                  children: [
                    SkeletonPlaceholder(
                      height: 12,
                      width: 40,
                    ),
                    SkeletonPlaceholder(
                      height: 12,
                      width: 60,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 价格和按钮骨架 - 使用Flexible包装
          Flexible(
            child: SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SkeletonPlaceholder(
                    height: 18,
                    width: 60,
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    children: [
                      SkeletonPlaceholder(
                        height: 28,
                        width: 28,
                        borderRadius: 14,
                      ),
                      SkeletonPlaceholder(
                        height: 20,
                        width: 20,
                        borderRadius: 10,
                      ),
                      SkeletonPlaceholder(
                        height: 28,
                        width: 28,
                        borderRadius: 14,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 外卖页面骨架图
class TakeawayPageSkeleton extends StatelessWidget {
  const TakeawayPageSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 搜索框骨架
          SkeletonPlaceholder(
            height: 40,
            borderRadius: 20,
            margin: const EdgeInsets.only(bottom: 16),
          ),
          
          // 订单列表骨架
          ...List.generate(4, (index) => _buildOrderItemSkeleton()),
        ],
      ),
    );
  }

  Widget _buildOrderItemSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 订单头部
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonPlaceholder(
                height: 16,
                width: 100,
              ),
              SkeletonPlaceholder(
                height: 16,
                width: 80,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 订单信息
          SkeletonPlaceholder(
            height: 14,
            width: 200,
            margin: const EdgeInsets.only(bottom: 8),
          ),
          SkeletonPlaceholder(
            height: 14,
            width: 150,
            margin: const EdgeInsets.only(bottom: 8),
          ),
          SkeletonPlaceholder(
            height: 14,
            width: 120,
          ),
        ],
      ),
    );
  }
}

/// 已点页面骨架图 - 简化版
class OrderedPageSkeleton extends StatelessWidget {
  const OrderedPageSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 只显示2个订单项骨架，减少视觉负担
          ...List.generate(2, (index) => _buildOrderItemSkeleton()),
        ],
      ),
    );
  }

  Widget _buildOrderItemSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 简化的订单头部 - 只保留一个标题
          SkeletonPlaceholder(
            height: 18,
            width: 120,
            borderRadius: 4,
          ),
          const SizedBox(height: 16),
          
          // 简化的订单信息 - 只显示2行
          SkeletonPlaceholder(
            height: 14,
            width: 180,
            margin: const EdgeInsets.only(bottom: 12),
            borderRadius: 4,
          ),
          SkeletonPlaceholder(
            height: 14,
            width: 140,
            margin: const EdgeInsets.only(bottom: 16),
            borderRadius: 4,
          ),
          
          // 简化的菜品列表 - 只显示1个菜品
          _buildDishItemSkeleton(),
        ],
      ),
    );
  }

  Widget _buildDishItemSkeleton() {
    return Row(
      children: [
        SkeletonPlaceholder(
          height: 14,
          width: 24,
          borderRadius: 6,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SkeletonPlaceholder(
            height: 14,
            width: 100,
            borderRadius: 4,
          ),
        ),
        SkeletonPlaceholder(
          height: 14,
          width: 50,
          borderRadius: 4,
        ),
      ],
    );
  }
}

/// 购物车骨架图
class CartSkeleton extends StatelessWidget {
  const CartSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 购物车项骨架
          ...List.generate(3, (index) => _buildCartItemSkeleton()),
          
          const SizedBox(height: 16),
          
          // 总计骨架
          _buildTotalSkeleton(),
        ],
      ),
    );
  }

  Widget _buildCartItemSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          SkeletonPlaceholder(
            width: 60,
            height: 60,
            borderRadius: 8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonPlaceholder(
                  height: 16,
                  margin: const EdgeInsets.only(bottom: 4),
                ),
                SkeletonPlaceholder(
                  height: 14,
                  width: 80,
                  margin: const EdgeInsets.only(bottom: 4),
                ),
                SkeletonPlaceholder(
                  height: 14,
                  width: 60,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkeletonPlaceholder(
                height: 16,
                width: 50,
                margin: const EdgeInsets.only(bottom: 8),
              ),
              Row(
                children: [
                  SkeletonPlaceholder(
                    height: 24,
                    width: 24,
                    borderRadius: 12,
                  ),
                  const SizedBox(width: 8),
                  SkeletonPlaceholder(
                    height: 16,
                    width: 20,
                  ),
                  const SizedBox(width: 8),
                  SkeletonPlaceholder(
                    height: 24,
                    width: 24,
                    borderRadius: 12,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SkeletonPlaceholder(
            height: 18,
            width: 80,
          ),
          SkeletonPlaceholder(
            height: 18,
            width: 100,
          ),
        ],
      ),
    );
  }
}

/// 桌台页面骨架图
class TablePageSkeleton extends StatelessWidget {
  const TablePageSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab骨架
          SkeletonPlaceholder(
            height: 40,
            margin: const EdgeInsets.only(bottom: 16),
          ),
          
          // 桌台网格骨架
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 13,
              childAspectRatio: 1.2,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => _buildTableCardSkeleton(),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 1),
            blurRadius: 3,
            color: const Color(0x33000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 桌台信息
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonPlaceholder(
                  height: 16,
                  width: 60,
                ),
                SkeletonPlaceholder(
                  height: 12,
                  width: 40,
                ),
              ],
            ),
          ),
          
          // 金额信息
          Expanded(
            child: Center(
              child: SkeletonPlaceholder(
                height: 16,
                width: 80,
              ),
            ),
          ),
          
          // 状态栏
          Container(
            height: 23,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE4E4E4),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonPlaceholder(
                  height: 12,
                  width: 60,
                ),
                SkeletonPlaceholder(
                  height: 12,
                  width: 40,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}