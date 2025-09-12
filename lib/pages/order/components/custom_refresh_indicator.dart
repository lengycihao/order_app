import 'package:flutter/material.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';

/// 自定义下拉刷新组件，使用RestaurantLoadingWidget动画
class CustomRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final double displacement;
  final Color? color;
  final Color? backgroundColor;

  const CustomRefreshIndicator({
    Key? key,
    required this.child,
    required this.onRefresh,
    this.displacement = 40.0,
    this.color,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<CustomRefreshIndicator> createState() => _CustomRefreshIndicatorState();
}

class _CustomRefreshIndicatorState extends State<CustomRefreshIndicator> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: widget.color ?? Colors.orange,
      backgroundColor: widget.backgroundColor ?? Colors.white,
      strokeWidth: 2.0,
      displacement: widget.displacement,
      child: Stack(
        children: [
          widget.child,
          if (_isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: widget.displacement,
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: RestaurantLoadingWidget(
                    size: 30,
                    color: widget.color ?? Colors.orange,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 自定义可刷新的ListView
class CustomRefreshableListView extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function() onRefresh;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final double displacement;
  final Color? color;
  final Color? backgroundColor;

  const CustomRefreshableListView({
    Key? key,
    required this.children,
    required this.onRefresh,
    this.padding,
    this.physics,
    this.displacement = 40.0,
    this.color,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      displacement: displacement,
      color: color,
      backgroundColor: backgroundColor,
      child: ListView(
        padding: padding,
        physics: physics ?? AlwaysScrollableScrollPhysics(),
        children: children,
      ),
    );
  }
}

/// 自定义可刷新的ListView.builder
class CustomRefreshableListViewBuilder extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Future<void> Function() onRefresh;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final double displacement;
  final Color? color;
  final Color? backgroundColor;

  const CustomRefreshableListViewBuilder({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onRefresh,
    this.padding,
    this.physics,
    this.displacement = 40.0,
    this.color,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      displacement: displacement,
      color: color,
      backgroundColor: backgroundColor,
      child: ListView.builder(
        padding: padding,
        physics: physics ?? AlwaysScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }
}
