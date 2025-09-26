import 'package:get/get.dart';
import 'package:lib_domain/entrity/cart/cart_info_model.dart';
import 'package:lib_base/logging/logging.dart';
import '../../../utils/toast_utils.dart';
import '../model/dish.dart';
import '../order_element/cart_manager.dart';
import '../order_element/local_cart_manager.dart';
import '../order_element/websocket_handler.dart';
import '../order_element/websocket_debounce_manager.dart';
import '../order_element/models.dart';

/// 购物车控制器
/// 负责管理购物车的所有操作
class CartController extends GetxController {
  final String _logTag = 'CartController';
  
  // 购物车数据
  final cart = <CartItem, int>{}.obs;
  var cartInfo = Rx<CartInfoModel?>(null);
  final isLoadingCart = false.obs;
  final isCartOperationLoading = false.obs;
  
  // 管理器
  late final CartManager _cartManager;
  late final LocalCartManager _localCartManager;
  WebSocketHandler? _wsHandler;
  WebSocketDebounceManager? _wsDebounceManager;
  
  // 409强制更新相关
  CartItem? _lastOperationCartItem;
  int? _lastOperationQuantity;

  @override
  void onInit() {
    super.onInit();
    _initializeManagers();
  }

  /// 初始化管理器
  void _initializeManagers() {
    _cartManager = CartManager(logTag: _logTag);
    _localCartManager = LocalCartManager(logTag: _logTag);
    
    // 设置本地购物车管理器的回调
    _localCartManager.setCallbacks(
      onQuantityChanged: _onLocalQuantityChanged,
      onWebSocketSend: _onLocalWebSocketSend,
      onWebSocketFailed: _onLocalWebSocketFailed,
    );
  }

  /// 设置WebSocket处理器
  void setWebSocketHandler(WebSocketHandler wsHandler) {
    _wsHandler = wsHandler;
    _wsDebounceManager = WebSocketDebounceManager(
      wsHandler: wsHandler,
      logTag: _logTag,
    );
    _wsDebounceManager?.setFailureCallback(_onWebSocketDebounceFailed);
  }

  /// 从API加载购物车数据
  Future<void> loadCartFromApi({
    required String tableId,
    int retryCount = 0,
    bool silent = false,
  }) async {
    if (isLoadingCart.value && !silent) {
      logDebug('⏳ 购物车数据正在加载中，跳过重复请求', tag: _logTag);
      return;
    }
    
    // 静默刷新时不设置loading状态，避免显示骨架图
    if (!silent) {
      isLoadingCart.value = true;
    }
    
    try {
      final cartData = await _cartManager.loadCartFromApi(tableId);
      
      if (cartData != null) {
        cartInfo.value = cartData;
        logDebug('✅ 购物车数据加载成功', tag: _logTag);
      } else {
        logDebug('🛒 购物车API返回空数据', tag: _logTag);
      }
    } catch (e) {
      logError('❌ 购物车数据加载异常: $e', tag: _logTag);
    } finally {
      // 静默刷新时不重置loading状态
      if (!silent) {
        isLoadingCart.value = false;
      }
    }
  }

  /// 将API购物车数据转换为本地购物车格式
  void convertApiCartToLocalCart({
    required List<Dish> dishes,
    required List<String> categories,
    required bool isInitialized,
  }) {
    if (cartInfo.value?.items == null || cartInfo.value!.items!.isEmpty) {
      // 服务器购物车为空，但只在非初始化时清空本地购物车
      if (isInitialized) {
        logDebug('🛒 服务器购物车为空，清空本地购物车', tag: _logTag);
        // 取消所有待执行的WebSocket防抖操作
        _wsDebounceManager?.cancelAllPendingOperations();
        // 取消所有待执行的本地购物车防抖操作
        _localCartManager.clearAllPendingOperations();
        cart.clear();
        cart.refresh();
        update();
      } else {
        logDebug('🛒 初始化时服务器购物车为空，保留本地购物车数据', tag: _logTag);
      }
      return;
    }
    
    // 确保菜品数据已加载
    if (dishes.isEmpty) {
      logDebug('⚠️ 菜品数据未加载完成，延迟转换购物车', tag: _logTag);
      Future.delayed(Duration(milliseconds: 500), () {
        if (dishes.isNotEmpty) {
          convertApiCartToLocalCart(
            dishes: dishes,
            categories: categories,
            isInitialized: isInitialized,
          );
        }
      });
      return;
    }
    
    final newCart = _cartManager.convertApiCartToLocalCart(
      cartInfo: cartInfo.value,
      dishes: dishes,
      categories: categories,
    );
    
    // 更新购物车
    cart.clear();
    cart.addAll(newCart);
    cart.refresh();
    update();
    logDebug('✅ 购物车数据已更新: ${cart.length} 种商品', tag: _logTag);
  }

