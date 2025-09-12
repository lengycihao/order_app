# JSON-Model 转换使用指南

HttpResult现在提供了简洁友好的JSON-Model转换方式，让你轻松处理API响应数据。

## 基本模型定义

首先，定义你的数据模型：

```dart
class User {
  final int id;
  final String name;
  final String email;
  final String? avatar;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
  });

  // JSON转换工厂方法
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
    };
  }
}

class Product {
  final int id;
  final String title;
  final double price;
  final String? description;

  Product({
    required this.id,
    required this.title,
    required this.price,
    this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
    );
  }
}
```

## 转换方法

### 1. asModel - 转换为单个模型

```dart
// API返回单个用户数据
final result = await HttpManager.instance.executeGet('/api/user/123');

// 转换为User模型
final userResult = result.asModel<User>(User.fromJson);

if (userResult.isSuccess) {
  final user = userResult.data!;
  print('用户名: ${user.name}');
  print('邮箱: ${user.email}');
} else {
  print('转换失败: ${userResult.msg}');
}
```

### 2. asModelList - 转换为模型列表

```dart
// API返回用户列表
final result = await HttpManager.instance.executeGet('/api/users');

// 转换为User列表
final usersResult = result.asModelList<User>(User.fromJson);

if (usersResult.isSuccess) {
  final users = usersResult.dataList!;
  print('用户数量: ${users.length}');
  
  for (final user in users) {
    print('- ${user.name} (${user.email})');
  }
} else {
  print('转换失败: ${usersResult.msg}');
}
```

### 3. tryAsModel - 安全转换单个模型

```dart
// 安全转换，失败时返回null
final user = result.tryAsModel<User>(User.fromJson);

if (user != null) {
  print('用户名: ${user.name}');
} else {
  print('转换失败或无数据');
}
```

### 4. tryAsModelList - 安全转换模型列表

```dart
// 安全转换，失败时返回空列表
final users = result.tryAsModelList<User>(User.fromJson);

print('用户数量: ${users.length}');

// 可以安全遍历，即使转换失败也不会报错
for (final user in users) {
  print('用户: ${user.name}');
}
```

## 实际使用场景

### 场景1: 获取用户信息

```dart
class UserService {
  static Future<User?> getUserById(int userId) async {
    final result = await HttpManager.instance.executeGet('/api/user/$userId');
    
    // 直接返回转换后的用户，失败时返回null
    return result.tryAsModel<User>(User.fromJson);
  }
  
  static Future<List<User>> getAllUsers() async {
    final result = await HttpManager.instance.executeGet('/api/users');
    
    // 直接返回用户列表，失败时返回空列表
    return result.tryAsModelList<User>(User.fromJson);
  }
}

// 使用
final user = await UserService.getUserById(123);
if (user != null) {
  print('获取到用户: ${user.name}');
}

final users = await UserService.getAllUsers();
print('获取到${users.length}个用户');
```

### 场景2: 带错误处理的转换

```dart
class ProductService {
  static Future<HttpResult<Product>> getProduct(int productId) async {
    final result = await HttpManager.instance.executeGet('/api/product/$productId');
    
    // 返回完整的转换结果，包含错误信息
    return result.asModel<Product>(Product.fromJson);
  }
}

// 使用
final productResult = await ProductService.getProduct(456);

if (productResult.isSuccess) {
  final product = productResult.data!;
  print('产品: ${product.title} - ¥${product.price}');
} else {
  // 可以区分是网络错误还是转换错误
  if (productResult.code == -1) {
    print('数据转换失败: ${productResult.msg}');
  } else {
    print('网络请求失败: ${productResult.msg}');
  }
}
```

### 场景3: 复杂嵌套数据转换

```dart
class OrderItem {
  final Product product;
  final int quantity;

  OrderItem({required this.product, required this.quantity});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
    );
  }
}

class Order {
  final int id;
  final User user;
  final List<OrderItem> items;
  final double total;

  Order({
    required this.id,
    required this.user,
    required this.items,
    required this.total,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(OrderItem.fromJson)
          .toList(),
      total: (json['total'] as num).toDouble(),
    );
  }
}

// 使用
final result = await HttpManager.instance.executeGet('/api/order/789');
final order = result.tryAsModel<Order>(Order.fromJson);

if (order != null) {
  print('订单 ${order.id} - 用户: ${order.user.name}');
  print('商品数量: ${order.items.length}');
  print('总价: ¥${order.total}');
}
```

## 错误处理策略

### 策略1: 快速安全转换（推荐日常使用）

```dart
// 适合不需要详细错误信息的场景
final user = result.tryAsModel<User>(User.fromJson);
final users = result.tryAsModelList<User>(User.fromJson);
```

### 策略2: 完整错误处理（推荐关键业务）

```dart
// 适合需要详细错误信息和状态码的场景
final userResult = result.asModel<User>(User.fromJson);

if (userResult.isSuccess) {
  // 处理成功情况
} else {
  // 根据错误码进行不同处理
  switch (userResult.code) {
    case 404:
      print('用户不存在');
      break;
    case -1:
      print('数据格式错误');
      break;
    default:
      print('请求失败: ${userResult.msg}');
  }
}
```

## 优势特点

1. **类型安全**: 编译时类型检查，避免运行时错误
2. **简洁易用**: 一行代码完成JSON到Model的转换
3. **错误友好**: 提供安全转换和详细错误信息两种方式
4. **性能优化**: 避免重复的JSON解析
5. **向后兼容**: 与现有代码完全兼容

通过这些转换方法，你可以轻松地在网络层和业务层之间进行数据转换，让代码更加简洁和类型安全。