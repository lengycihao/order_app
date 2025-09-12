# WebSocket使用示例

## 新的架构说明

### 📁 **文件结构**
- `websocket_util.dart` - 底层连接管理（单例）
- `websocket_manager.dart` - 业务逻辑管理（单例）

### 🔄 **消息格式**
严格按照你提供的JSON格式：
```json
{
    "id": "1755739492876irb4lh",  // 20位随机字符串
    "type": "cart",               // 业务类型
    "data": {                     // 具体业务数据
        "action": "add",          // 业务操作
        "options": [...],         // 菜品规格
        "dish_id": 2,            // 菜品ID
        "quantity": 1,           // 数量
        "force_operate": true    // 是否强势操作
    },
    "timestamp": 1755739492      // 时间戳
}
```

## 使用示例

### 1. 初始化连接

```dart
import 'package:lib_base/lib/utils/websocket_manager.dart';

// 初始化桌台连接
final success = await wsManager.initializeTableConnection(
  tableId: '6',
  serverUrl: 'ws://129.204.154.113:8050/api/waiter/ws', // 可选，有默认值
  token: 'your_token_here', // 可选
);

if (success) {
  print('✅ 桌台6连接成功');
} else {
  print('❌ 桌台6连接失败');
}
```

### 2. 发送消息

#### 添加菜品到购物车
```dart
// 基本添加
await wsManager.sendAddDishToCart(
  tableId: '6',
  dishId: 2,
  quantity: 1,
);

// 带规格的添加
await wsManager.sendAddDishToCart(
  tableId: '6',
  dishId: 2,
  quantity: 1,
  options: [
    DishOption(
      id: 3,
      itemIds: [7],
      customValues: [],
    ),
    DishOption(
      id: 4,
      itemIds: [9],
      customValues: [],
    ),
  ],
  forceOperate: true, // 强势添加
);
```

#### 添加临时菜品
```dart
await wsManager.sendAddTempDishToCart(
  tableId: '6',
  dishId: 2,
  quantity: 1,
  options: [
    DishOption(id: 3, itemIds: [7]),
  ],
);
```

#### 更新菜品数量
```dart
await wsManager.sendUpdateDishQuantity(
  tableId: '6',
  dishId: 2,
  quantity: 3, // 更新为3份
  options: [
    DishOption(id: 3, itemIds: [7]),
  ],
);
```

#### 删除菜品
```dart
await wsManager.sendDeleteDish(
  tableId: '6',
  dishId: 2,
  options: [
    DishOption(id: 3, itemIds: [7]),
  ],
);
```

#### 清空购物车
```dart
await wsManager.sendClearCart(
  tableId: '6',
  forceOperate: true,
);
```

#### 刷新购物车
```dart
await wsManager.sendRefreshCart(
  tableId: '6',
);
```

### 3. 接收服务器消息

```dart
// 添加服务器消息监听器
wsManager.addServerMessageListener((tableId, message) {
  final type = message['type'];
  final data = message['data'];
  
  if (type == 'cart') {
    final action = data['action'];
    switch (action) {
      case 'add':
        print('➕ 收到菜品添加消息: $data');
        // 处理菜品添加逻辑
        break;
      case 'update':
        print('🔄 收到菜品更新消息: $data');
        // 处理菜品更新逻辑
        break;
      case 'delete':
        print('🗑️ 收到菜品删除消息: $data');
        // 处理菜品删除逻辑
        break;
      case 'clear':
        print('🧹 收到购物车清空消息: $data');
        // 处理购物车清空逻辑
        break;
      case 'refresh':
        print('🔄 收到购物车刷新消息: $data');
        // 处理购物车刷新逻辑
        break;
    }
  }
});
```

### 4. 连接管理

#### 多桌台管理
```dart
// 连接多个桌台
await wsManager.initializeTableConnection(tableId: '6');
await wsManager.initializeTableConnection(tableId: '7');
await wsManager.initializeTableConnection(tableId: '8');

// 切换活跃桌台
wsManager.switchActiveTable('7');

// 检查桌台连接状态
final isConnected = wsManager.isTableConnected('6');
final connectionState = wsManager.getTableConnectionState('6');

// 获取连接统计
final stats = wsManager.connectionStats;
print('连接统计: $stats');
```