  /// 清空购物车
  void clearCart() {
    _cartManager.debounceOperation('clear_cart', () {
      // 取消所有待执行的WebSocket防抖操作
      _wsDebounceManager?.cancelAllPendingOperations();
      // 取消所有待执行的本地购物车防抖操作
      _localCartManager.clearAllPendingOperations();
      cart.clear();
      update();
      if (_wsHandler != null) {
        _wsHandler!.sendClearCart();
      } else {
        logDebug('⚠️ WebSocket处理器未初始化，跳过清空购物车同步', tag: _logTag);
      }
      logDebug('🧹 购物车已清空', tag: _logTag);
    }, milliseconds: 300);
  }

  /// 添加菜品到购物车
  void addToCart(Dish dish, {Map<String, List<String>>? selectedOptions}) {
    logDebug('📤 添加菜品到购物车: ${dish.name}', tag: _logTag);
    
    // 查找是否已存在相同的购物车项
    CartItem? existingCartItem;
    for (var entry in cart.entries) {
      if (entry.key.dish.id == dish.id && 
          _areOptionsEqual(entry.key.selectedOptions, selectedOptions ?? {})) {
        existingCartItem = entry.key;
        break;
      }
    }
    
    if (existingCartItem != null) {
      // 如果已存在，使用本地购物车管理器增加数量
      final currentQuantity = cart[existingCartItem]!;
      final newQuantity = currentQuantity + 1;
      
      // 保存操作上下文，用于可能的409强制更新
      _lastOperationCartItem = existingCartItem;
      _lastOperationQuantity = newQuantity;
      
      _localCartManager.addDishQuantity(existingCartItem, currentQuantity);
      logDebug('➕ 增加已存在菜品数量: ${dish.name}', tag: _logTag);
    } else {
      // 如果不存在，创建新的购物车项并添加到本地购物车
      final newCartItem = CartItem(
        dish: dish,
        selectedOptions: selectedOptions ?? {},
        cartSpecificationId: null,
        cartItemId: null,
        cartId: null,
      );
      
      // 保存操作上下文，用于可能的409强制更新
      _lastOperationCartItem = newCartItem;
      _lastOperationQuantity = 1;
      
      // 立即添加到本地购物车
      cart[newCartItem] = 1;
      cart.refresh();
      update();
      
      // 发送WebSocket添加消息
      _sendAddDishWebSocket(dish, selectedOptions);
      
      logDebug('➕ 添加新菜品: ${dish.name}', tag: _logTag);
    }
  }

