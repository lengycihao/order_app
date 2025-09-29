import 'dart:async';
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

/// 待处理操作模型
class PendingOperation {
  final CartItem cartItem;
  final int quantityChange;
  
  PendingOperation({required this.cartItem, required this.quantityChange});
}

/// 购物车控制器
/// 负责管理购物车的所有操作
/// 设计为可以独立使用，也可以作为其他控制器的组件
class CartController extends GetxController {
  final String _logTag = 'CartController';
  
  // 购物车数据
  final cart = <CartItem, int>{}.obs;
  var cartInfo = Rx<CartInfoModel?>(null);
  final isLoadingCart = false.obs;
  final isCartOperationLoading = false.obs;
  
  // 依赖数据（由外部提供）
  List<Dish> _dishes = [];
  List<String> _categories = [];
  bool _isInitialized = false;
  
  // 管理器
  late final CartManager _cartManager;
  late final LocalCartManager _localCartManager;
  WebSocketHandler? _wsHandler;
  WebSocketDebounceManager? _wsDebounceManager;
  
  // UI防抖相关
  Timer? _uiDebounceTimer;
  final Map<String, PendingOperation> _pendingOperations = {}; // dishKey -> PendingOperation
  static const Duration _uiDebounceDuration = Duration(milliseconds: 700);
  
  // 409强制更新相关
  CartItem? _lastOperationCartItem;
  int? _lastOperationQuantity;
  
  // 消息ID与操作上下文的映射关系（用于409强制更新）
  final Map<String, _OperationContext> _operationContextMap = {};

  @override
  void onInit() {
    super.onInit();
    _initializeManagers();
  }
  
  @override
  void onClose() {
    _uiDebounceTimer?.cancel();
    _cartManager.dispose();
    _localCartManager.clearAllPendingOperations();
    _wsDebounceManager?.dispose();
    super.onClose();
  }
  
  /// 初始化依赖数据
  /// 当作为组件使用时，需要从父控制器获取这些数据
  void initializeDependencies({
    required List<Dish> dishes,
    required List<String> categories,
    required bool isInitialized,
  }) {
    _dishes = dishes;
    _categories = categories;
    _isInitialized = isInitialized;
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
    // 不在这里创建防抖管理器，由外部设置
    // _wsDebounceManager = WebSocketDebounceManager(
    //   wsHandler: wsHandler,
    //   logTag: _logTag,
    // );
    // _wsDebounceManager?.setFailureCallback(_onWebSocketDebounceFailed);
  }

