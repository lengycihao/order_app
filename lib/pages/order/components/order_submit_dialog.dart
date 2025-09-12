import 'package:flutter/material.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';

class OrderSubmitDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool isLoading;
  final bool isSuccess;
  final bool isError;
  final VoidCallback? onClose;

  const OrderSubmitDialog({
    Key? key,
    required this.title,
    required this.message,
    this.isLoading = false,
    this.isSuccess = false,
    this.isError = false,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标区域
            Container(
              width: 80,
              height: 80,
              margin: EdgeInsets.only(bottom: 16),
              child: _buildIcon(),
            ),
            
            // 标题
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getTitleColor(),
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 8),
            
            // 消息
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 16),
            
            // 按钮区域（只有在成功或错误时显示）
            if (!isLoading) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSuccess ? Colors.orange : Colors.grey[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        '确定',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (isLoading) {
      return RestaurantLoadingWidget(size: 60);
    } else if (isSuccess) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.green[50],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 60,
        ),
      );
    } else if (isError) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red[50],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.error,
          color: Colors.red,
          size: 60,
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: Colors.orange[50],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.restaurant_menu,
          color: Colors.orange,
          size: 60,
        ),
      );
    }
  }

  Color _getTitleColor() {
    if (isSuccess) {
      return Colors.green;
    } else if (isError) {
      return Colors.red;
    } else {
      return Colors.black87;
    }
  }

  /// 显示纯动画加载弹窗（无文字）
  static Future<void> showLoadingOnly(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: RestaurantLoadingWidget(size: 60),
        ),
      ),
    );
  }

  /// 显示加载中的弹窗（带文字）
  static Future<void> showLoading(
    BuildContext context, {
    String title = '正在下单',
    String message = '请稍候...',
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OrderSubmitDialog(
        title: title,
        message: message,
        isLoading: true,
      ),
    );
  }

  /// 显示成功弹窗
  static Future<void> showSuccess(
    BuildContext context, {
    String title = '下单成功',
    String message = '订单已提交成功！',
    VoidCallback? onClose,
  }) async {
    // 先关闭加载弹窗
    Navigator.of(context).pop();
    
    // 显示成功弹窗
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OrderSubmitDialog(
        title: title,
        message: message,
        isSuccess: true,
        onClose: onClose ?? () => Navigator.of(context).pop(),
      ),
    );
  }

  /// 显示错误弹窗
  static Future<void> showError(
    BuildContext context, {
    String title = '下单失败',
    String message = '订单提交失败，请重试',
    VoidCallback? onClose,
  }) async {
    // 先关闭加载弹窗
    Navigator.of(context).pop();
    
    // 显示错误弹窗
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OrderSubmitDialog(
        title: title,
        message: message,
        isError: true,
        onClose: onClose ?? () => Navigator.of(context).pop(),
      ),
    );
  }

  /// 显示重试中弹窗
  static Future<void> showRetrying(
    BuildContext context, {
    String title = '正在重试',
    String message = '服务器响应较慢，正在重试...',
  }) async {
    // 先关闭之前的弹窗
    Navigator.of(context).pop();
    
    // 显示重试弹窗
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OrderSubmitDialog(
        title: title,
        message: message,
        isLoading: true,
      ),
    );
  }
}