  /// 添加指定数量的菜品到购物车
  void addToCartWithQuantity(Dish dish, {
    required int quantity,
    Map<String, List<String>>? selectedOptions,
  }) {
    logDebug('📤 添加指定数量菜品到购物车: ${dish.name} x$quantity', tag: _logTag);
    
    // 查找是否已存在相同的购物车项
    CartItem? existingCartItem;
    for (var entry in cart.entries) {
      if (entry.key.dish.id == dish.id && 
          _areOptionsEqual(entry.key.selectedOptions, selectedOptions ?? {})) {
        existingCartItem = entry.key;
        break;
      }
    }
    
    if (existingCartItem != null) {
      // 如果已存在，直接增加指定数量
      final currentQuantity = cart[existingCartItem]!;
      final newQuantity = currentQuantity + quantity;
      
      // 保存操作上下文，用于可能的409强制更新
      _lastOperationCartItem = existingCartItem;
      _lastOperationQuantity = newQuantity;
      
      // 立即更新本地购物车状态
      cart[existingCartItem] = newQuantity;
      cart.refresh();
      update();
      
      // 发送WebSocket消息
      _sendAddDishWebSocketWithQuantity(dish, quantity, selectedOptions);
      
      logDebug('➕ 增加已存在菜品数量: ${dish.name} +$quantity = $newQuantity', tag: _logTag);
    } else {
      // 如果不存在，创建新的购物车项并添加到本地购物车
      final newCartItem = CartItem(
        dish: dish,
        selectedOptions: selectedOptions ?? {},
        cartSpecificationId: null,
        cartItemId: null,
        cartId: null,
      );
      
      // 保存操作上下文，用于可能的409强制更新
      _lastOperationCartItem = newCartItem;
      _lastOperationQuantity = quantity;
      
      // 立即添加到本地购物车
      cart[newCartItem] = quantity;
      cart.refresh();
      update();
      
      // 发送WebSocket消息
      _sendAddDishWebSocketWithQuantity(dish, quantity, selectedOptions);
      
      logDebug('➕ 添加新菜品: ${dish.name} x$quantity', tag: _logTag);
    }
  }

  /// 移除购物车项
  void removeFromCart(dynamic item) {
    if (item is CartItem) {
      _removeCartItem(item);
    } else if (item is Dish) {
      _removeDishFromCart(item);
    }
  }

  /// 删除购物车项
  void deleteCartItem(CartItem cartItem) {
    if (!cart.containsKey(cartItem)) return;
    
    // 开始loading状态
    isCartOperationLoading.value = true;
    
    // 保存操作上下文，用于可能的409强制更新和失败回滚
    _lastOperationCartItem = cartItem;
    _lastOperationQuantity = 0; // 删除操作的目标数量为0
    final originalQuantity = cart[cartItem]!; // 保存原始数量用于回滚
    
    // 从本地购物车中移除
    cart.remove(cartItem);
    cart.refresh();
    update();
    
    // 检查是否有必要的ID
    if (cartItem.cartSpecificationId == null || cartItem.cartId == null) {
      logDebug('⚠️ 删除的菜品缺少ID，无法同步到WebSocket: ${cartItem.dish.name}', tag: _logTag);
      isCartOperationLoading.value = false;
      return;
    }
    
    // 同步到WebSocket
    if (_wsHandler != null) {
      _wsHandler!.sendDeleteDish(cartItem).then((success) {
        if (success) {
          logDebug('✅ 删除菜品同步到WebSocket成功: ${cartItem.dish.name}', tag: _logTag);
        } else {
          logDebug('❌ 删除菜品同步到WebSocket失败', tag: _logTag);
          // WebSocket失败，回滚本地购物车
          _rollbackDeleteCartItem(cartItem, originalQuantity);
          GlobalToast.error('删除菜品失败，请重试');
        }
        isCartOperationLoading.value = false;
      }).catchError((error) {
        logDebug('❌ 删除菜品同步到WebSocket异常: $error', tag: _logTag);
        // 异常时也需要回滚本地购物车
        _rollbackDeleteCartItem(cartItem, originalQuantity);
        GlobalToast.error('删除菜品异常，请重试');
        isCartOperationLoading.value = false;
      });
    } else {
      logDebug('⚠️ WebSocket处理器未初始化，跳过删除菜品同步', tag: _logTag);
      isCartOperationLoading.value = false;
    }
    
    logDebug('🗑️ 完全删除购物车项: ${cartItem.dish.name}', tag: _logTag);
  }

