# WebSocket生命周期管理指南

## 问题描述

在桌台页面（外卖页面）仍然收到WebSocket消息，导致不必要的网络通信和日志输出。

## 问题原因

1. **页面切换时WebSocket连接未清理**：从点餐页面切换到桌台页面时，WebSocket连接没有被正确断开
2. **桌台页面不需要WebSocket连接**：桌台页面是外卖订单管理页面，不需要实时WebSocket通信
3. **缺乏统一的连接管理**：不同页面的WebSocket连接管理分散，没有统一的生命周期管理

## 解决方案

### 1. WebSocket生命周期管理器

创建了 `WebSocketLifecycleManager` 类来统一管理不同页面的WebSocket连接状态：

```dart
// 页面类型定义
static const String PAGE_TAKEAWAY = 'takeaway';  // 桌台页面（外卖）
static const String PAGE_ORDER = 'order';        // 点餐页面
static const String PAGE_TABLE = 'table';        // 桌台管理页面
static const String PAGE_OTHER = 'other';        // 其他页面
```

### 2. 页面类型处理逻辑

- **桌台页面（外卖）**：清理所有WebSocket连接，不需要实时通信
- **点餐页面**：保持WebSocket连接，用于实时订单更新
- **桌台管理页面**：清理所有WebSocket连接
- **其他页面**：根据具体需求管理

### 3. 使用方法

#### 在页面控制器中使用

```dart
class TakeawayController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    // 设置页面类型并清理WebSocket连接
    wsLifecycleManager.setCurrentPageType(WebSocketLifecycleManager.PAGE_TAKEAWAY);
    loadInitialData();
  }

  @override
  void onClose() {
    // 清理WebSocket连接
    wsLifecycleManager.cleanupAllConnections();
    searchController.dispose();
    super.onClose();
  }
}
```

#### 在点餐页面中使用

```dart
class OrderController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    // 设置页面类型，点餐页面需要WebSocket连接
    wsLifecycleManager.setCurrentPageType(WebSocketLifecycleManager.PAGE_ORDER);
    // 初始化WebSocket连接
    _initializeWebSocket();
  }
}
```

## 实现效果

### 修复前
```
[WebSocketManager] ⚠️ 收到其他桌台(0)的消息，当前桌台(5),消息类型(heartbeat)，跳过处理
[WebSocketManager] ⚠️ 收到其他桌台(0)的消息，当前桌台(3),消息类型(heartbeat)，跳过处理
```

### 修复后
```
[WebSocketLifecycleManager] 🔄 页面切换: null -> takeaway
[WebSocketLifecycleManager] 🧹 桌台页面：已清理所有WebSocket连接
```

## 最佳实践

### 1. 页面切换时自动清理

每个页面在 `onInit()` 时设置页面类型，在 `onClose()` 时清理连接：

```dart
@override
void onInit() {
  super.onInit();
  wsLifecycleManager.setCurrentPageType(WebSocketLifecycleManager.PAGE_TAKEAWAY);
}

@override
void onClose() {
  wsLifecycleManager.cleanupAllConnections();
  super.onClose();
}
```

### 2. 检查连接状态

```dart
// 检查是否需要WebSocket连接
bool needsConnection = wsLifecycleManager.needsWebSocketConnection();

// 获取连接状态信息
Map<String, dynamic> status = wsLifecycleManager.getConnectionStatus();
```

### 3. 调试和监控

```dart
// 获取详细的连接状态
Map<String, dynamic> status = wsLifecycleManager.getConnectionStatus();
print('当前页面类型: ${status['current_page_type']}');
print('需要WebSocket: ${status['needs_websocket']}');
print('WebSocket统计: ${status['websocket_stats']}');
```

## 注意事项

1. **页面类型设置**：确保在页面初始化时正确设置页面类型
2. **连接清理**：页面关闭时及时清理WebSocket连接
3. **错误处理**：WebSocket操作包含在try-catch块中，避免异常影响页面功能
4. **性能考虑**：避免频繁的连接建立和断开操作

## 测试验证

### 1. 功能测试
- 从点餐页面切换到桌台页面，检查WebSocket连接是否被清理
- 从桌台页面切换到点餐页面，检查WebSocket连接是否正常建立
- 检查日志输出，确认没有收到其他桌台的消息

### 2. 性能测试
- 监控内存使用情况，确保连接清理后内存得到释放
- 检查网络连接数，确保没有多余的WebSocket连接

### 3. 日志验证
```
[WebSocketLifecycleManager] 🔄 页面切换: order -> takeaway
[WebSocketLifecycleManager] 🧹 桌台页面：已清理所有WebSocket连接
[WebSocketManager] 🔌 所有桌台连接已断开
```

## 总结

通过引入WebSocket生命周期管理器，解决了桌台页面收到不必要WebSocket消息的问题，提高了应用的性能和用户体验。该方案具有以下优势：

1. **统一管理**：集中管理所有页面的WebSocket连接状态
2. **自动清理**：页面切换时自动清理不需要的连接
3. **类型安全**：通过页面类型枚举确保正确的连接管理
4. **易于维护**：清晰的API和文档，便于后续维护和扩展
