# 弹窗管理器使用指南

## 概述

弹窗管理器（DialogManager）是一个单例类，用于管理应用中的弹窗显示，确保同时只显示一个弹窗，避免弹窗重叠的问题。

## 主要功能

### 1. 409强制更新弹窗管理
- 当收到409状态码时，自动显示强制更新确认弹窗
- 如果已有弹窗显示，会先关闭当前弹窗再显示新的
- 确保用户界面的一致性和清晰度

### 2. 通用确认弹窗管理
- 提供统一的确认弹窗显示接口
- 支持自定义标题、内容、按钮文字和颜色
- 自动管理弹窗状态，防止重复显示

## 使用方法

### 显示409强制更新弹窗

```dart
dialogManager.showForceUpdateDialog(
  context: context,
  message: '检测到其他用户正在修改此商品，是否继续操作？',
  onConfirm: () {
    // 用户确认后的操作
    _performForceUpdate();
  },
  onCancel: () {
    // 用户取消后的操作
    _cancelForceUpdate();
  },
);
```

### 显示通用确认弹窗

```dart
dialogManager.showConfirmDialog(
  context: context,
  title: '操作确认',
  content: '确定要执行此操作吗？',
  confirmText: '确认',
  cancelText: '取消',
  confirmColor: Colors.orange,
  onConfirm: () {
    // 用户确认后的操作
  },
  onCancel: () {
    // 用户取消后的操作
  },
);
```

## 核心特性

### 1. 弹窗状态管理
- `isDialogShowing`: 当前是否有弹窗显示
- `currentDialogType`: 当前弹窗类型（force_update、confirm等）
- 自动跟踪弹窗状态，防止重复显示

### 2. 自动弹窗替换
- 当新弹窗需要显示时，自动关闭当前弹窗
- 确保用户界面始终只有一个弹窗
- 避免弹窗重叠造成的用户体验问题

### 3. 异常处理
- 弹窗显示异常时自动清理状态
- 提供强制关闭所有弹窗的紧急方法
- 完善的错误日志记录

## 集成位置

### OrderController
- 409消息处理：`_handleForceUpdateRequired()`
- 使用弹窗管理器显示强制更新确认弹窗

### QuantityInputWidget
- 数量修改409处理：`_showDoubleConfirmDialog()`
- 使用弹窗管理器显示二次确认弹窗

## 测试场景

### 1. 基本功能测试
- 正常显示409弹窗
- 用户确认和取消操作
- 弹窗状态正确清理

### 2. 弹窗替换测试
- 快速连续触发多个409消息
- 验证新弹窗会替换旧弹窗
- 确保同时只有一个弹窗显示

### 3. 异常情况测试
- 上下文无效时的处理
- 弹窗显示异常时的状态清理
- 强制关闭弹窗功能

## 日志输出

弹窗管理器会输出详细的调试日志：

```
[DialogManager] 🔍 检查弹窗状态: isDialogShowing=false, currentType=null
[DialogManager] ✅ 开始显示409强制更新弹窗
[DialogManager] ✅ 用户确认409强制更新
[DialogManager] 🧹 弹窗状态已清理
```

## 注意事项

1. **单例模式**: DialogManager使用单例模式，确保全局状态一致
2. **上下文管理**: 需要确保传入有效的BuildContext
3. **状态清理**: 弹窗关闭后会自动清理状态，无需手动处理
4. **异常安全**: 所有操作都有异常处理，确保应用稳定性

## 扩展性

弹窗管理器设计为可扩展的架构，可以轻松添加新的弹窗类型：

1. 在DialogManager中添加新的显示方法
2. 定义新的弹窗类型常量
3. 实现相应的弹窗组件
4. 更新状态管理逻辑

这样的设计确保了弹窗管理的统一性和可维护性。