  /// 增加购物车项数量
  void addCartItemQuantity(CartItem cartItem) {
    if (!cart.containsKey(cartItem)) return;
    
    // 开始loading状态
    isCartOperationLoading.value = true;
    
    final currentQuantity = cart[cartItem]!;
    final newQuantity = currentQuantity + 1;
    
    // 保存操作上下文，用于可能的409强制更新
    _lastOperationCartItem = cartItem;
    _lastOperationQuantity = newQuantity;
    
    // 使用本地购物车管理器进行本地优先的增减操作
    _localCartManager.addDishQuantity(cartItem, currentQuantity);
    
    logDebug('➕ 本地增加购物车项数量: ${cartItem.dish.name}', tag: _logTag);
    
    // 检查是否有必要的ID
    if (cartItem.cartSpecificationId == null || cartItem.cartId == null) {
      logDebug('⚠️ 增加的菜品缺少ID，无法同步到WebSocket: ${cartItem.dish.name}', tag: _logTag);
      isCartOperationLoading.value = false;
      return;
    }
    
    // 同步到WebSocket
    if (_wsHandler != null) {
      _wsHandler!.sendUpdateQuantity(cartItem: cartItem, quantity: newQuantity).then((success) {
        if (success) {
          logDebug('✅ 增加菜品数量同步到WebSocket成功: ${cartItem.dish.name}', tag: _logTag);
        } else {
          logDebug('❌ 增加菜品数量同步到WebSocket失败', tag: _logTag);
        }
        isCartOperationLoading.value = false;
      }).catchError((error) {
        logDebug('❌ 增加菜品数量同步到WebSocket异常: $error', tag: _logTag);
        isCartOperationLoading.value = false;
      });
    } else {
      logDebug('⚠️ WebSocket处理器未初始化，跳过增加菜品数量同步', tag: _logTag);
      isCartOperationLoading.value = false;
    }
  }

  /// 减少购物车项数量
  void _removeCartItem(CartItem cartItem) {
    if (!cart.containsKey(cartItem)) return;
    
    // 开始loading状态
    isCartOperationLoading.value = true;
    
    final currentQuantity = cart[cartItem]!;
    final newQuantity = currentQuantity - 1;
    
    // 保存操作上下文，用于可能的409强制更新
    _lastOperationCartItem = cartItem;
    _lastOperationQuantity = newQuantity;
    
    // 使用本地购物车管理器进行本地优先的增减操作
    _localCartManager.removeDishQuantity(cartItem, currentQuantity);
    
    logDebug('➖ 本地减少购物车项数量: ${cartItem.dish.name}', tag: _logTag);
    
    // 检查是否有必要的ID
    if (cartItem.cartSpecificationId == null || cartItem.cartId == null) {
      logDebug('⚠️ 减少的菜品缺少ID，无法同步到WebSocket: ${cartItem.dish.name}', tag: _logTag);
      isCartOperationLoading.value = false;
      return;
    }
    
    // 同步到WebSocket
    if (_wsHandler != null) {
      _wsHandler!.sendUpdateQuantity(cartItem: cartItem, quantity: newQuantity).then((success) {
        if (success) {
          logDebug('✅ 减少菜品数量同步到WebSocket成功: ${cartItem.dish.name}', tag: _logTag);
        } else {
          logDebug('❌ 减少菜品数量同步到WebSocket失败', tag: _logTag);
        }
        isCartOperationLoading.value = false;
      }).catchError((error) {
        logDebug('❌ 减少菜品数量同步到WebSocket异常: $error', tag: _logTag);
        isCartOperationLoading.value = false;
      });
    } else {
      logDebug('⚠️ WebSocket处理器未初始化，跳过减少菜品数量同步', tag: _logTag);
      isCartOperationLoading.value = false;
    }
  }

  /// 从购物车中移除菜品
  void _removeDishFromCart(Dish dish) {
    CartItem? targetCartItem;
    
    // 首先查找无规格的版本
    for (var entry in cart.entries) {
      if (entry.key.dish.id == dish.id && entry.key.selectedOptions.isEmpty) {
        targetCartItem = entry.key;
        break;
      }
    }
    
    // 如果没有找到无规格的，就选择第一个匹配的
    if (targetCartItem == null) {
      for (var entry in cart.entries) {
        if (entry.key.dish.id == dish.id) {
          targetCartItem = entry.key;
          break;
        }
      }
    }
    
    if (targetCartItem != null) {
      _removeCartItem(targetCartItem);
    }
  }

