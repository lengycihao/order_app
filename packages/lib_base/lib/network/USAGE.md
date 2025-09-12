# HttpManager 优化使用指南

## 初始化

```dart
// 在应用启动时初始化
HttpManager.instance.init(
  'https://api.example.com',
  enableLogging: true,        // 启用日志
  enableCache: true,          // 启用缓存
  enableEncryption: false,    // 启用加密（可选）
  enableDebounce: true,       // 启用防抖
  enableApiInterceptor: true, // 启用API业务逻辑处理（新增）
  encryptionKey: 'your-key',  // 加密密钥（可选）
  encryptionIv: 'your-iv',    // 加密向量（可选）
);
```

## 基本使用

### GET 请求
```dart
final result = await HttpManager.instance.executeGet(
  '/api/users',
  queryParam: {'page': 1, 'limit': 10},
  cacheControl: CacheControl.cacheFirstOrNetworkPut,
  cacheExpiration: Duration(minutes: 30),
);

if (result.isSuccess) {
  final data = result.getDataJson();
  // 处理数据
}
```

### POST 请求
```dart
final result = await HttpManager.instance.executePost(
  '/api/users',
  jsonParam: {
    'name': 'John Doe',
    'email': 'john@example.com',
  },
  bodyEncrypt: true,  // 启用请求体加密
  networkDebounce: true,  // 启用防抖
);
```

### PUT 请求
```dart
final result = await HttpManager.instance.executePut(
  '/api/users/123',
  jsonParam: {
    'name': 'Updated Name',
  },
);
```

### DELETE 请求
```dart
final result = await HttpManager.instance.executeDelete(
  '/api/users/123',
);
```

### 文件上传
```dart
final result = await HttpManager.instance.uploadFiles(
  '/api/upload',
  fields: {
    'user_id': '123',
    'description': 'Profile photo',
  },
  filePaths: {
    'avatar': '/path/to/avatar.jpg',
  },
  onSendProgress: (sent, total) {
    print('Upload: ${(sent / total * 100).toInt()}%');
  },
);
```

### 文件下载
```dart
final result = await HttpManager.instance.downloadFile(
  'https://example.com/file.pdf',
  '/local/path/file.pdf',
  onReceiveProgress: (received, total) {
    print('Download: ${(received / total * 100).toInt()}%');
  },
);
```

## 高级功能

### 缓存策略
- `CacheControl.onlyCache`: 仅使用缓存
- `CacheControl.cacheFirstOrNetworkPut`: 缓存优先，无缓存时请求网络
- `CacheControl.onlyNetworkPutCache`: 仅网络请求，但缓存响应

### 加密选项
- `paramEncrypt: true`: 加密URL参数
- `bodyEncrypt: true`: 加密请求体
- 自动识别敏感字段并加密

### 防抖去重
- `networkDebounce: true`: 启用请求防抖
- 自动去除重复请求
- 防止快速重复点击

### 运行时管理
```dart
// 更新基础URL
HttpManager.instance.updateBaseUrl('https://new-api.example.com');

// 清除缓存
HttpManager.instance.clearCache();

// 清除防抖缓存
HttpManager.instance.clearDebounceCache();

// 取消所有请求
HttpManager.instance.cancelAllRequests();
```

## 错误处理

```dart
final result = await HttpManager.instance.executeGet('/api/data');

if (result.isSuccess) {
  // 请求成功
  final data = result.getDataJson();
} else {
  // 请求失败
  print('Error: ${result.msg}');
  print('Code: ${result.code}');
}
```

## ApiInterceptor 业务逻辑处理（新增）

ApiInterceptor 是新增的核心功能，负责统一处理HTTP状态码和API业务状态码，简化上层业务代码。

### 自动处理的状态码

#### HTTP状态码
- 200, 201, 202, 204: 成功状态
- 400: Bad Request
- 401: Unauthorized（可扩展自动登出逻辑）
- 403: Forbidden 
- 404: Not Found
- 422: Validation Error
- 429: Rate Limit
- 500: Internal Server Error
- 其他状态码自动映射错误消息

#### API业务状态码
- 200/0: 业务成功
- 401: 未授权（自动登出）
- 403: 权限不足
- 404: 资源不存在
- 422: 参数验证失败
- 429: 请求频率限制
- 500: 服务器错误

### 响应数据格式支持

ApiInterceptor 支持多种API响应格式：

```json
// 标准格式
{
  "code": 200,
  "message": "Success",
  "data": {...}
}

// 简化格式
{
  "status": 0,
  "msg": "OK", 
  "data": [...]
}

// 错误格式
{
  "code": 400,
  "errorCode": 1001,
  "message": "Parameter validation failed"
}
```

### 业务逻辑扩展

可以在 ApiInterceptor 中扩展特定业务逻辑：

```dart
// 在 _handleUnauthorized 方法中添加自动登出
HttpResult _handleUnauthorized(int code, String? message) {
  // 自动登出逻辑
  AuthService.logout();
  // 跳转到登录页
  NavigationService.toLogin();
  
  return HttpResult(
    isSuccess: false,
    code: code,
    msg: message ?? 'Unauthorized - Please login again',
  );
}
```

## 新增功能特性

1. **ApiInterceptor**: 统一业务逻辑处理，自动状态码映射
2. **更多HTTP方法**: 支持PUT、DELETE、PATCH
3. **增强加密**: 完整的AES加解密支持
4. **智能缓存**: 内存+文件双级缓存
5. **美化日志**: 结构化日志输出，敏感信息脱敏
6. **防抖去重**: 智能请求合并和去重
7. **进度跟踪**: 上传下载进度回调
8. **统一错误处理**: 网络错误和业务错误统一处理
9. **运行时配置**: 支持动态更新配置

所有这些功能都保持了与原有API的兼容性，可以无缝升级使用。

## 架构优势

通过 ApiInterceptor 的引入，实现了关注点分离：

- **HttpManager**: 专注于网络请求的发送和基础配置
- **ApiInterceptor**: 专注于业务逻辑、状态码处理和错误映射
- **其他拦截器**: 专注于各自的职责（缓存、加密、日志等）

这样的架构使得代码更容易维护和扩展，业务逻辑集中在一个地方处理。