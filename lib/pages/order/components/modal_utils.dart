import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 弹窗工具类
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
      builder: (context) => height != null
          ? Container(
              height: height,
              child: child,
            )
          : margin != null
              ? Container(
                  margin: margin,
                  child: child,
                )
              : child,
    );
  }

  /// 显示确认对话框
  static void showConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = '确认',
    String cancelText = '取消',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    Color? confirmColor,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: onCancel ?? () => Get.back(),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: onConfirm ?? () => Get.back(),
            style: TextButton.styleFrom(
              foregroundColor: confirmColor ?? Colors.red,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// 显示提示消息
  static void showSnackBar({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: backgroundColor ?? Colors.orange.withOpacity(0.1),
      colorText: textColor ?? Colors.orange,
      duration: duration,
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(16),
      borderRadius: 8,
      isDismissible: true,
    );
  }
}

/// 通用弹窗容器
class ModalContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const ModalContainer({
    Key? key,
    required this.title,
    required this.child,
    this.actions,
    this.showCloseButton = true,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (showCloseButton)
                  GestureDetector(
                    onTap: onClose ?? () => Get.back(),
                    child: Icon(Icons.close, size: 24),
                  ),
              ],
            ),
          ),
          // 内容
          Flexible(child: child),
          // 底部操作按钮
          if (actions != null && actions!.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: actions!,
              ),
            ),
        ],
      ),
    );
  }
}

/// 购物车弹窗容器
class CartModalContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onClear;

  const CartModalContainer({
    Key? key,
    required this.title,
    required this.child,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // 用户头像
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.grey.shade600,
                    size: 16,
                  ),
                ),
                // 标题居中
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // 清空按钮
                GestureDetector(
                  onTap: onClear,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.grey.shade600,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '清空',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 内容
          Flexible(child: child),
        ],
      ),
    );
  }
}

/// 通用弹窗容器（带边距）
class ModalContainerWithMargin extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final EdgeInsets? margin;

  const ModalContainerWithMargin({
    Key? key,
    required this.title,
    required this.child,
    this.actions,
    this.showCloseButton = true,
    this.onClose,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xff000000),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (showCloseButton)
                  GestureDetector(
                    onTap: onClose ?? () => Get.back(),
                    child: Icon(Icons.close, size: 24),
                  ),
              ],
            ),
          ),
          Divider(height: 1,indent: 16,endIndent: 16, color: Colors.grey.shade300),
          // 内容
          Flexible(child: child),
          // 底部操作按钮
          if (actions != null && actions!.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: actions!,
              ),
            ),
        ],
      ),
    );
  }
}
