import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lib_base/lib_base.dart';
import 'package:lib_domain/api/cart_api.dart';
import 'package:lib_domain/entrity/cart/cart_info_model.dart';
import '../model/dish.dart';
import 'order_constants.dart';
import 'models.dart';

/// 购物车管理器
class CartManager {
  final CartApi _cartApi = CartApi();
  final String _logTag;
  
  // 购物车刷新防抖器
  Timer? _cartRefreshTimer;
  
  // 防抖处理 - 存储操作的Timer  
  final Map<String, Timer> _debounceTimers = {};

  CartManager({required String logTag}) : _logTag = logTag;

  /// 防抖操作 - 防止用户快速连续点击
  void debounceOperation(String key, VoidCallback operation, {int milliseconds = OrderConstants.debounceTimeMs}) {
    // 取消之前的定时器
    _debounceTimers[key]?.cancel();
    
    // 设置新的定时器
    _debounceTimers[key] = Timer(Duration(milliseconds: milliseconds), () {
      operation();
      _debounceTimers.remove(key);
    });
  }

  /// 从API加载购物车数据
  Future<CartInfoModel?> loadCartFromApi(String tableId) async {
    try {
      final result = await _cartApi.getCartInfo(tableId: tableId);
      
      if (result.isSuccess && result.data != null) {
        return result.data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// 将API购物车数据转换为本地购物车格式
  Map<CartItem, int> convertApiCartToLocalCart({
    required CartInfoModel? cartInfo,
    required List<Dish> dishes,
    required List<String> categories,
  }) {
    if (cartInfo?.items == null || cartInfo!.items!.isEmpty) {
      logDebug('🛒 服务器购物车为空，返回空购物车', tag: _logTag);
      return {};
    }
    
    logDebug('🔄 开始转换购物车数据，共${cartInfo.items!.length}个商品，当前菜品列表有${dishes.length}个菜品', tag: _logTag);
    
    // 创建新的购物车映射
    final newCart = <CartItem, int>{};
    int validItemCount = 0;
    int invalidItemCount = 0;
    
    for (var apiCartItem in cartInfo.items!) {
      logDebug('🔄 转换购物车商品: ${apiCartItem.dishName} (ID: ${apiCartItem.dishId}) x${apiCartItem.quantity}', tag: _logTag);
      
      // 从现有菜品列表中查找对应的菜品
      Dish? existingDish;
      try {
        existingDish = dishes.firstWhere(
          (dish) => dish.id == (apiCartItem.dishId ?? 0).toString(),
        );
        // logDebug('✅ 找到对应菜品: ${existingDish.name}', tag: _logTag);
      } catch (e) {
        logDebug('⚠️ 未找到对应菜品ID: ${apiCartItem.dishId}，使用API数据创建临时菜品', tag: _logTag);
        
        // 计算正确的categoryId
        int correctCategoryId = _calculateCategoryId(apiCartItem, categories);
        
        // 如果找不到对应的菜品，创建一个临时的菜品对象
        existingDish = Dish(
          id: (apiCartItem.dishId ?? 0).toString(),
          name: apiCartItem.dishName ?? '',
          price: apiCartItem.price ?? 0.0,
          image: apiCartItem.image ?? OrderConstants.defaultDishImage,
          categoryId: correctCategoryId,
          allergens: [],
          options: [],
          tags: null, // 临时菜品没有tags信息
          dishType: apiCartItem.dishType ?? 1, // 传递菜品类型，默认为正常菜品
        );
        logDebug('🆕 创建临时菜品: ${existingDish.name} (分类ID: $correctCategoryId)', tag: _logTag);
      }
      
      // 创建规格选项映射
      Map<String, List<String>> selectedOptions = _buildSelectedOptions(apiCartItem);
      
      // 创建CartItem
      final localCartItem = CartItem(
        dish: existingDish,
        selectedOptions: selectedOptions,
        cartSpecificationId: apiCartItem.specificationId,
        cartItemId: apiCartItem.cartId, // 购物车项的ID
        cartId: cartInfo.cartId, // 购物车的外层ID
      );
      
      // 添加到新购物车
      final quantity = apiCartItem.quantity ?? 1;
      newCart[localCartItem] = quantity;
      validItemCount++;
      logDebug('✅ 添加到新购物车: ${existingDish.name} x$quantity', tag: _logTag);
    }
    
    // 计算总数量用于调试
    int totalQuantity = newCart.values.fold(0, (sum, quantity) => sum + quantity);
    logDebug('🔢 购物车数据统计 - 有效商品种类: $validItemCount, 无效商品: $invalidItemCount', tag: _logTag);
    logDebug('🔢 购物车数据转换完成: ${newCart.length} 种商品，总数量: $totalQuantity 个', tag: _logTag);
    
    return newCart;
  }

  /// 计算分类ID
  int _calculateCategoryId(dynamic apiCartItem, List<String> categories) {
    if (apiCartItem.tempDishInfo?.categoryId != null) {
      // 尝试在现有分类中找到匹配的分类
      final tempCategoryName = apiCartItem.tempDishInfo!.categoryName;
      if (tempCategoryName != null && tempCategoryName.isNotEmpty) {
        try {
          final correctCategoryId = categories.indexWhere((cat) => cat == tempCategoryName);
          if (correctCategoryId == -1) {
            // 如果找不到匹配的分类，使用第一个分类
            logDebug('⚠️ 未找到匹配的分类名称: $tempCategoryName，使用第一个分类', tag: _logTag);
            return 0;
          } else {
            logDebug('✅ 找到匹配的分类: $tempCategoryName (索引: $correctCategoryId)', tag: _logTag);
            return correctCategoryId;
          }
        } catch (e) {
          logDebug('⚠️ 分类匹配异常: $e，使用第一个分类', tag: _logTag);
          return 0;
        }
      } else {
        logDebug('⚠️ 临时菜品信息中没有分类名称，使用第一个分类', tag: _logTag);
        return 0;
      }
    } else {
      logDebug('⚠️ 临时菜品信息中没有分类ID，使用第一个分类', tag: _logTag);
      return 0;
    }
  }

  /// 构建规格选项映射
  Map<String, List<String>> _buildSelectedOptions(dynamic apiCartItem) {
    Map<String, List<String>> selectedOptions = {};
    if (apiCartItem.specifications != null && apiCartItem.specifications!.isNotEmpty) {
      for (var spec in apiCartItem.specifications!) {
        if (spec.specificationName != null && spec.optionName != null) {
          if (!selectedOptions.containsKey(spec.specificationName!)) {
            selectedOptions[spec.specificationName!] = [];
          }
          selectedOptions[spec.specificationName!]!.add(spec.optionName!);
        }
      }
      logDebug('🏷️ 规格选项: $selectedOptions', tag: _logTag);
    }
    return selectedOptions;
  }

  /// 从服务器刷新购物车数据（带防抖）
  void refreshCartFromServer(VoidCallback refreshCallback) {
    try {
      logDebug('🔄 准备从服务器刷新购物车数据', tag: _logTag);
      
      // 取消之前的刷新计时器
      _cartRefreshTimer?.cancel();
      
      // 设置防抖延迟，给服务器更多时间同步数据
      _cartRefreshTimer = Timer(Duration(milliseconds: OrderConstants.cartRefreshDelayMs), () {
        logDebug('🔄 执行购物车数据刷新', tag: _logTag);
        refreshCallback();
      });
    } catch (e) {
      logDebug('❌ 从服务器刷新购物车数据失败: $e', tag: _logTag);
    }
  }

  /// 清理资源
  void dispose() {
    _cartRefreshTimer?.cancel();
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
  }
}
