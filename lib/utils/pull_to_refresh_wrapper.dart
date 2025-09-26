import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';

class PullToRefreshWrapper extends StatelessWidget {
  final Widget child;
  final Future<void> Function()? onRefresh;
  final RefreshController? controller;

  const PullToRefreshWrapper({
    Key? key,
    required this.child,
    this.onRefresh,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      controller: controller ?? RefreshController(),
      enablePullDown: true, // 始终启用下拉刷新
      enablePullUp: false,
      physics: const AlwaysScrollableScrollPhysics(), // 确保始终可以滚动
      header: CustomHeader(
        builder: (context, mode) {
          Widget body;
          if (mode == RefreshStatus.idle) {
            // 空闲状态 - 显示箭头
            body = const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFFFF9027),
              size: 30,
            );
          } else if (mode == RefreshStatus.canRefresh) {
            // 可以刷新状态 - 显示向上箭头
            body = const Icon(
              Icons.keyboard_arrow_up,
              color: Color(0xFFFF9027),
              size: 30,
            );
          } else if (mode == RefreshStatus.refreshing) {
            // 刷新中状态 - 显示你的动画
            body = const RestaurantLoadingWidget();
          } else if (mode == RefreshStatus.completed) {
            // 刷新完成状态 - 显示勾选
            body = const Icon(
              Icons.check,
              color: Colors.green,
              size: 30,
            );
          } else {
            // 其他状态
            body = const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFFFF9027),
              size: 30,
            );
          }

          return Container(
            height: 60,
            alignment: Alignment.center,
            child: body,
          );
        },
      ),
      onRefresh: onRefresh,
      child: child,
    );
  }
}
