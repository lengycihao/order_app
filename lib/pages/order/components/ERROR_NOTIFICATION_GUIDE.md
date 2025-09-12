# 错误提示防重复功能使用指南

## 概述

`ErrorNotificationManager` 是一个单例类，用于管理应用中的错误、成功和警告提示，防止重复显示相同的提示消息。

## 主要功能

### 1. 防重复机制
- **冷却时间**: 3秒内相同消息不会重复显示
- **消息去重**: 基于标题、消息内容和错误代码生成唯一标识符
- **自动清理**: 定期清理过期的提示记录，避免内存泄漏

### 2. 提示类型
- **错误提示**: `showErrorNotification()` - 红色主题
- **成功提示**: `showSuccessNotification()` - 绿色主题  
- **警告提示**: `showWarningNotification()` - 橙色主题
- **强制显示**: `forceShowNotification()` - 忽略防重复机制

## 使用方法

### 基本用法

```dart
import 'package:order_app/pages/order/components/error_notification_manager.dart';

// 获取管理器实例
final manager = ErrorNotificationManager();

// 显示错误提示
manager.showErrorNotification(
  title: '操作失败',
  message: '网络连接超时，请重试',
  errorCode: 'network_timeout',
);

// 显示成功提示
manager.showSuccessNotification(
  title: '操作成功',
  message: '数据已保存',
  successCode: 'save_success',
);

// 显示警告提示
manager.showWarningNotification(
  title: '注意',
  message: '此操作不可撤销',
  warningCode: 'irreversible_action',
);
```

### 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `title` | String | 是 | 提示标题 |
| `message` | String | 是 | 提示消息内容 |
| `errorCode/successCode/warningCode` | String | 否 | 错误/成功/警告代码，用于防重复标识 |
| `backgroundColor` | Color | 否 | 背景颜色，默认根据类型设置 |
| `textColor` | Color | 否 | 文字颜色，默认根据类型设置 |
| `duration` | Duration | 否 | 显示时长，默认2秒 |

### 防重复机制详解

#### 1. 标识符生成
```dart
// 基于以下信息生成唯一标识符
final key = '${title}_${message}_${code ?? ''}';
```

#### 2. 冷却时间检查
```dart
// 3秒内相同消息不会重复显示
if (currentTime - lastShownTime < 3000) {
  return; // 跳过显示
}
```

#### 3. 记录管理
```dart
// 记录已显示的消息
_shownErrors.add(key);
_errorTimestamps[key] = currentTime;
```

## 实际应用示例

### WebSocket错误处理

```dart
// 在OrderController中处理WebSocket错误
void _handleOperationError(PendingOperation operation, int code, String message) {
  switch (code) {
    case 409:
      ErrorNotificationManager().showWarningNotification(
        title: '超出限制',
        message: message,
        warningCode: code.toString(),
      );
      break;
    case 501:
      // 501错误会自动重试，不显示提示
      _handleCart501Error(operation);
      return;
    default:
      ErrorNotificationManager().showErrorNotification(
        title: '操作失败',
        message: message,
        errorCode: code.toString(),
      );
  }
}
```

### 表单验证

```dart
// 在规格选择弹窗中处理验证错误
if (missingOptionName != null) {
  ErrorNotificationManager().showWarningNotification(
    title: '提示',
    message: '请选择$missingOptionName',
    warningCode: 'missing_required_option',
  );
}
```

### 网络请求错误

```dart
// 处理API请求失败
try {
  final result = await api.getData();
  if (result.isSuccess) {
    ErrorNotificationManager().showSuccessNotification(
      title: '成功',
      message: '数据加载完成',
      successCode: 'data_loaded',
    );
  } else {
    ErrorNotificationManager().showErrorNotification(
      title: '加载失败',
      message: result.message ?? '未知错误',
      errorCode: 'api_error',
    );
  }
} catch (e) {
  ErrorNotificationManager().showErrorNotification(
    title: '网络错误',
    message: '请检查网络连接',
    errorCode: 'network_error',
  );
}
```

## 高级功能

### 强制显示
```dart
// 忽略防重复机制，强制显示提示
manager.forceShowNotification(
  title: '重要通知',
  message: '系统维护中',
);
```

### 清理记录
```dart
// 清理所有提示记录（用于测试或重置）
manager.clearAllRecords();
```

## 最佳实践

### 1. 错误代码命名
```dart
// 使用有意义的错误代码
'network_timeout'     // 网络超时
'validation_failed'   // 验证失败
'permission_denied'   // 权限不足
'data_not_found'      // 数据不存在
```

### 2. 消息内容
```dart
// 提供清晰、用户友好的错误消息
'网络连接超时，请检查网络设置后重试'
'请选择必填的规格选项'
'操作成功，数据已保存'
```

### 3. 错误分类
```dart
// 根据错误类型选择合适的提示方法
if (isUserError) {
  manager.showWarningNotification(...);  // 用户操作错误
} else if (isSystemError) {
  manager.showErrorNotification(...);    // 系统错误
} else if (isSuccess) {
  manager.showSuccessNotification(...);  // 成功操作
}
```

## 测试

使用 `ErrorNotificationTest` 类进行功能测试：

```dart
import 'package:order_app/pages/order/components/error_notification_test.dart';

// 运行测试
ErrorNotificationTest.runTest();

// 清理测试数据
ErrorNotificationTest.cleanup();
```

## 注意事项

1. **单例模式**: 使用单例模式确保全局状态一致
2. **内存管理**: 自动清理过期记录，避免内存泄漏
3. **线程安全**: 所有操作都在主线程执行
4. **性能优化**: 使用Set和Map进行快速查找
5. **调试友好**: 提供详细的调试日志输出

## 故障排除

### 问题1: 提示不显示
- 检查是否在冷却时间内
- 确认消息内容是否完全相同
- 查看调试日志确认原因

### 问题2: 重复提示仍然显示
- 检查错误代码是否不同
- 确认标题或消息内容是否有差异
- 使用强制显示功能绕过防重复机制

### 问题3: 内存占用过高
- 检查是否有大量不同的提示消息
- 考虑调整冷却时间或清理策略
- 使用 `clearAllRecords()` 手动清理