  /// 发送添加菜品的WebSocket消息
  Future<void> _sendAddDishWebSocket(Dish dish, Map<String, List<String>>? selectedOptions) async {
    if (_wsHandler == null) {
      logDebug('⚠️ WebSocket处理器未初始化，跳过发送添加菜品消息: ${dish.name}', tag: _logTag);
      return;
    }
    
    try {
      logDebug('🆕 发送WebSocket添加菜品: ${dish.name}', tag: _logTag);
      
      final success = await _wsHandler!.sendAddDish(
        dish: dish,
        quantity: 1,
        selectedOptions: selectedOptions,
      );
      
      if (success) {
        logDebug('✅ WebSocket添加菜品成功: ${dish.name}', tag: _logTag);
      } else {
        logDebug('❌ WebSocket添加菜品失败: ${dish.name}', tag: _logTag);
      }
    } catch (e) {
      logError('❌ 发送WebSocket添加菜品异常: $e', tag: _logTag);
    }
  }

  /// 发送添加指定数量菜品的WebSocket消息
  Future<void> _sendAddDishWebSocketWithQuantity(Dish dish, int quantity, Map<String, List<String>>? selectedOptions) async {
    if (_wsHandler == null) {
      logDebug('⚠️ WebSocket处理器未初始化，跳过发送添加指定数量菜品消息: ${dish.name} x$quantity', tag: _logTag);
      return;
    }
    
    try {
      logDebug('🆕 发送WebSocket添加指定数量菜品: ${dish.name} x$quantity', tag: _logTag);
      
      final success = await _wsHandler!.sendAddDish(
        dish: dish,
        quantity: quantity,
        selectedOptions: selectedOptions,
      );
      
      if (success) {
        logDebug('✅ WebSocket添加指定数量菜品成功: ${dish.name} x$quantity', tag: _logTag);
      } else {
        logDebug('❌ WebSocket添加指定数量菜品失败: ${dish.name} x$quantity', tag: _logTag);
      }
    } catch (e) {
      logError('❌ 发送WebSocket添加指定数量菜品异常: $e', tag: _logTag);
    }
  }

  /// 比较两个选项映射是否相等
  bool _areOptionsEqual(Map<String, List<String>> options1, Map<String, List<String>> options2) {
    if (options1.length != options2.length) return false;
    
    for (var key in options1.keys) {
      if (!options2.containsKey(key)) return false;
      
      final list1 = options1[key]!;
      final list2 = options2[key]!;
      
      if (list1.length != list2.length) return false;
      
      // 对列表进行排序后比较
      final sortedList1 = List<String>.from(list1)..sort();
      final sortedList2 = List<String>.from(list2)..sort();
      
      for (int i = 0; i < sortedList1.length; i++) {
        if (sortedList1[i] != sortedList2[i]) return false;
      }
    }
    
    return true;
  }

  /// 本地数量变化回调
  void _onLocalQuantityChanged(CartItem cartItem, int quantity) {
    logDebug('🔍 本地数量变化: ${cartItem.dish.name} -> $quantity', tag: _logTag);
    
    // 立即更新本地购物车状态
    if (quantity > 0) {
      cart[cartItem] = quantity;
    } else {
      cart.remove(cartItem);
    }
    cart.refresh();
    update();
  }

  /// 本地WebSocket发送回调
  void _onLocalWebSocketSend(CartItem cartItem, int quantity) {
    // 检查是否有必要的ID
    if (cartItem.cartSpecificationId == null || cartItem.cartId == null) {
      logDebug('⚠️ 新菜品缺少ID，跳过WebSocket同步: ${cartItem.dish.name}', tag: _logTag);
      return;
    }
    
    // 统一使用WebSocket防抖管理器发送更新消息
      _wsDebounceManager?.debounceUpdateQuantity(
      cartItem: cartItem,
      quantity: quantity,
    );
    
    logDebug('📤 本地WebSocket发送: ${cartItem.dish.name} -> $quantity', tag: _logTag);
  }

  /// 本地WebSocket失败回调
  void _onLocalWebSocketFailed(CartItem cartItem, int originalQuantity) {
    logDebug('❌ 本地WebSocket失败，已回滚: ${cartItem.dish.name} -> $originalQuantity', tag: _logTag);
  }

