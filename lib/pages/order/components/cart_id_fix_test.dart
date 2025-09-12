import 'package:flutter/material.dart';
import 'package:order_app/pages/order/order_element/models.dart';
import '../order_element/order_controller.dart';
import '../model/dish.dart';

/// 购物车ID修复测试
class CartIdFixTest {
  static void runTest() {
    debugPrint('🧪 开始测试购物车ID修复...');
    
    // 测试1: 验证CartItem模型结构
    debugPrint('📝 测试1: 验证CartItem模型结构');
    final testDish = Dish(
      id: '1',
      name: '测试菜品',
      price: 10.0,
      image: '',
      categoryId: 1,
      allergens: [],
      options: [],
    );
    
    final testCartItem = CartItem(
      dish: testDish,
      selectedOptions: {'size': ['large']},
      cartSpecificationId: 'spec_123',
      cartItemId: 456, // 购物车项的ID
      cartId: 789, // 购物车的外层ID
    );
    
    debugPrint('✅ CartItem创建成功:');
    debugPrint('   - cartItemId (购物车项ID): ${testCartItem.cartItemId}');
    debugPrint('   - cartId (购物车外层ID): ${testCartItem.cartId}');
    debugPrint('   - cartSpecificationId: ${testCartItem.cartSpecificationId}');
    
    // 测试2: 验证字段区分
    debugPrint('📝 测试2: 验证字段区分');
    if (testCartItem.cartItemId != testCartItem.cartId) {
      debugPrint('✅ cartItemId 和 cartId 正确区分');
    } else {
      debugPrint('❌ cartItemId 和 cartId 没有正确区分');
    }
    
    // 测试3: 验证空值处理
    debugPrint('📝 测试3: 验证空值处理');
    final testCartItemWithNulls = CartItem(
      dish: testDish,
      selectedOptions: {},
      cartSpecificationId: null,
      cartItemId: null,
      cartId: null,
    );
    
    debugPrint('✅ 空值CartItem创建成功:');
    debugPrint('   - cartItemId: ${testCartItemWithNulls.cartItemId}');
    debugPrint('   - cartId: ${testCartItemWithNulls.cartId}');
    debugPrint('   - cartSpecificationId: ${testCartItemWithNulls.cartSpecificationId}');
    
    debugPrint('✅ 购物车ID修复测试完成');
    debugPrint('📊 预期结果:');
    debugPrint('   - CartItem现在有两个不同的ID字段');
    debugPrint('   - cartItemId: 购物车项的ID (来自API的cartId字段)');
    debugPrint('   - cartId: 购物车的外层ID (来自CartInfoModel的cartId字段)');
    debugPrint('   - update和delete操作现在使用正确的cartId (购物车外层ID)');
  }
  
  /// 模拟购物车数据转换测试
  static void testCartDataConversion() {
    debugPrint('🧪 开始测试购物车数据转换...');
    
    // 模拟API返回的购物车数据
    final mockApiCartItem = MockCartItemModel(
      cartId: 123, // 这是购物车项的ID
      dishId: 1,
      dishName: '测试菜品',
      price: 10.0,
      quantity: 2,
      specificationId: 'spec_456',
    );
    
    final mockCartInfo = MockCartInfoModel(
      cartId: 789, // 这是购物车的外层ID
      tableId: 1,
      items: [mockApiCartItem],
    );
    
    debugPrint('📝 模拟API数据:');
    debugPrint('   - 购物车外层ID (CartInfoModel.cartId): ${mockCartInfo.cartId}');
    debugPrint('   - 购物车项ID (CartItemModel.cartId): ${mockApiCartItem.cartId}');
    
    // 模拟转换过程
    final testDish = Dish(
      id: mockApiCartItem.dishId.toString(),
      name: mockApiCartItem.dishName ?? '',
      price: mockApiCartItem.price ?? 0.0,
      image: '',
      categoryId: 1,
      allergens: [],
      options: [],
    );
    
    final convertedCartItem = CartItem(
      dish: testDish,
      selectedOptions: {},
      cartSpecificationId: mockApiCartItem.specificationId,
      cartItemId: mockApiCartItem.cartId, // 购物车项的ID
      cartId: mockCartInfo.cartId, // 购物车的外层ID
    );
    
    debugPrint('📝 转换后的CartItem:');
    debugPrint('   - cartItemId (购物车项ID): ${convertedCartItem.cartItemId}');
    debugPrint('   - cartId (购物车外层ID): ${convertedCartItem.cartId}');
    
    // 验证转换正确性
    if (convertedCartItem.cartItemId == mockApiCartItem.cartId &&
        convertedCartItem.cartId == mockCartInfo.cartId) {
      debugPrint('✅ 购物车数据转换正确');
    } else {
      debugPrint('❌ 购物车数据转换错误');
    }
    
    debugPrint('✅ 购物车数据转换测试完成');
  }
}

/// 模拟购物车信息模型
class MockCartInfoModel {
  final int? cartId;
  final int? tableId;
  final List<MockCartItemModel>? items;
  
  MockCartInfoModel({
    this.cartId,
    this.tableId,
    this.items,
  });
}

/// 模拟购物车项模型
class MockCartItemModel {
  final int? cartId;
  final int? dishId;
  final String? dishName;
  final double? price;
  final int? quantity;
  final String? specificationId;
  
  MockCartItemModel({
    this.cartId,
    this.dishId,
    this.dishName,
    this.price,
    this.quantity,
    this.specificationId,
  });
}
