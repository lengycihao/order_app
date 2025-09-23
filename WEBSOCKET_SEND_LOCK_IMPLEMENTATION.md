# WebSocket发送锁机制实现总结

## 🎯 需求分析

用户需求：**在点餐页面的WebSocket发送消息改成在收到回复消息之前不可以再次发送消息**

### 问题背景
- 用户快速点击添加菜品时，可能会发送多个重复的WebSocket消息
- 在收到服务器回复之前，应该阻止新的消息发送
- 需要确保消息的有序性和可靠性

## ✅ 实现方案

### 1. 发送锁机制设计

在 `WebSocketHandler` 中添加了发送锁机制：

```dart
// 发送锁机制 - 防止在收到回复前重复发送消息
bool _isSendingMessage = false;
Timer? _sendTimeoutTimer;
static const Duration _sendTimeout = Duration(seconds: 10); // 10秒超时解锁
```

### 2. 核心方法实现

#### 锁定发送状态
```dart
void _lockSending() {
  if (_isSendingMessage) {
    logDebug('⚠️ 已有消息正在发送中，跳过本次发送', tag: _logTag);
    return;
  }
  
  _isSendingMessage = true;
  logDebug('🔒 锁定发送状态，防止重复发送', tag: _logTag);
  
  // 设置超时解锁
  _sendTimeoutTimer?.cancel();
  _sendTimeoutTimer = Timer(_sendTimeout, () {
    logDebug('⏰ 发送超时，自动解锁', tag: _logTag);
    _unlockSending();
  });
}
```

#### 解锁发送状态
```dart
void _unlockSending() {
  if (!_isSendingMessage) {
    return;
  }
  
  _isSendingMessage = false;
  _sendTimeoutTimer?.cancel();
  _sendTimeoutTimer = null;
  logDebug('🔓 解锁发送状态，允许下次发送', tag: _logTag);
}
```

#### 检查是否可以发送
```dart
bool _canSendMessage() {
  if (_isSendingMessage) {
    logDebug('❌ 当前有消息正在发送中，请等待回复后再试', tag: _logTag);
    return false;
  }
  return true;
}
```

### 3. 消息发送方法修改

所有WebSocket发送方法都添加了锁检查：

#### 添加菜品
```dart
Future<bool> sendAddDish({...}) async {
  // 检查是否可以发送消息
  if (!_canSendMessage()) {
    return false;
  }
  
  try {
    // 锁定发送状态
    _lockSending();
    
    final success = await _wsManager.sendAddDishToCart(...);
    
    if (success) {
      logDebug('📤 添加菜品到WebSocket: ${dish.name} x$quantity', tag: _logTag);
    } else {
      logDebug('❌ 添加菜品同步到WebSocket失败', tag: _logTag);
      // 发送失败时解锁
      _unlockSending();
    }
    
    return success;
  } catch (e) {
    logDebug('❌ 同步添加菜品到WebSocket异常: $e', tag: _logTag);
    // 异常时解锁
    _unlockSending();
    return false;
  }
}
```

#### 更新数量
```dart
Future<bool> sendUpdateQuantity({...}) async {
  // 检查是否可以发送消息
  if (!_canSendMessage()) {
    return false;
  }

  try {
    // 锁定发送状态
    _lockSending();
    
    final success = await _wsManager.sendUpdateDishQuantity(...);
    
    if (success) {
      logDebug('📤 更新菜品数量已同步到WebSocket: ${cartItem.dish.name} x$quantity', tag: _logTag);
    } else {
      logDebug('❌ 更新菜品数量同步到WebSocket失败', tag: _logTag);
      // 发送失败时解锁
      _unlockSending();
    }
    
    return success;
  } catch (e) {
    logDebug('❌ 同步更新菜品数量到WebSocket异常: $e', tag: _logTag);
    // 异常时解锁
    _unlockSending();
    return false;
  }
}
```

### 4. 回复消息处理

在收到 `cart_response` 消息时自动解锁：

```dart
void _handleCartResponseMessage(Map<String, dynamic> data) {
  try {
    final code = data['code'] as int?;
    final message = data['message'] as String?;
    
    if (code != null && message != null) {
      // 收到任何回复都解锁，允许下次发送
      _unlockSending();
      
      if (code == 0) {
        // 操作成功
        onCartUpdate?.call();
      } else if (code == 409) {
        // 需要强制操作确认
        onForceUpdateRequired?.call(message, data);
      } else {
        // 其他操作失败
        onOperationError?.call(code, message);
      }
    }
  } catch (e) {
    // 异常时也要解锁
    _unlockSending();
  }
}
```

### 5. 超时保护机制

- **10秒超时**：防止锁死，如果10秒内没有收到回复，自动解锁
- **自动清理**：超时后自动停止锁定状态
- **异常处理**：任何异常都会触发解锁

### 6. 控制器层处理

在 `OrderController` 中处理发送失败的情况：

