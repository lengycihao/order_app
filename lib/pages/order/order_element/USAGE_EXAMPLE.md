# OrderController 优化版本使用示例

## 基本使用

### 1. 替换原文件

将优化后的文件替换原始文件：

```bash
# 备份原文件
mv order_controller.dart order_controller_backup.dart

# 使用优化版本
mv order_controller_optimized.dart order_controller.dart
```

### 2. 在页面中使用

```dart
import 'package:get/get.dart';
import 'order_controller.dart';

class OrderPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderController>(
      init: OrderController(),
      builder: (controller) {
        return Scaffold(
          body: Column(
            children: [
              // 菜品列表
              Expanded(
                child: ListView.builder(
                  itemCount: controller.filteredDishes.length,
                  itemBuilder: (context, index) {
                    final dish = controller.filteredDishes[index];
                    return ListTile(
                      title: Text(dish.name),
                      subtitle: Text('¥${dish.price}'),
                      trailing: Obx(() => Text('${controller.cart[CartItem(dish: dish)] ?? 0}')),
                      onTap: () => controller.addToCart(dish),
                    );
                  },
                ),
              ),
              // 购物车信息
              Obx(() => Text('总数量: ${controller.totalCount}')),
              Obx(() => Text('总价格: ¥${controller.totalPrice}')),
            ],
          ),
        );
      },
    );
  }
}
```

## 主要功能使用

### 1. 购物车操作

```dart
// 添加菜品到购物车
controller.addToCart(dish);

// 添加带规格的菜品
controller.addToCart(dish, selectedOptions: {
  'size': ['large'],
  'spice': ['medium']
});

// 从购物车移除菜品
controller.removeFromCart(dish);

// 清空购物车
controller.clearCart();
```

### 2. 搜索和筛选

```dart
// 显示搜索框
controller.showSearchBox();

// 隐藏搜索框
controller.hideSearchBox();

// 搜索关键词（自动筛选）
controller.searchKeyword.value = '宫保鸡丁';

// 敏感物筛选
controller.toggleAllergen(allergenId);
controller.clearAllergenSelection();
```

### 3. 数据刷新

```dart
// 刷新菜品数据
await controller.refreshOrderData();

// 强制刷新购物车
await controller.forceRefreshCart();

// 强制刷新UI
controller.forceRefreshCartUI();
```

## 配置自定义

### 1. 修改常量配置

在 `order_constants.dart` 中修改配置：

```dart
class OrderConstants {
  // 修改防抖时间
  static const int debounceTimeMs = 300; // 原来是500ms
  
  // 修改超时时间
  static const int dishLoadingTimeoutSeconds = 15; // 原来是10秒
  
  // 添加新的错误代码
  static const int errorCodeCustom = 999;
}
```

### 2. 自定义错误处理

在 `error_handler.dart` 中添加自定义错误处理：

```dart
void _handleCustomError(int code, String message) {
  // 自定义错误处理逻辑
  if (code == OrderConstants.errorCodeCustom) {
    // 处理自定义错误
  }
}
```

## 扩展功能

### 1. 添加新的WebSocket消息类型

在 `websocket_handler.dart` 中：

```dart
void _routeMessage(String? messageType, Map<String, dynamic>? data) {
  switch (messageType) {
    case 'custom_message':
      _handleCustomMessage(data);
      break;
    // ... 其他消息类型
  }
}

void _handleCustomMessage(Map<String, dynamic>? data) {
  // 处理自定义消息
}
```

### 2. 添加新的数据转换方法

在 `data_converter.dart` 中：

```dart
class DataConverter {
  // 添加新的转换方法
  static String formatPrice(double price) {
    return '¥${price.toStringAsFixed(2)}';
  }
  
  static String formatQuantity(int quantity) {
    return quantity > 99 ? '99+' : quantity.toString();
  }
}
```

## 测试示例

### 1. 单元测试

```dart
import 'package:flutter_test/flutter_test.dart';
import 'order_controller.dart';

void main() {
  group('OrderController Tests', () {
    late OrderController controller;
    
    setUp(() {
      controller = OrderController();
    });
    
    test('should add dish to cart', () {
      final dish = Dish(id: '1', name: 'Test Dish', price: 10.0);
      controller.addToCart(dish);
      
      expect(controller.cart.length, 1);
      expect(controller.totalCount, 1);
    });
    
    test('should calculate total price correctly', () {
      final dish1 = Dish(id: '1', name: 'Dish 1', price: 10.0);
      final dish2 = Dish(id: '2', name: 'Dish 2', price: 20.0);
      
      controller.addToCart(dish1);
      controller.addToCart(dish2);
      
      expect(controller.totalPrice, 30.0);
    });
  });
}
```

### 2. 集成测试

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'order_controller.dart';

void main() {
  group('OrderController Integration Tests', () {
    testWidgets('should display cart items', (WidgetTester tester) async {
      Get.put(OrderController());
      
      await tester.pumpWidget(MyApp());
      
      // 测试UI显示
      expect(find.text('总数量: 0'), findsOneWidget);
      expect(find.text('总价格: ¥0.0'), findsOneWidget);
    });
  });
}
```

## 性能监控

### 1. 添加性能监控

```dart
class OrderController extends GetxController {
  // 添加性能监控
  void _logPerformance(String operation, Function() callback) {
    final stopwatch = Stopwatch()..start();
    callback();
    stopwatch.stop();
    logDebug('$operation 耗时: ${stopwatch.elapsedMilliseconds}ms', tag: OrderConstants.logTag);
  }
  
  void addToCart(Dish dish, {Map<String, List<String>>? selectedOptions}) {
    _logPerformance('添加菜品到购物车', () {
      // 原有逻辑
    });
  }
}
```

### 2. 内存使用监控

```dart
class OrderController extends GetxController {
  @override
  void onClose() {
    // 清理资源
    _wsHandler.dispose();
    _cartManager.dispose();
    
    // 记录内存使用
    logDebug('OrderController 已清理资源', tag: OrderConstants.logTag);
    super.onClose();
  }
}
```

## 注意事项

1. **向后兼容性** - 优化后的API与原版本完全兼容
2. **性能影响** - 优化后性能有所提升，内存使用更少
3. **错误处理** - 错误处理更加统一和友好
4. **日志记录** - 日志更加详细和结构化
5. **测试覆盖** - 建议为每个模块编写单元测试

## 故障排除

### 常见问题

1. **导入错误** - 确保所有依赖文件都在正确位置
2. **类型错误** - 检查模型类定义是否正确
3. **空指针异常** - 确保在使用前检查对象是否为null
4. **WebSocket连接失败** - 检查网络连接和服务器状态

### 调试技巧

1. **启用详细日志** - 在开发环境中启用详细日志
2. **使用调试工具** - 使用Flutter Inspector等工具
3. **性能分析** - 使用Flutter Performance工具分析性能
4. **错误追踪** - 实现错误追踪和报告机制
