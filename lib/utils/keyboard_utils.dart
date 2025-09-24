import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 键盘工具类
class KeyboardUtils {
  /// 收起键盘
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// 收起键盘（使用系统方法）
  static void hideKeyboardSystem() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  /// 创建一个可以点击收起键盘的容器
  static Widget buildDismissibleContainer({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        // 收起键盘
        SystemChannels.textInput.invokeMethod('TextInput.hide');
        // 执行自定义点击回调
        onTap?.call();
      },
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }

  /// 创建一个可以点击收起键盘的页面包装器
  static Widget buildDismissiblePage({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        // 收起键盘
        SystemChannels.textInput.invokeMethod('TextInput.hide');
        // 执行自定义点击回调
        onTap?.call();
      },
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}

/// 可点击收起键盘的页面混入
mixin DismissibleKeyboardMixin<T extends StatefulWidget> on State<T> {
  /// 收起键盘
  void dismissKeyboard() {
    KeyboardUtils.hideKeyboardSystem();
  }

  /// 创建可点击收起键盘的容器
  Widget buildDismissibleContainer({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return KeyboardUtils.buildDismissibleContainer(
      child: child,
      onTap: onTap,
    );
  }
}