#### 添加菜品失败处理
```dart
_wsHandler.sendAddDish(...).then((success) {
  if (!success) {
    logDebug('❌ WebSocket发送失败，停止loading状态', tag: OrderConstants.logTag);
    _stopCartOperationLoading();
    _setCartOperationStatus('发送失败，请重试');
  } else {
    logDebug('📤 WebSocket消息已发送: ${dish.name}', tag: OrderConstants.logTag);
  }
}).catchError((error) {
  logDebug('❌ WebSocket发送异常: $error', tag: OrderConstants.logTag);
  _stopCartOperationLoading();
  _setCartOperationStatus('发送异常，请重试');
});
```

#### 删除菜品失败处理
```dart
_wsHandler.sendDeleteDish(cartItem).then((success) {
  if (!success) {
    logDebug('❌ WebSocket删除失败，恢复购物车项', tag: OrderConstants.logTag);
    // 发送失败时恢复购物车项
    cart[cartItem] = _lastOperationCartItem != null ? 1 : 0;
    cart.refresh();
    update();
    _stopCartOperationLoading();
    _setCartOperationStatus('删除失败，请重试');
  }
}).catchError((error) {
  // 异常时恢复购物车项
  cart[cartItem] = _lastOperationCartItem != null ? 1 : 0;
  cart.refresh();
  update();
  _stopCartOperationLoading();
  _setCartOperationStatus('删除异常，请重试');
});
```

### 7. 防抖管理器更新

在 `WebSocketDebounceManager` 中也添加了失败处理：

```dart
switch (operation.type) {
  case OperationType.update:
    _wsHandler.sendUpdateQuantity(...).then((success) {
      if (!success) {
        logDebug('❌ WebSocket防抖操作发送失败: 更新数量 ${operation.cartItem!.dish.name}', tag: _logTag);
      } else {
        logDebug('📤 执行WebSocket防抖操作: 更新数量 ${operation.cartItem!.dish.name} -> ${operation.quantity}', tag: _logTag);
      }
    }).catchError((error) {
      logDebug('❌ WebSocket防抖操作异常: 更新数量 ${operation.cartItem!.dish.name}, 错误: $error', tag: _logTag);
    });
    break;
}
```

## 🔧 技术特性

### 1. 发送锁机制
- ✅ **防重复发送**：在收到回复前阻止新消息发送
- ✅ **状态检查**：每次发送前检查锁状态
- ✅ **自动解锁**：收到回复后自动解锁

### 2. 超时保护
- ✅ **10秒超时**：防止锁死状态
- ✅ **自动清理**：超时后自动解锁
- ✅ **计时器管理**：及时取消超时计时器

### 3. 异常处理
- ✅ **发送失败解锁**：发送失败时立即解锁
- ✅ **异常解锁**：任何异常都会触发解锁
- ✅ **状态恢复**：失败时恢复UI状态

### 4. 用户体验
- ✅ **即时反馈**：发送失败时立即提示用户
- ✅ **状态恢复**：失败时恢复购物车状态
- ✅ **错误提示**：显示具体的错误信息

## 📊 覆盖范围

### 修改的文件
1. **`websocket_handler.dart`** - 核心发送锁机制
2. **`order_controller.dart`** - 控制器层失败处理
3. **`websocket_debounce_manager.dart`** - 防抖管理器更新

### 覆盖的操作
- ✅ **添加菜品**：`sendAddDish()`
- ✅ **更新数量**：`sendUpdateQuantity()`
- ✅ **减少数量**：`sendDecreaseQuantity()`
- ✅ **删除菜品**：`sendDeleteDish()`
- ✅ **清空购物车**：`sendClearCart()`

## 🎉 实现效果

### 用户体验提升
- ✅ **防止重复操作**：快速点击时不会发送重复消息
- ✅ **状态一致性**：UI状态与服务器状态保持一致
- ✅ **错误恢复**：发送失败时自动恢复状态

### 技术指标改善
- ✅ **消息有序性**：确保消息按顺序发送和接收
- ✅ **可靠性提升**：减少重复消息和状态不一致
- ✅ **超时保护**：防止锁死状态

### 日志输出
- ✅ **详细日志**：记录锁定、解锁、发送、失败等状态
- ✅ **错误追踪**：便于调试和问题排查
- ✅ **状态监控**：实时监控发送状态

## 🔍 使用示例

### 正常流程
1. 用户点击添加菜品
2. 检查发送锁状态 → 未锁定
3. 锁定发送状态
4. 发送WebSocket消息
5. 收到服务器回复
6. 自动解锁发送状态
7. 允许下次发送

### 重复点击流程
1. 用户第一次点击添加菜品
2. 锁定发送状态，发送消息
3. 用户第二次点击添加菜品
4. 检查发送锁状态 → 已锁定
5. 跳过发送，记录日志
6. 收到第一次操作的回复
7. 自动解锁，允许下次发送

### 超时流程
1. 用户点击添加菜品
2. 锁定发送状态，发送消息
3. 10秒内未收到回复
4. 超时计时器触发
5. 自动解锁发送状态
6. 记录超时日志

这个实现确保了WebSocket消息的有序发送，防止了重复消息的问题，同时提供了完善的错误处理和超时保护机制。