#### 断开连接
```dart
// 断开指定桌台
await wsManager.disconnectTable('6');

// 断开所有连接
await wsManager.disconnectAll();
```

### 5. 在OrderController中使用

```dart
class OrderController extends GetxController {
  final String tableId = '6';
  
  @override
  void onInit() {
    super.onInit();
    _initializeWebSocket();
    _setupMessageListener();
  }
  
  // 初始化WebSocket连接
  Future<void> _initializeWebSocket() async {
    final success = await wsManager.initializeTableConnection(
      tableId: tableId,
      token: 'your_token_here',
    );
    
    if (success) {
      print('✅ WebSocket连接成功');
    } else {
      print('❌ WebSocket连接失败');
    }
  }
  
  // 设置消息监听器
  void _setupMessageListener() {
    wsManager.addServerMessageListener((tableId, message) {
      if (tableId == this.tableId) {
        _handleServerMessage(message);
      }
    });
  }
  
  // 处理服务器消息
  void _handleServerMessage(Map<String, dynamic> message) {
    final type = message['type'];
    final data = message['data'];
    
    if (type == 'cart') {
      final action = data['action'];
      // 根据action更新本地购物车数据
      _updateLocalCart(data);
    }
  }
  
  // 添加菜品到购物车
  Future<void> addDishToCart(int dishId, int quantity, List<DishOption> options) async {
    final success = await wsManager.sendAddDishToCart(
      tableId: tableId,
      dishId: dishId,
      quantity: quantity,
      options: options,
    );
    
    if (success) {
      print('✅ 菜品添加消息发送成功');
    } else {
      print('❌ 菜品添加消息发送失败');
    }
  }
  
  // 更新菜品数量
  Future<void> updateDishQuantity(int dishId, int quantity, List<DishOption> options) async {
    final success = await wsManager.sendUpdateDishQuantity(
      tableId: tableId,
      dishId: dishId,
      quantity: quantity,
      options: options,
    );
    
    if (success) {
      print('✅ 菜品数量更新消息发送成功');
    } else {
      print('❌ 菜品数量更新消息发送失败');
    }
  }
  
  // 删除菜品
  Future<void> removeDishFromCart(int dishId, List<DishOption> options) async {
    final success = await wsManager.sendDeleteDish(
      tableId: tableId,
      dishId: dishId,
      options: options,
    );
    
    if (success) {
      print('✅ 菜品删除消息发送成功');
    } else {
      print('❌ 菜品删除消息发送失败');
    }
  }
  
  // 清空购物车
  Future<void> clearCart() async {
    final success = await wsManager.sendClearCart(
      tableId: tableId,
    );
    
    if (success) {
      print('✅ 购物车清空消息发送成功');
    } else {
      print('❌ 购物车清空消息发送失败');
    }
  }
  
  @override
  void onClose() {
    // 清理资源
    wsManager.dispose();
    super.onClose();
  }
}
```

## 消息类型说明

### 业务类型 (type)
- `cart` - 购物车相关操作

### 操作类型 (action)
- `add` - 添加菜品
- `add_temp` - 添加临时菜品
- `update` - 更新菜品数量
- `delete` - 删除菜品
- `clear` - 清空购物车
- `refresh` - 刷新购物车（服务器推送）

### 菜品规格 (options)
```dart
DishOption(
  id: 3,                    // 规格名称ID
  itemIds: [7],            // 规格值ID列表
  customValues: [],        // 自定义值（暂时不用）
)
```

## 注意事项

1. **消息ID**: 自动生成20位随机字符串
2. **时间戳**: 自动使用当前时间戳（秒）
3. **连接管理**: 支持多桌台同时连接
4. **错误处理**: 所有操作都有完整的错误处理
5. **资源清理**: 页面销毁时记得调用`dispose()`

## 调试信息

系统会输出详细的调试信息：
- 🔌 连接状态变化
- 📤 消息发送
- 📨 消息接收
- ❌ 错误信息
- ✅ 成功操作

这样你就可以轻松实现多人点餐的实时同步功能了！🎉
