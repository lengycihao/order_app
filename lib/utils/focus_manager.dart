import 'package:flutter/material.dart';

/// 全局焦点管理器
class GlobalFocusManager {
  static final GlobalFocusManager _instance = GlobalFocusManager._internal();
  factory GlobalFocusManager() => _instance;
  GlobalFocusManager._internal();

  // 存储所有活跃的数量输入组件的焦点节点
  final Set<FocusNode> _activeQuantityInputs = <FocusNode>{};

  /// 注册数量输入组件的焦点节点
  void registerQuantityInput(FocusNode focusNode) {
    _activeQuantityInputs.add(focusNode);
  }

  /// 注销数量输入组件的焦点节点
  void unregisterQuantityInput(FocusNode focusNode) {
    _activeQuantityInputs.remove(focusNode);
  }

  /// 收起所有数量输入组件的键盘并恢复原值
  void dismissAllQuantityInputs() {
    for (final focusNode in _activeQuantityInputs) {
      if (focusNode.hasFocus) {
        focusNode.unfocus();
      }
    }
  }

  /// 清除所有注册的焦点节点
  void clear() {
    _activeQuantityInputs.clear();
  }
}
