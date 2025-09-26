import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// 智能刷新包装器
/// 提供统一的刷新样式和配置
class SmartRefreshWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Future<void> Function()? onLoading;
  final bool enablePullDown;
  final bool enablePullUp;
  final bool enableOverScroll;
  final Color? primaryColor;
  final Color? backgroundColor;

  const SmartRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.onLoading,
    this.enablePullDown = true,
    this.enablePullUp = false,
    this.enableOverScroll = true,
    this.primaryColor,
    this.backgroundColor,
  });

  @override
  State<SmartRefreshWrapper> createState() => _SmartRefreshWrapperState();
}

class _SmartRefreshWrapperState extends State<SmartRefreshWrapper> {
  late final RefreshController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController(initialRefresh: false);
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: widget.enablePullDown,
      enablePullUp: widget.enablePullUp,
      header: CustomHeader(
        builder: (context, mode) {
          Widget body;
          Color textColor = widget.primaryColor ?? const Color(0xFFFF9027);
          
          if (mode == RefreshStatus.idle) {
            body = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_arrow_down, color: textColor, size: 20),
                const SizedBox(width: 8),
                Text("下拉刷新", style: TextStyle(color: textColor, fontSize: 14)),
              ],
            );
          } else if (mode == RefreshStatus.refreshing) {
            body = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text("正在刷新...", style: TextStyle(color: textColor, fontSize: 14)),
              ],
            );
          } else if (mode == RefreshStatus.failed) {
            body = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text("刷新失败", style: TextStyle(color: Colors.red, fontSize: 14)),
              ],
            );
          } else if (mode == RefreshStatus.canRefresh) {
            body = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_arrow_up, color: textColor, size: 20),
                const SizedBox(width: 8),
                Text("释放刷新", style: TextStyle(color: textColor, fontSize: 14)),
              ],
            );
          } else {
            body = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text("刷新完成", style: TextStyle(color: Colors.green, fontSize: 14)),
              ],
            );
          }
          return Container(
            height: 60.0,
            child: Center(child: body),
          );
        },
      ),
      footer: widget.enablePullUp ? CustomFooter(
        builder: (context, mode) {
          Widget body;
          Color textColor = widget.primaryColor ?? const Color(0xFFFF9027);
          
          if (mode == LoadStatus.idle) {
            body = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_arrow_up, color: textColor, size: 20),
                const SizedBox(width: 8),
                Text("上拉加载", style: TextStyle(color: textColor, fontSize: 14)),
              ],
            );
          } else if (mode == LoadStatus.loading) {
            body = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text("正在加载...", style: TextStyle(color: textColor, fontSize: 14)),
              ],
            );
          } else if (mode == LoadStatus.failed) {
            body = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text("加载失败", style: TextStyle(color: Colors.red, fontSize: 14)),
              ],
            );
          } else if (mode == LoadStatus.canLoading) {
            body = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_arrow_down, color: textColor, size: 20),
                const SizedBox(width: 8),
                Text("释放加载", style: TextStyle(color: textColor, fontSize: 14)),
              ],
            );
          } else {
            body = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text("没有更多数据", style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            );
          }
          return Container(
            height: 60.0,
            child: Center(child: body),
          );
        },
      ) : null,
      onRefresh: () async {
        await widget.onRefresh();
        _refreshController.refreshCompleted();
      },
      onLoading: widget.onLoading != null ? () async {
        await widget.onLoading!();
        _refreshController.loadComplete();
      } : null,
      child: widget.child,
    );
  }
}

/// 简化的下拉刷新包装器
class PullToRefreshWrapper extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? primaryColor;
  final Color? backgroundColor;

  const PullToRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.primaryColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SmartRefreshWrapper(
      onRefresh: onRefresh,
      enablePullDown: true,
      enablePullUp: false,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      child: child,
    );
  }
}
