import 'package:flutter/material.dart';

/// 弹窗工具类 - 统一项目弹窗样式
class ModalUtils {
  /// 显示底部弹窗
  static void showBottomModal({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = false,
    bool isDismissible = true,
    Color? backgroundColor,
    double? height,
    EdgeInsets? margin,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      backgroundColor: backgroundColor ?? Colors.transparent,
      builder: (context) {
        Widget wrappedChild = child;
        
        if (height != null) {
          wrappedChild = Container(
            height: height,
            child: child,
          );
        } else if (margin != null) {
          wrappedChild = Container(
            margin: margin,
            child: child,
          );
        }
        
        // 当 isScrollControlled 为 true 时，包装在 SingleChildScrollView 中，并设置适当的约束
        if (isScrollControlled) {
          return SingleChildScrollView(
            child: wrappedChild,
          );
        }
        
        return wrappedChild;
      },
    );
  }
  /// 显示确认弹窗
  /// 
  /// [context] 上下文
  /// [title] 弹窗标题
  /// [message] 弹窗消息内容
  /// [confirmText] 确认按钮文字，默认为"确定"
  /// [cancelText] 取消按钮文字，默认为"取消"
  /// [onConfirm] 确认回调
  /// [onCancel] 取消回调
  /// [confirmColor] 确认按钮颜色，默认为橙色
  /// [cancelColor] 取消按钮颜色，默认为深灰色
  static Future<bool?> showConfirmDialog({
    required BuildContext context,
    String? title,
    required String message,
    String confirmText = '确定',
    String cancelText = '取消',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    Color confirmColor = const Color(0xFFFF8C00),
    Color cancelColor = const Color(0xFF4A4A4A),
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题区域
              if (title != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // 消息内容区域
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, title != null ? 0 : 20, 20, 20),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF4A4A4A),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // 分割线
              Container(
                height: 1,
                color: const Color(0xFFE0E0E0),
              ),
              
              // 按钮区域
              IntrinsicHeight(
                child: Row(
                  children: [
                    // 取消按钮
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop(false);
                          onCancel?.call();
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              cancelText,
                              style: TextStyle(
                                fontSize: 16,
                                color: cancelColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // 垂直分割线
                    Container(
                      width: 1,
                      color: const Color(0xFFE0E0E0),
                    ),
                    
                    // 确认按钮
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop(true);
                          onConfirm?.call();
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              confirmText,
                              style: TextStyle(
                                fontSize: 16,
                                color: confirmColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 显示简单提示弹窗
  /// 
  /// [context] 上下文
  /// [message] 提示消息
  /// [confirmText] 确认按钮文字，默认为"确定"
  /// [onConfirm] 确认回调
  static Future<void> showAlertDialog({
    required BuildContext context,
    required String message,
    String confirmText = '确定',
    VoidCallback? onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 消息内容区域
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF4A4A4A),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // 分割线
              Container(
                height: 1,
                color: const Color(0xFFE0E0E0),
              ),
              
              // 确认按钮
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  onConfirm?.call();
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      confirmText,
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFFFF8C00),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 显示加载弹窗
  /// 
  /// [context] 上下文
  /// [message] 加载提示文字，默认为"加载中..."
  static Future<void> showLoadingDialog({
    required BuildContext context,
    String message = '加载中...',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.all(24),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFFFF8C00),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF4A4A4A),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 显示SnackBar提示
  /// 
  /// [context] 上下文
  /// [title] 提示标题
  /// [message] 提示消息
  /// [duration] 显示时长，默认为2秒
  static void showSnackBar({
    required BuildContext context,
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        duration: duration,
        backgroundColor: const Color(0xFF4A4A4A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// 带边距的弹窗容器组件
class ModalContainerWithMargin extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsets margin;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const ModalContainerWithMargin({
    Key? key,
    required this.title,
    required this.child,
    this.margin = const EdgeInsets.all(16),
    this.showCloseButton = true,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
                if (showCloseButton)
                  GestureDetector(
                    onTap: () {
                      if (onClose != null) {
                        onClose!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: const Color(0xFF666666),
                    ),
                  ),
              ],
            ),
          ),
          // 内容区域
          Flexible(child: child),
        ],
      ),
    );
  }
}