  /// 设置WebSocket防抖管理器
  void setWebSocketDebounceManager(WebSocketDebounceManager wsDebounceManager) {
    _wsDebounceManager = wsDebounceManager;
    // 设置失败回调
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
        
        // 重要：将API数据转换为本地购物车格式
        convertApiCartToLocalCart();
      } else {
        logDebug('🛒 购物车API返回空数据', tag: _logTag);
        
        // API返回空数据时也需要调用转换方法，以正确处理空购物车的逻辑
        convertApiCartToLocalCart();
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
  void convertApiCartToLocalCart() {
    if (cartInfo.value?.items == null || cartInfo.value!.items!.isEmpty) {
      // 服务器购物车为空，但只在非初始化时清空本地购物车
      if (_isInitialized) {
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
    if (_dishes.isEmpty) {
      logDebug('⚠️ 菜品数据未加载完成，延迟转换购物车', tag: _logTag);
      Future.delayed(Duration(milliseconds: 500), () {
        if (_dishes.isNotEmpty) {
          convertApiCartToLocalCart();
        }
      });
      return;
    }
    
    final newCart = _cartManager.convertApiCartToLocalCart(
      cartInfo: cartInfo.value,
      dishes: _dishes,
      categories: _categories,
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

  /// 添加菜品到购物车（带防抖）
  void addToCart(Dish dish, {Map<String, List<String>>? selectedOptions}) {
    print('🛒 CartController.addToCart 被调用: ${dish.name}');
    _addToCartWithDebounce(dish, selectedOptions: selectedOptions);
  }

  /// 移除购物车项（带防抖）
  void removeFromCart(dynamic item) {
    if (item is CartItem) {
      _removeFromCartWithDebounce(item);
    } else if (item is Dish) {
      _removeFromCartWithDebounce(item);
    }
  }

  /// 防抖添加菜品到购物车
  void _addToCartWithDebounce(Dish dish, {Map<String, List<String>>? selectedOptions}) {
    print('🔄 CartController._addToCartWithDebounce 被调用: ${dish.name}');
    final dishKey = _getDishKey(dish, selectedOptions);
    final cartItem = CartItem(dish: dish, selectedOptions: selectedOptions ?? {}, optionsStr: null, apiPrice: null);
    
    // 更新待处理操作
    final existingOperation = _pendingOperations[dishKey];
    if (existingOperation != null) {
      _pendingOperations[dishKey] = PendingOperation(
        cartItem: cartItem, 
        quantityChange: existingOperation.quantityChange + 1
      );
    } else {
      _pendingOperations[dishKey] = PendingOperation(
        cartItem: cartItem, 
        quantityChange: 1
      );
    }
    
    // 立即更新UI
    _updateLocalCartImmediately(dish, 1, selectedOptions);
    
    // 重置防抖计时器
    _uiDebounceTimer?.cancel();
    _uiDebounceTimer = Timer(_uiDebounceDuration, () {
      _flushPendingOperations();
    });
    
    logDebug('📤 防抖添加菜品: ${dish.name}, 待处理: ${_pendingOperations[dishKey]?.quantityChange}', tag: _logTag);
  }

  /// 防抖移除购物车项
  void _removeFromCartWithDebounce(dynamic item) {
    CartItem? cartItem;
    String? dishKey;
    
    if (item is CartItem) {
      cartItem = item;
      dishKey = _getDishKey(cartItem.dish, cartItem.selectedOptions);
    } else if (item is Dish) {
      // 查找对应的CartItem
      for (var entry in cart.entries) {
        if (entry.key.dish.id == item.id) {
          cartItem = entry.key;
          dishKey = _getDishKey(item, cartItem.selectedOptions);
          break;
        }
      }
      if (cartItem == null || dishKey == null) return;
    } else {
      return;
    }
    
    // 更新待处理操作
    final existingOperation = _pendingOperations[dishKey];
    if (existingOperation != null) {
      _pendingOperations[dishKey] = PendingOperation(
        cartItem: cartItem, 
        quantityChange: existingOperation.quantityChange - 1
      );
    } else {
      _pendingOperations[dishKey] = PendingOperation(
        cartItem: cartItem, 
        quantityChange: -1
      );
    }
    
    // 立即更新UI
    _updateLocalCartImmediately(cartItem.dish, -1, cartItem.selectedOptions);
    
    // 重置防抖计时器
    _uiDebounceTimer?.cancel();
    _uiDebounceTimer = Timer(_uiDebounceDuration, () {
      _flushPendingOperations();
    });
    
    logDebug('📤 防抖移除菜品: ${cartItem.dish.name}, 待处理: ${_pendingOperations[dishKey]?.quantityChange}', tag: _logTag);
  }

  /// 立即更新本地购物车UI
  void _updateLocalCartImmediately(Dish dish, int quantityChange, Map<String, List<String>>? selectedOptions) {
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
      final currentQuantity = cart[existingCartItem] ?? 0;
      final newQuantity = (currentQuantity + quantityChange).clamp(0, 999);
      
      if (newQuantity <= 0) {
        cart.remove(existingCartItem);
      } else {
        cart[existingCartItem] = newQuantity;
      }
    } else if (quantityChange > 0) {
      // 创建新的购物车项
      final newCartItem = CartItem(
        dish: dish,
        selectedOptions: selectedOptions ?? {},
        cartSpecificationId: null,
        optionsStr: null,
        cartItemId: null,
        cartId: null,
        apiPrice: null,
      );
      cart[newCartItem] = quantityChange;
    }
    
    cart.refresh();
    update();
  }

  /// 刷新待处理的操作到WebSocket
  void _flushPendingOperations() {
    if (_pendingOperations.isEmpty) return;
    
    logDebug('🚀 刷新待处理操作到WebSocket: ${_pendingOperations.length} 个', tag: _logTag);
    
    for (var entry in _pendingOperations.entries) {
      final pendingOperation = entry.value;
      final quantityChange = pendingOperation.quantityChange;
      
      if (quantityChange == 0) continue;
      
      if (quantityChange > 0) {
        // 添加操作
        _sendAddDishWebSocketWithQuantity(pendingOperation.cartItem.dish, quantityChange, null);
      } else {
        // 减少操作，直接使用保存的CartItem信息
        _sendRemoveDishWebSocketWithQuantity(pendingOperation.cartItem, -quantityChange);
      }
    }
    
    _pendingOperations.clear();
  }

  /// 生成菜品的唯一键
  String _getDishKey(Dish dish, Map<String, List<String>>? selectedOptions) {
    final optionsStr = selectedOptions?.entries
        .map((e) => '${e.key}:${e.value.join(',')}')
        .join('|') ?? '';
    return '${dish.id}|$optionsStr';
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
      // 注意：保存的是增加的数量，而不是总数量
      _lastOperationCartItem = existingCartItem;
      _lastOperationQuantity = quantity; // 保存增加的数量
      
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
        optionsStr: null,
        cartItemId: null,
        cartId: null,
        apiPrice: null,
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
    
    // 保存操作上下文，用于可能的409强制更新
    // 注意：保存的是增加的数量(1)，而不是总数量
    _lastOperationCartItem = cartItem;
    _lastOperationQuantity = 1; // 每次点击只增加1个
    
    final currentQuantity = cart[cartItem]!;
    final newQuantity = currentQuantity + 1;
    
    // 使用本地购物车管理器进行本地优先的增减操作
    _localCartManager.addDishQuantity(cartItem, currentQuantity);
    
    logDebug('➕ 本地增加购物车项数量: ${cartItem.dish.name}', tag: _logTag);
    
    // 检查是否有必要的ID
    if (cartItem.cartSpecificationId == null || cartItem.cartId == null) {
      logDebug('⚠️ 增加的菜品缺少ID，无法同步到WebSocket: ${cartItem.dish.name}', tag: _logTag);
      isCartOperationLoading.value = false;
      return;
    }
    
    // 使用WebSocket防抖管理器进行防抖发送
    if (_wsDebounceManager != null) {
      _wsDebounceManager!.debounceUpdateQuantity(
        cartItem: cartItem,
        quantity: newQuantity,
      );
      
      // 延迟结束loading状态，给防抖一些时间
      Future.delayed(Duration(milliseconds: 100), () {
        isCartOperationLoading.value = false;
      });
      
      logDebug('🔄 使用防抖管理器增加菜品数量: ${cartItem.dish.name}', tag: _logTag);
    } else if (_wsHandler != null) {
      // 回退到直接发送
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

  /// 发送添加指定数量菜品的WebSocket消息
  Future<void> _sendAddDishWebSocketWithQuantity(Dish dish, int quantity, Map<String, List<String>>? selectedOptions) async {
    if (_wsHandler == null) {
      logDebug('⚠️ WebSocket处理器未初始化，跳过发送添加指定数量菜品消息: ${dish.name} x$quantity', tag: _logTag);
      return;
    }
    
    try {
      logDebug('🆕 发送WebSocket添加指定数量菜品: ${dish.name} x$quantity', tag: _logTag);
      
      final messageId = await _wsHandler!.sendAddDish(
        dish: dish,
        quantity: quantity,
        selectedOptions: selectedOptions,
      );
      
      if (messageId != null) {
        // 保存消息ID与操作上下文的映射（用于409强制更新）
        final cartItem = _findOrCreateCartItem(dish, selectedOptions);
        _operationContextMap[messageId] = _OperationContext(
          cartItem: cartItem,
          quantity: quantity,
          selectedOptions: selectedOptions,
        );
        
        logDebug('✅ WebSocket添加指定数量菜品成功: ${dish.name} x$quantity, 消息ID=$messageId', tag: _logTag);
        logDebug('💾 保存操作上下文映射: messageId=$messageId, dish=${dish.name}, quantity=$quantity', tag: _logTag);
        
        // 清理过期的映射（保留最近10分钟的）
        _cleanupExpiredContextMappings();
      } else {
        logDebug('❌ WebSocket添加指定数量菜品失败: ${dish.name} x$quantity', tag: _logTag);
      }
    } catch (e) {
      logError('❌ 发送WebSocket添加指定数量菜品异常: $e', tag: _logTag);
    }
  }

  /// 发送移除指定数量菜品的WebSocket消息
  Future<void> _sendRemoveDishWebSocketWithQuantity(CartItem cartItem, int quantity) async {
    if (_wsHandler == null) {
      logDebug('⚠️ WebSocket处理器未初始化，跳过发送移除指定数量菜品消息: ${cartItem.dish.name} x$quantity', tag: _logTag);
      return;
    }
    
    // 检查是否有必要的ID
    if (cartItem.cartSpecificationId == null || cartItem.cartId == null) {
      logDebug('⚠️ 移除的菜品缺少ID，无法同步到WebSocket: ${cartItem.dish.name}', tag: _logTag);
      return;
    }
    
    try {
      logDebug('🗑️ 发送WebSocket移除指定数量菜品: ${cartItem.dish.name} x$quantity', tag: _logTag);
      
      // 调用减少菜品数量来减少指定数量
      // 注意：sendDecreaseQuantity期望负数表示减少，所以传入-quantity
      final success = await _wsHandler!.sendDecreaseQuantity(
        cartItem: cartItem,
        incrQuantity: -quantity,
      );
      
      if (success) {
        logDebug('✅ WebSocket移除指定数量菜品成功: ${cartItem.dish.name} x$quantity', tag: _logTag);
      } else {
        logDebug('❌ WebSocket移除指定数量菜品失败: ${cartItem.dish.name} x$quantity', tag: _logTag);
      }
    } catch (e) {
      logError('❌ 发送WebSocket移除指定数量菜品异常: $e', tag: _logTag);
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
    
    // 409状态码由OrderController统一处理，这里不需要额外处理
    // 避免重复处理导致的问题
  }


  /// 设置购物车项的数量（用于OrderController调用）
  void setCartItemQuantity(CartItem cartItem, int newQuantity) {
    if (!cart.containsKey(cartItem)) return;
    
    // 直接使用本地购物车管理器设置数量
    _localCartManager.setDishQuantity(cartItem, newQuantity);
    
    logDebug('🔄 设置购物车项数量: ${cartItem.dish.name} -> $newQuantity', tag: _logTag);
  }

  /// 处理WebSocket失败（用于OrderController调用）
  void handleWebSocketFailure(CartItem cartItem) {
    _localCartManager.handleWebSocketFailure(cartItem);
    logDebug('❌ 处理WebSocket失败，已回滚: ${cartItem.dish.name}', tag: _logTag);
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
  
  /// 获取总价格（优先使用接口返回的数据）
  double get totalPrice {
    // 优先使用接口返回的总价
    if (cartInfo.value?.totalPrice != null) {
      return cartInfo.value!.totalPrice!;
    }
    
    // 如果接口没有返回总价，则计算本地购物车总价（兜底逻辑）
    // 注意：这里只计算基础价格，不包含价格增量、税费等
    // 因为API返回的totalPrice可能包含了这些额外费用
    double total = cart.entries.fold(0.0, (sum, e) => sum + e.key.dish.price * e.value);
    // 修复浮点数精度问题，保留2位小数
    return double.parse(total.toStringAsFixed(2));
  }
  
  /// 获取基础总价格（不包含价格增量、税费等额外费用）
  double get baseTotalPrice {
    // 计算本地购物车的基础总价
    double total = cart.entries.fold(0.0, (sum, e) => sum + e.key.dish.price * e.value);
    // 修复浮点数精度问题，保留2位小数
    return double.parse(total.toStringAsFixed(2));
  }
  
  /// 暴露私有字段用于委托模式（只读访问）
  CartItem? get lastOperationCartItem => _lastOperationCartItem;
  int? get lastOperationQuantity => _lastOperationQuantity;

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
  
  /// 查找或创建购物车项（用于操作上下文）
  CartItem _findOrCreateCartItem(Dish dish, Map<String, List<String>>? selectedOptions) {
    // 首先尝试在现有购物车中找到匹配的项
    for (final cartItem in cart.keys) {
      if (cartItem.dish.id == dish.id) {
        // 检查选项是否匹配
        if (_areOptionsEqualForContext(cartItem.selectedOptions, selectedOptions)) {
          return cartItem;
        }
      }
    }
    
    // 如果没找到，创建一个新的CartItem用于上下文保存
    return CartItem(
      dish: dish,
      selectedOptions: selectedOptions ?? {},
      cartSpecificationId: "0", // 临时ID，不会用于实际操作
      cartId: 0,
      apiPrice: null,
    );
  }
  
  /// 比较两个选项映射是否相等（用于上下文匹配）
  bool _areOptionsEqualForContext(Map<String, List<String>>? options1, Map<String, List<String>>? options2) {
    if (options1 == null && options2 == null) return true;
    if (options1 == null || options2 == null) return false;
    if (options1.length != options2.length) return false;
    
    for (final key in options1.keys) {
      if (!options2.containsKey(key)) return false;
      final list1 = options1[key]!;
      final list2 = options2[key]!;
      if (list1.length != list2.length) return false;
      for (int i = 0; i < list1.length; i++) {
        if (list1[i] != list2[i]) return false;
      }
    }
    return true;
  }
  
  /// 清理过期的操作上下文映射
  void _cleanupExpiredContextMappings() {
    final now = DateTime.now();
    final expiredIds = <String>[];
    
    for (final entry in _operationContextMap.entries) {
      if (now.difference(entry.value.createdAt).inMinutes > 10) {
        expiredIds.add(entry.key);
      }
    }
    
    for (final id in expiredIds) {
      _operationContextMap.remove(id);
    }
    
    if (expiredIds.isNotEmpty) {
      logDebug('🧹 清理了${expiredIds.length}个过期的操作上下文映射', tag: _logTag);
    }
  }
  
  /// 根据消息ID查找操作上下文（供OrderController调用）
  _OperationContext? getOperationContextByMessageId(String messageId) {
    return _operationContextMap[messageId];
  }
  
  /// 清理指定消息ID的操作上下文（供OrderController调用）
  void clearOperationContext(String messageId) {
    _operationContextMap.remove(messageId);
  }
}

/// 操作上下文类，用于存储409强制更新所需的信息
class _OperationContext {
  final CartItem cartItem;
  final int quantity;
  final Map<String, List<String>>? selectedOptions;
  final DateTime createdAt;
  
  _OperationContext({
    required this.cartItem,
    required this.quantity,
    this.selectedOptions,
  }) : createdAt = DateTime.now();
}
