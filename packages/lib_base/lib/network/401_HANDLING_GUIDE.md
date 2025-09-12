# 401错误处理优化指南

## 概述

已经完全优化了401错误的处理机制，现在具备以下特性：

✅ **防重复处理**：3秒冷却时间，避免重复跳转和提示  
✅ **自动跳转登录页**：支持多个备用路由  
✅ **智能提示消息**：只显示一次，自动消失  
✅ **状态管理**：可查看和重置处理状态  
✅ **完全可配置**：支持自定义各种参数  

## 使用方法

### 1. 基本配置（已在main.dart中配置）

```dart
// 在应用启动时配置401处理器
UnauthorizedHandler.instance.configure(
  loginRoute: '/login',                              // 主要登录路由
  defaultTitle: '认证失败',                          // 提示标题
  defaultMessage: '登录已过期，请重新登录',          // 提示消息
  cooldownDuration: const Duration(seconds: 3),     // 冷却时间
  snackbarDuration: const Duration(seconds: 2),     // 提示显示时间
  fallbackRoutes: ['/login', '/auth'],              // 备用路由
);
```

### 2. 自动工作

配置完成后，所有401错误会自动处理：

```dart
// 您的现有代码无需修改
final result = await HttpManagerN.instance.executeGet('/api/waiter/menus');

if (result.isSuccess) {
  // 处理成功数据
} else {
  // 如果是401错误，会自动：
  // 1. 显示提示消息
  // 2. 跳转到登录页
  // 3. 防止重复处理
  print('错误: ${result.msg}');
}
```

### 3. 高级功能

#### 重置处理状态
```dart
// 重置401处理状态（用于测试或特殊情况）
UnauthorizedHandler.instance.resetState();
```

#### 查看当前状态
```dart
// 获取当前处理状态
final status = UnauthorizedHandler.instance.getStatus();
print('是否正在处理: ${status['isHandling']}');
print('最后处理时间: ${status['lastHandleTime']}');
```

#### 手动处理401错误
```dart
// 手动触发401处理（如果需要）
final handled = UnauthorizedHandler.instance.handle401Error('自定义错误消息');
```

## 防重复机制

### 工作原理

1. **冷却时间**：连续的401错误在3秒内只会处理一次
2. **处理标志**：正在处理时会跳过新的401错误
3. **时间记录**：记录最后处理时间，防止频繁处理

### 示例场景

```dart
// 场景：快速连续发送多个会返回401的请求
for (int i = 0; i < 5; i++) {
  final result = await HttpManagerN.instance.executeGet('/api/waiter/menus');
  print('请求$i: ${result.isSuccess ? "成功" : "失败"}');
}

// 结果：
// - 只有第一个请求会触发401处理（显示提示、跳转登录页）
// - 其他4个请求会返回错误，但不会重复处理
```

## 测试工具

### 使用Test401Page进行测试

```dart
// 在您的路由中添加测试页面
GetPage(name: '/test-401', page: () => const Test401Page()),

// 然后访问该页面进行测试
Get.toNamed('/test-401');
```

### 测试功能

1. **单次401测试**：测试基本的401处理逻辑
2. **防重复测试**：连续5次401请求，验证防重复机制
3. **状态管理**：查看和重置处理状态

## 日志输出

处理401错误时会输出详细的日志信息：

```
🔐 开始处理401错误
💬 已显示401提示消息
🔄 自动跳转到登录页...
✅ 已跳转到登录页: /login
✅ 401错误处理完成
```

如果遇到重复处理：
```
🔒 401错误在冷却期内，跳过处理
🔒 正在处理401错误，跳过重复处理
```

## 错误恢复

如果跳转失败，会自动尝试备用方案：

1. 首先尝试主要登录路由 `/login`
2. 如果失败，尝试备用路由 `/auth`
3. 如果都失败，显示错误提示

## 自定义配置示例

```dart
// 自定义配置示例
UnauthorizedHandler.instance.configure(
  loginRoute: '/custom-login',                       // 自定义登录路由
  defaultTitle: '会话过期',                          // 自定义标题
  defaultMessage: '您的会话已过期，请重新登录',      // 自定义消息
  cooldownDuration: const Duration(seconds: 5),     // 更长的冷却时间
  snackbarDuration: const Duration(seconds: 3),     // 更长的提示时间
  fallbackRoutes: ['/login', '/signin', '/auth'],   // 更多备用路由
);
```

## 注意事项

1. **冷却时间**：默认3秒，可根据需要调整
2. **路由配置**：确保登录路由已正确配置
3. **Get框架**：依赖GetX进行导航和提示
4. **向后兼容**：现有代码无需修改

通过这个优化方案，您的401错误处理现在完全自动化，并且不会出现重复跳转和提示的问题！
