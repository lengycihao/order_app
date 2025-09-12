import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';

/// 全局Loading管理器
/// 解决多个网络请求同时进行时loading动画一直存在的问题
class LoadingManager {
  static final LoadingManager _instance = LoadingManager._internal();
  factory LoadingManager() => _instance;
  LoadingManager._internal();

  static LoadingManager get instance => _instance;

  // 当前显示的loading dialog
  bool _isShowing = false;
  
  // 请求计数器，用于管理多个并发请求
  int _requestCount = 0;
  

  /// 显示loading
  void showLoading({String? message}) {
    _requestCount++;
    
    // 如果已经在显示loading，只需要增加计数
    if (_isShowing) {
      return;
    }
    
    _isShowing = true;
    
    // 显示loading dialog
    Get.dialog(
      _buildLoadingDialog(message),
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
    ).then((_) {
      // dialog被关闭时的回调
      _isShowing = false;
      _requestCount = 0;
    });
  }

  /// 隐藏loading
  void hideLoading() {
    if (_requestCount > 0) {
      _requestCount--;
    }
    
    // 只有当所有请求都完成时才关闭loading
    if (_requestCount <= 0 && _isShowing) {
      _requestCount = 0;
      Get.back();
      _isShowing = false;
    }
  }

  /// 强制关闭所有loading
  void forceHideLoading() {
    _requestCount = 0;
    if (_isShowing) {
      Get.back();
      _isShowing = false;
    }
  }

  /// 检查是否正在显示loading
  bool get isShowing => _isShowing;

  /// 获取当前请求数量
  int get requestCount => _requestCount;

  /// 构建loading dialog
  Widget _buildLoadingDialog(String? message) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: RestaurantLoadingWidget(
            size: 50,
            color: Colors.orange,
          ),
        ),
      ),
    );
  }

  /// 显示带消息的loading
  void showLoadingWithMessage(String message) {
    showLoading(message: message);
  }

  /// 重置状态（用于调试或异常情况）
  void reset() {
    _requestCount = 0;
    _isShowing = false;
  }
}

/// Loading管理器的扩展方法
extension LoadingManagerExtension on LoadingManager {
  /// 执行带loading的异步操作
  Future<T> executeWithLoading<T>(
    Future<T> Function() operation, {
    String? loadingMessage,
  }) async {
    try {
      showLoading(message: loadingMessage);
      final result = await operation();
      return result;
    } finally {
      hideLoading();
    }
  }
}
