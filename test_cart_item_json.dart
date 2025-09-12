import 'dart:convert';
import 'packages/lib_domain/lib/entrity/cart/cart_item_model.dart';

void main() {
  // 从日志中提取的CartItem JSON示例
  final cartItemJsonString = '''
  {
    "id": 419,
    "cart_specification_id": "419-0",
    "dish_id": 5,
    "name": "蒸蛋面条",
    "quantity": 1,
    "status": 1,
    "price": 0,
    "menu_price": 0,
    "price_increment": 0,
    "tax_rate": 6,
    "unit_price": 0,
    "image": "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400&h=300&fit=crop&crop=center",
    "allergens": [
      {
        "label": "花生",
        "id": 1,
        "icon": "https://testkt.oss-cn-shanghai.aliyuncs.com/huansheng.png"
      }
    ],
    "options_str": "",
    "options": null,
    "source": 2,
    "type": 1,
    "waiter_id": 1,
    "customer_id": 0,
    "browser_fingerprint_hash": ""
  }
  ''';
  
  try {
    final jsonData = json.decode(cartItemJsonString);
    print('✅ CartItem JSON解析成功: ${jsonData.keys}');
    
    final cartItemModel = CartItemModel.fromJson(jsonData);
    print('✅ CartItemModel转换成功');
    print('✅ cartId: ${cartItemModel.cartId}');
    print('✅ dishId: ${cartItemModel.dishId}');
    print('✅ dishName: ${cartItemModel.dishName}');
    print('✅ price: ${cartItemModel.price}');
    print('✅ quantity: ${cartItemModel.quantity}');
    print('✅ image: ${cartItemModel.image}');
    print('✅ status: ${cartItemModel.status}');
    
  } catch (e, stackTrace) {
    print('❌ CartItem转换失败: $e');
    print('❌ 堆栈跟踪: $stackTrace');
  }
}

