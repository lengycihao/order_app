# 优化后的网络请求模块使用指南

## 概述

经过全面优化，网络请求模块现在具备以下特性：

1. **统一的错误处理**：HTTP状态码和业务状态码统一处理
2. **自动401处理**：业务401错误自动跳转登录页
3. **完善的日志系统**：结构化日志，敏感信息脱敏
4. **模块化拦截器**：职责分离，易于维护

## 主要改进

### 1. 新增ApiBusinessInterceptor

这是核心的业务逻辑拦截器，负责：
- 统一处理HTTP状态码和API业务状态码
- 自动处理401错误（跳转登录页）
- 将响应转换为统一的HttpResultN格式
- 处理各种网络错误

### 2. 优化ApiResponseInterceptor

现在只负责：
- 添加认证token到请求头
- 从AuthService获取当前用户token

### 3. 修复日志系统

- 正确初始化LogManager
- 解决"LogManager Not initialized"问题

## 使用方法

### 基本使用（无需修改现有代码）

```dart
// 现有的API调用代码无需修改
final result = await HttpManagerN.instance.executeGet('/api/waiter/menus');

if (result.isSuccess) {
  // 处理成功数据
  final data = result.getDataJson();
} else {
  // 处理错误 - 现在会正确捕获401等错误
  print('错误码: ${result.code}');
  print('错误消息: ${result.msg}');
}
```

### 错误处理示例

```dart
Future<void> fetchData() async {
  final result = await HttpManagerN.instance.executeGet('/api/waiter/menus');
  
  if (result.isSuccess) {
    // 请求成功
    final data = result.getDataJson();
    print('数据: $data');
  } else {
    // 请求失败 - 现在会正确捕获所有错误
    switch (result.code) {
      case 401:
        // 401错误会自动跳转登录页，这里通常不会执行到
        print('未授权，已自动跳转登录页');
        break;
      case 403:
        print('权限不足: ${result.msg}');
        break;
      case 404:
        print('资源不存在: ${result.msg}');
        break;
      case 422:
        print('参数验证失败: ${result.msg}');
        break;
      case 429:
        print('请求过于频繁: ${result.msg}');
        break;
      case 500:
        print('服务器错误: ${result.msg}');
        break;
      default:
        print('其他错误: ${result.msg}');
    }
  }
}
```

### 测试错误处理

```dart
import 'package:lib_base/lib_base.dart';

// 在需要的地方调用测试
await ErrorHandlingTest.runAllTests();
```

## 配置说明

### 拦截器配置

```dart
List<Interceptor> httpInterceptors = [
  ApiResponseInterceptor(), // 负责添加认证头
  ApiBusinessInterceptor(), // 负责业务逻辑处理
];
```

### 日志配置

```dart
await LogManager.instance.initialize(
  const LogConfig(
    enableConsoleLog: true,
    enableFileLog: false,
    enableUpload: false,
    minLevel: LogLevel.debug,
  ),
);
```

## 解决的问题

### 1. 401错误处理问题

**之前**：
- HTTP 200 + 业务401 被当作成功处理
- 只拦截HTTP 401，不拦截业务401

**现在**：
- 统一处理HTTP和业务状态码
- 业务401自动跳转登录页
- 错误状态正确传递

### 2. 日志系统问题

**之前**：
- LogManager显示"Not initialized"
- 日志输出不完整

**现在**：
- 正确初始化LogManager
- 结构化日志输出
- 敏感信息自动脱敏

### 3. 错误处理不统一

**之前**：
- 不同错误类型处理方式不一致
- 错误信息不完整

**现在**：
- 统一的HttpResultN格式
- 完整的错误信息
- 自动错误分类处理

## 注意事项

1. **向后兼容**：现有代码无需修改，自动享受优化
2. **拦截器顺序**：ApiResponseInterceptor必须在ApiBusinessInterceptor之前
3. **错误处理**：业务代码中仍需要检查result.isSuccess
4. **日志级别**：生产环境建议调整日志级别为info或warn

## 性能优化

1. **减少重复处理**：拦截器职责分离，避免重复逻辑
2. **统一错误格式**：减少上层代码的复杂度
3. **自动跳转**：401错误自动处理，减少手动判断

通过这些优化，您的网络请求模块现在能够：
- ✅ 正确捕获和处理所有类型的错误
- ✅ 自动处理401认证错误
- ✅ 提供完整的日志信息
- ✅ 保持向后兼容性
- ✅ 提供统一的错误处理接口
