# 购物车数据稳定性修复总结

## 问题分析
购物车数据不稳定，经常出现数据丢失的问题，主要原因是：
1. API返回状态码210（数据处理中）时，购物车数据为空
2. 缺乏对状态码210的容错处理机制
3. 购物车数据转换时没有考虑状态码210的情况

## 修复内容

### 1. CartApi 修复 (`packages/lib_domain/lib/api/cart_api.dart`)
- ✅ 添加了 `CartItemModel` 的导入
- ✅ 移除了不存在的 `statusCode` 属性访问
- ✅ 修复了 `HttpResultN.success` 方法调用错误
- ✅ 优化了空数据检查逻辑
- ✅ 添加了对状态码210的特殊处理，返回空购物车而不是错误

### 2. CartManager 修复 (`lib/pages/order/order_element/cart_manager.dart`)
- ✅ 添加了 `CartItemModel` 的导入
- ✅ 在 `loadCartFromApi` 方法中添加了状态码210的特殊处理
- ✅ 当状态码210时返回空购物车而不是null
- ✅ 添加了购物车数据不稳定的重试机制
- ✅ 优化了购物车转换逻辑，避免在状态码210时清空本地购物车

### 3. OrderController 优化 (`lib/pages/order/order_element/order_controller.dart`)
- ✅ 在 `_loadCartFromApi` 方法中添加了重试机制
- ✅ 当购物车为空但本地有数据时，延迟2秒后重试
- ✅ 在 `_convertApiCartToLocalCart` 方法中添加了状态码210的容错处理
- ✅ 避免在状态码210时清空本地购物车

## 核心改进

### 状态码210处理
```dart
// CartApi中
if (result.code == 210) {
  print('⚠️ CartAPI 返回状态码210，数据处理中，返回空购物车');
  final emptyCart = CartInfoModel(
    cartId: null,
    tableId: int.tryParse(tableId),
    items: <CartItemModel>[],
    totalQuantity: 0,
    totalPrice: 0.0,
    createdAt: null,
    updatedAt: null,
  );
  return HttpResultN<CartInfoModel>(
    isSuccess: true,
    code: 210,
    msg: '数据处理中',
    data: emptyCart,
  );
}
```

### 购物车重试机制
```dart
// OrderController中
if ((cartInfo.value?.items == null || cartInfo.value!.items!.isEmpty) && cart.isNotEmpty) {
  logDebug('⚠️ 购物车数据可能不稳定，2秒后重试', tag: OrderConstants.logTag);
  Future.delayed(Duration(seconds: 2), () {
    if (isLoadingCart.value == false) {
      _loadCartFromApi();
    }
  });
}
```

### 容错处理
```dart
// OrderController中
if (cartInfo.value?.items == null || cartInfo.value!.items!.isEmpty) {
  // 检查是否是因为状态码210导致的空购物车
  if (cartInfo.value?.tableId != null && cart.isNotEmpty) {
    logDebug('⚠️ 服务器购物车为空但本地有数据，可能是状态码210，保留本地购物车', tag: OrderConstants.logTag);
    return; // 保留本地购物车，不清空
  } else {
    logDebug('🛒 服务器购物车为空，清空本地购物车', tag: OrderConstants.logTag);
    cart.clear();
    cart.refresh();
    update();
    return;
  }
}
```

## 预期效果
1. **提高稳定性**: 状态码210不再导致购物车数据丢失
2. **自动恢复**: 购物车数据异常时自动重试
3. **用户体验**: 避免用户看到购物车突然变空的情况
4. **数据一致性**: 本地购物车与服务器状态保持同步

## 测试建议
1. 测试状态码210场景下的购物车行为
2. 测试网络不稳定时的购物车重试机制
3. 测试购物车数据转换的准确性
4. 测试多用户同时操作时的数据一致性
