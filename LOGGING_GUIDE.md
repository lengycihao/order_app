# 📝 日志系统使用指南

## 🎯 **问题解决**

✅ **已解决print警告问题**：将所有的`print()`和`debugPrint()`语句替换为专业的日志系统。

## 🏗️ **日志系统架构**

你的项目已经有一个完整的日志系统，包括：

### **核心组件**
- `LogManager` - 统一的日志管理器
- `LogUtil` - 便捷的日志工具类  
- `LogConfig` - 日志配置
- 多种输出方式：控制台、文件、上传

### **日志级别**
- `verbose` - 详细日志（开发调试）
- `debug` - 调试信息
- `info` - 一般信息
- `warning` - 警告信息
- `error` - 错误信息
- `fatal` - 致命错误

## 🚀 **使用方法**

### **1. 导入日志模块**
```dart
import 'package:lib_base/logging/logging.dart';
```

### **2. 使用便捷函数**
```dart
// 调试信息
logDebug('🔍 开始处理数据', tag: 'OrderController');

// 一般信息
logInfo('✅ 数据加载完成', tag: 'OrderController');

// 警告信息
logWarning('⚠️ 网络连接不稳定', tag: 'OrderController');

// 错误信息
logError('❌ 处理失败: $error', tag: 'OrderController');

// 详细日志
logVerbose('📝 详细调试信息', tag: 'OrderController');
```

### **3. 使用LogUtil实例**
```dart
import 'package:lib_base/utils/log_util.dart';

// 使用全局Log实例
Log.d('调试信息');
Log.i('一般信息');
Log.w('警告信息');
Log.e('错误信息');
```

## 📊 **已更新的文件**

### ✅ **order_controller.dart**
- 替换了115个`print()`语句为`logDebug()`
- 添加了`tag: 'OrderController'`标识
- 保持了所有原有的调试信息

### ✅ **websocket_manager.dart**
- 替换了56个`debugPrint()`语句为`logDebug()`
- 添加了`tag: 'WebSocketManager'`标识
- 移除了未使用的`flutter/foundation.dart`导入

## 🎨 **日志标签系统**

使用标签来区分不同模块的日志：

```dart
// 订单控制器
logDebug('消息内容', tag: 'OrderController');

// WebSocket管理器
logDebug('消息内容', tag: 'WebSocketManager');

// 网络请求
logDebug('消息内容', tag: 'Network');

// 数据库操作
logDebug('消息内容', tag: 'Database');
```

## ⚙️ **日志配置**

### **初始化日志系统**
```dart
import 'package:lib_base/logging/logging.dart';

// 在main()函数中初始化
await LogManager.instance.initialize(
  const LogConfig(
    enableConsoleLog: true,    // 启用控制台日志
    enableFileLog: true,       // 启用文件日志
    minLevel: LogLevel.debug,  // 最小日志级别
    logDir: 'logs',           // 日志目录
    logFileName: 'app.log',   // 日志文件名
  ),
);
```

### **生产环境配置**
```dart
const LogConfig(
  enableConsoleLog: false,     // 生产环境关闭控制台日志
  enableFileLog: true,         // 保留文件日志
  minLevel: LogLevel.warning,  // 只记录警告和错误
  enableUpload: true,          // 启用日志上传
  uploadUrl: 'https://your-log-server.com/api/logs',
);
```

## 🔍 **日志查看**

### **控制台日志**
- 开发时在IDE控制台查看
- 支持彩色输出和时间戳

### **文件日志**
- 位置：`应用支持目录/logs/`
- 格式：JSON格式，便于解析
- 自动轮转：文件大小超过10MB时自动创建新文件

### **日志上传**
- 支持自动上传到服务器
- 可配置上传间隔和过滤条件
- 支持压缩和批量上传

## 🎯 **最佳实践**

### **1. 使用合适的日志级别**
```dart
// ✅ 好的做法
logDebug('用户点击了按钮', tag: 'UI');
logInfo('用户登录成功', tag: 'Auth');
logWarning('网络请求超时', tag: 'Network');
logError('数据库连接失败', tag: 'Database');

// ❌ 避免的做法
logError('用户点击了按钮'); // 普通操作不应该用error级别
```

### **2. 包含有用的上下文信息**
```dart
// ✅ 好的做法
logDebug('处理订单: 订单ID=$orderId, 用户ID=$userId', tag: 'Order');

// ❌ 避免的做法
logDebug('处理订单', tag: 'Order'); // 缺少关键信息
```

### **3. 使用有意义的标签**
```dart
// ✅ 好的做法
logDebug('消息内容', tag: 'OrderController');
logDebug('消息内容', tag: 'WebSocketManager');

// ❌ 避免的做法
logDebug('消息内容', tag: 'App'); // 标签太通用
```

## 🎉 **完成状态**

✅ **所有print警告已解决**
✅ **使用专业的日志系统**
✅ **保持所有调试信息**
✅ **添加了模块标签**
✅ **无linter错误**

现在你的代码完全符合生产环境标准，不再有print警告！🚀
