# 全局Loading管理器使用指南

## 概述

全局Loading管理器解决了多个网络请求同时进行时loading动画一直存在的问题。通过请求计数器机制，确保只有在所有请求都完成后才关闭loading。

## 核心特性

- **请求计数管理**：支持多个并发请求，只有所有请求完成才关闭loading
- **统一管理**：所有网络请求的loading都通过统一管理器控制
- **自动集成**：网络拦截器自动处理loading的显示和隐藏
- **手动控制**：支持手动显示/隐藏loading

## 自动使用（推荐）

### 网络请求自动loading

在网络请求中设置header即可自动显示loading：

```dart
// 在API调用时设置showLoadingDialog为true
final result = await baseApi.getTableDetail(
  tableId: tableId,
  headers: {
    HttpHeaderKey.showLoadingDialog: "true",
  },
);
```

网络拦截器会自动：
- 请求开始时显示loading
- 请求完成时隐藏loading
- 多个并发请求时只显示一个loading
- 所有请求完成后才关闭loading

## 手动使用

### 基本用法

```dart
import 'package:lib_base/utils/loading_manager.dart';

// 显示loading
LoadingManager.instance.showLoading();

// 隐藏loading
LoadingManager.instance.hideLoading();

// 显示带消息的loading
LoadingManager.instance.showLoadingWithMessage("正在处理...");
```

### 执行异步操作

```dart
// 使用扩展方法执行带loading的异步操作
final result = await LoadingManager.instance.executeWithLoading(
  () async {
    // 你的异步操作
    return await someAsyncOperation();
  },
  loadingMessage: "正在处理...",
);
```

### 强制关闭

```dart
// 强制关闭所有loading（用于异常情况）
LoadingManager.instance.forceHideLoading();
```

## 状态查询

```dart
// 检查是否正在显示loading
bool isShowing = LoadingManager.instance.isShowing;

// 获取当前请求数量
int requestCount = LoadingManager.instance.requestCount;
```

## 迁移指南

### 从Get.dialog迁移

**之前的代码：**
```dart
// 显示loading
Get.dialog(
  Center(child: CircularProgressIndicator()),
  barrierDismissible: false,
);

try {
  final result = await apiCall();
  Get.back(); // 关闭loading
} catch (e) {
  Get.back(); // 关闭loading
}
```

**迁移后的代码：**
```dart
// 方法1：使用网络拦截器（推荐）
final result = await apiCall(); // 自动处理loading

// 方法2：手动管理
LoadingManager.instance.showLoading();
try {
  final result = await apiCall();
} finally {
  LoadingManager.instance.hideLoading();
}

// 方法3：使用扩展方法
final result = await LoadingManager.instance.executeWithLoading(
  () => apiCall(),
);
```

## 注意事项

1. **网络请求优先使用拦截器**：对于网络请求，建议使用拦截器自动管理loading
2. **手动管理需要配对**：手动调用`showLoading()`后必须调用`hideLoading()`
3. **异常处理**：使用`executeWithLoading`扩展方法可以自动处理异常情况
4. **强制关闭**：在特殊情况下可以使用`forceHideLoading()`强制关闭loading

## 技术实现

- 使用单例模式确保全局唯一
- 请求计数器机制管理并发请求
- 与Dio拦截器深度集成
- 支持自定义loading样式和消息