  /// WebSocket防抖失败回调
  void _onWebSocketDebounceFailed(CartItem cartItem, int quantity) {
    // 通知本地购物车管理器处理失败
    _localCartManager.handleWebSocketFailure(cartItem);
    logDebug('❌ WebSocket防抖失败，已回滚: ${cartItem.dish.name}', tag: _logTag);
  }

  /// 处理强制更新需求（409状态码）
  void handleForceUpdateRequired(String message, Map<String, dynamic>? data) {
    logDebug('⚠️ 处理409状态码，显示强制更新确认弹窗: $message', tag: _logTag);
    
    // 这里可以显示确认弹窗，用户确认后调用_performForceUpdate
    _performForceUpdate();
  }

  /// 执行强制更新操作
  void _performForceUpdate() {
    logDebug('🔄 执行强制更新操作', tag: _logTag);
    
    try {
      if (_lastOperationCartItem != null && _lastOperationQuantity != null) {
        final cartItem = _lastOperationCartItem!;
        final quantity = _lastOperationQuantity!;
        
        logDebug('✅ 使用保存的操作上下文执行强制更新: ${cartItem.dish.name}, quantity=$quantity', tag: _logTag);
        
        // 检查WebSocket处理器是否已初始化
        if (_wsHandler != null) {
          // 检查是否有cartId和cartSpecificationId
          if (cartItem.cartId != null && cartItem.cartSpecificationId != null) {
            // 有完整的购物车项信息，使用sendUpdateQuantity
            _wsHandler!.sendUpdateQuantity(
              cartItem: cartItem,
              quantity: quantity,
              forceOperate: true,
            );
          } else {
            // 没有购物车项信息，可能是添加操作，使用sendAddDish
            _wsHandler!.sendAddDish(
              dish: cartItem.dish,
              quantity: quantity,
              selectedOptions: cartItem.selectedOptions,
              forceOperate: true,
            );
          }
        } else {
          logDebug('⚠️ WebSocket处理器未初始化，跳过强制更新操作', tag: _logTag);
        }
        
        // 强制更新成功后清理数据
        _lastOperationCartItem = null;
        _lastOperationQuantity = null;
        logDebug('✅ 强制更新操作完成，已清理操作上下文', tag: _logTag);
      } else {
        logDebug('❌ 没有保存的操作上下文，无法执行强制更新', tag: _logTag);
      }
    } catch (e) {
      logError('❌ 执行强制更新操作异常: $e', tag: _logTag);
      
      // 异常时也要清理数据
      _lastOperationCartItem = null;
      _lastOperationQuantity = null;
    }
  }

  /// 强制刷新购物车UI
  void forceRefreshCartUI() {
    logDebug('🔄 强制刷新购物车UI', tag: _logTag);
    cart.refresh();
    update();
    Future.delayed(Duration(milliseconds: 100), () {
      cart.refresh();
      update();
    });
  }

  /// 回滚删除购物车项操作
  void _rollbackDeleteCartItem(CartItem cartItem, int originalQuantity) {
    logDebug('🔙 回滚删除购物车项操作: ${cartItem.dish.name}, 恢复数量: $originalQuantity', tag: _logTag);
    
    // 将菜品重新添加到本地购物车，恢复原始数量
    cart[cartItem] = originalQuantity;
    cart.refresh();
    update();
    
    logDebug('✅ 回滚成功，已重新添加到本地购物车: ${cartItem.dish.name} x$originalQuantity', tag: _logTag);
  }

  /// 计算总数量
  int get totalCount => cart.values.fold(0, (sum, e) => sum + e);
  
  /// 计算总价格
  double get totalPrice => cart.entries.fold(0.0, (sum, e) => sum + e.key.dish.price * e.value);

  /// 获取指定类目的数量
  int getCategoryCount(int categoryIndex) {
    int count = 0;
    cart.forEach((cartItem, quantity) {
      if (cartItem.dish.categoryId == categoryIndex && cartItem.dish.dishType != 3) {
        count += quantity;
      }
    });
    return count;
  }

  @override
  void onClose() {
    _cartManager.dispose();
    _localCartManager.clearAllPendingOperations();
    _wsDebounceManager?.dispose();
    super.onClose();
  }
}
