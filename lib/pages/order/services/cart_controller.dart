import 'dart:async';
import 'package:get/get.dart';
import 'package:lib_domain/entrity/cart/cart_info_model.dart';
import 'package:lib_base/logging/logging.dart';
import '../../../utils/toast_utils.dart';
import '../model/dish.dart';
import '../order_element/cart_manager.dart';
import '../order_element/websocket_handler.dart';
import 'package:order_app/utils/cart_animation_registry.dart';
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
  final isCartOperationLoading = false.obs; // 保留用于兼容性
  
  // 按菜品ID管理的loading状态
  final dishLoadingStates = <String, bool>{}.obs;
  
  // 按菜品ID管理的14005错误状态（增加按钮禁用状态）
  final dish14005ErrorStates = <String, bool>{}.obs;
  
  /// 检查指定菜品是否正在loading
  bool isDishLoading(String dishId) {
    return dishLoadingStates[dishId] ?? false;
  }
  
  /// 设置指定菜品的loading状态
  void setDishLoading(String dishId, bool isLoading) {
    dishLoadingStates[dishId] = isLoading;
  }
  
  /// 检查指定菜品是否因14005错误而禁用增加按钮
  bool isDishAddDisabled(String dishId) {
    return dish14005ErrorStates[dishId] ?? false;
  }
  
  /// 设置指定菜品的14005错误状态（禁用增加按钮）
  void setDish14005Error(String dishId, bool hasError) {
    dish14005ErrorStates[dishId] = hasError;
    logDebug('🚫 设置菜品14005错误状态: dishId=$dishId, hasError=$hasError', tag: _logTag);
  }
  
  // 依赖数据（由外部提供）
  List<Dish> _dishes = [];
  List<String> _categories = [];
  
  // 管理器
  late final CartManager _cartManager;
  WebSocketHandler? _wsHandler;
  WebSocketDebounceManager? _wsDebounceManager;
  
  // UI防抖相关（用于批量操作）
  Timer? _uiDebounceTimer;
  final Map<String, PendingOperation> _pendingOperations = {};
  
  // 409强制更新相关
  CartItem? _lastOperationCartItem;
  int? _lastOperationQuantity;
  
  // 消息ID与操作上下文的映射关系（用于409强制更新）
  final Map<String, _OperationContext> _operationContextMap = {};
  
  // 智能同步相关
  Timer? _syncTimer;
  bool _isStableSyncInProgress = false;
  static const int _stabilityCheckDelayMs = 2000; // 2秒无操作后认为稳定

  @override
  void onInit() {
    super.onInit();
    _initializeManagers();
  }
  
  @override
  void onClose() {
    _uiDebounceTimer?.cancel();
    _syncTimer?.cancel(); // 清理同步定时器
    _cartManager.dispose();
    _wsDebounceManager?.dispose();
    _responseController.close();
    super.onClose();
  }
  
  /// 初始化依赖数据
  /// 当作为组件使用时，需要从父控制器获取这些数据
  void initializeDependencies({
    required List<Dish> dishes,
    required List<String> categories,
  }) {
    _dishes = dishes;
    _categories = categories;
  }

  /// 初始化管理器
  void _initializeManagers() {
    _cartManager = CartManager(logTag: _logTag);
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
        // logDebug('✅ 购物车数据加载成功', tag: _logTag);
        
        // 重要：将API数据转换为本地购物车格式
        convertApiCartToLocalCart();
      } else {
        logDebug('🛒 购物车API返回空数据', tag: _logTag);
        
        // API返回空数据时也需要调用转换方法，以正确处理空购物车的逻辑
        convertApiCartToLocalCart();
      }
    } catch (e) {
      // 检查是否是210状态码异常（数据处理中）
      if (e.runtimeType.toString().contains('CartProcessingException')) {
        logDebug('⏳ 购物车数据处理中，保留本地数据不清空', tag: _logTag);
        // 210状态码时不做任何操作，保留本地购物车数据
        // 如果是静默刷新，重新抛出异常让调用方处理重试逻辑
        if (silent) {
          rethrow;
        }
        return; // 重要：直接返回，不执行任何清空操作
      }
      logError('❌ 购物车数据加载异常: $e', tag: _logTag);
      // 其他异常也不清空购物车，保持现有状态
    } finally {
      // 静默刷新时不重置loading状态
      if (!silent) {
        isLoadingCart.value = false;
      }
    }
  }

  /// 将API购物车数据转换为本地购物车格式
  void convertApiCartToLocalCart({bool forceRefresh = false}) {
    // 重要：如果cartInfo.value为null，说明API请求失败，不应该清空购物车
    if (cartInfo.value == null) {
      logDebug('⚠️ cartInfo.value为null，API请求失败，保留本地购物车', tag: _logTag);
      return; // 保留本地购物车，不执行任何操作
    }
    
    if (cartInfo.value!.items == null || cartInfo.value!.items!.isEmpty) {
      // 如果是强制刷新模式，直接清空本地购物车，不检查待处理操作
      if (forceRefresh) {
        logDebug('🔄 强制刷新模式：服务器购物车为空，清空本地购物车', tag: _logTag);
        // 取消所有待执行的WebSocket防抖操作
        _wsDebounceManager?.cancelAllPendingOperations();
        // 🔧 修复：强制刷新时也清除所有14005错误状态
        dish14005ErrorStates.clear();
        cart.clear();
        cart.refresh();
        update();
        return;
      }
      
      // 服务器购物车为空，检查是否有待处理的操作
      if (_pendingOperations.isNotEmpty) {
        logDebug('🛒 服务器购物车为空，但有待处理操作，保留本地购物车', tag: _logTag);
        return; // 保留本地购物车，不执行清空操作
      }
      
      // 服务器购物车为空且无待处理操作，清空本地购物车
      logDebug('🛒 服务器购物车为空，清空本地购物车', tag: _logTag);
      // 取消所有待执行的WebSocket防抖操作
      _wsDebounceManager?.cancelAllPendingOperations();
      // 🔧 修复：服务器购物车为空时也清除所有14005错误状态
      dish14005ErrorStates.clear();
      cart.clear();
      cart.refresh();
      update();
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
    // logDebug('✅ 购物车数据已更新: ${cart.length} 种商品', tag: _logTag);
  }

  /// 清空购物车
  void clearCart() {
    _cartManager.debounceOperation('clear_cart', () {
      // 取消所有待执行的WebSocket防抖操作
      _wsDebounceManager?.cancelAllPendingOperations();
      
      // 🔧 修复：清空购物车时清除所有14005错误状态
      dish14005ErrorStates.clear();
      logDebug('🧹 清空购物车时已清除所有14005错误状态', tag: _logTag);
      
      cart.clear();
      update();
      if (_wsHandler != null) {
        _wsHandler!.sendClearCart();
      } else {
        // logDebug('⚠️ WebSocket处理器未初始化，跳过清空购物车同步', tag: _logTag);
      }
      logDebug('🧹 购物车已清空，所有菜品状态已重置', tag: _logTag);
    }, milliseconds: 300);
  }

  /// 添加菜品到购物车（同步操作，无本地更新）
  Future<bool> addToCart(Dish dish, {Map<String, List<String>>? selectedOptions}) async {
    // 检查是否正在操作中
    if (isDishLoading(dish.id)) {
      logDebug('⚠️ 菜品操作进行中，忽略重复点击: ${dish.name}', tag: _logTag);
      return false;
    }
    
    // 立即设置loading状态，防止连续点击
    setDishLoading(dish.id, true);
    
    try {
      // 创建临时CartItem用于操作上下文
      final tempCartItem = CartItem(
        dish: dish,
        selectedOptions: selectedOptions ?? {},
        cartSpecificationId: null,
        optionsStr: null,
        cartItemId: null,
        cartId: null,
        apiPrice: null,
      );
      
      // 保存操作上下文
      _lastOperationCartItem = tempCartItem;
      _lastOperationQuantity = 1;
      
      // 发送WebSocket消息并等待结果
      final success = await _sendAddDishWebSocket(dish, selectedOptions);
      
      if (success) {
        logDebug('✅ 添加菜品成功: ${dish.name}', tag: _logTag);
        // loading状态由handleWebSocketResponse重置，这里不需要重复重置
        return true;
      } else {
        logDebug('❌ 添加菜品失败: ${dish.name}', tag: _logTag);
        // loading状态由handleWebSocketResponse重置，这里不需要重复重置
        return false;
      }
    } catch (e) {
      logDebug('❌ 添加菜品异常: ${dish.name}, error: $e', tag: _logTag);
      // 异常时重置loading状态
      setDishLoading(dish.id, false);
      return false;
    }
  }

  /// 减少菜品数量（同步操作，无本地更新）
  Future<bool> removeFromCart(dynamic item) async {
    // 获取菜品ID用于loading状态管理
    String dishId;
    if (item is CartItem) {
      dishId = item.dish.id;
    } else if (item is Dish) {
      dishId = item.id;
    } else {
      logDebug('⚠️ 无效的item类型', tag: _logTag);
      return false;
    }
    
    // 检查是否正在操作中
    if (isDishLoading(dishId)) {
      final itemName = item is CartItem ? item.dish.name : (item is Dish ? item.name : 'Unknown');
      logDebug('⚠️ 菜品操作进行中，忽略重复点击: $itemName', tag: _logTag);
      return false;
    }
    
    // 立即设置loading状态，防止连续点击
    setDishLoading(dishId, true);
    
    CartItem? cartItem;
    if (item is CartItem) {
      cartItem = item;
    } else if (item is Dish) {
      // 查找对应的CartItem
      try {
        cartItem = cart.keys.firstWhere((ci) => ci.dish.id == item.id);
      } catch (e) {
        cartItem = null;
      }
    }
    
    if (cartItem == null) {
      logDebug('⚠️ 未找到对应的购物车项', tag: _logTag);
      setDishLoading(dishId, false); // 重置loading状态
      return false;
    }
    
    try {
      // 保存操作上下文
      _lastOperationCartItem = cartItem;
      final currentQuantity = cart[cartItem] ?? 0;
      _lastOperationQuantity = currentQuantity - 1;
      
      // 发送WebSocket消息并等待结果
      final success = await _sendReduceQuantityWebSocket(cartItem);
      
      if (success) {
        logDebug('✅ 减少菜品成功: ${cartItem.dish.name}', tag: _logTag);
        // loading状态由handleWebSocketResponse重置，这里不需要重复重置
        return true;
      } else {
        logDebug('❌ 减少菜品失败: ${cartItem.dish.name}', tag: _logTag);
        // loading状态由handleWebSocketResponse重置，这里不需要重复重置
        return false;
      }
    } catch (e) {
      logDebug('❌ 减少菜品异常: ${cartItem.dish.name}, error: $e', tag: _logTag);
      // 异常时重置loading状态
      setDishLoading(dishId, false);
      return false;
    }
  }


  // 已移除：本地即时更新方法（WS优先流程下不再使用）


  /// 添加指定数量的菜品到购物车
  void addToCartWithQuantity(Dish dish, {
    required int quantity,
    Map<String, List<String>>? selectedOptions,
  }) {
    // WS优先：不进行本地数量修改，直接发送WS并保存操作上下文
    CartItem tempCartItem = CartItem(
        dish: dish,
        selectedOptions: selectedOptions ?? {},
        cartSpecificationId: null,
        optionsStr: null,
        cartItemId: null,
        cartId: null,
        apiPrice: null,
      );
      
      // 保存操作上下文，用于可能的409强制更新
    _lastOperationCartItem = tempCartItem;
      _lastOperationQuantity = quantity;
      
      // 发送WebSocket消息
      _sendAddDishWebSocketWithQuantity(dish, quantity, selectedOptions);
      
    logDebug('➕(WS优先) 添加菜品: ${dish.name} x$quantity', tag: _logTag);
  }

  /// 删除购物车项
  void deleteCartItem(CartItem cartItem) {
    if (!cart.containsKey(cartItem)) return;
    
    // 开始loading状态
    setDishLoading(cartItem.dish.id, true);
    
    // 保存操作上下文，用于可能的409强制更新
    _lastOperationCartItem = cartItem;
    _lastOperationQuantity = 0; // 删除操作的目标数量为0
    
    // 从购物车中移除
    cart.remove(cartItem);
    cart.refresh();
    update();
    
    // 检查是否有必要的ID
    if (cartItem.cartSpecificationId == null || cartItem.cartId == null) {
      logDebug('⚠️ 删除的菜品缺少ID，无法同步到WebSocket: ${cartItem.dish.name}', tag: _logTag);
      setDishLoading(cartItem.dish.id, false);
      return;
    }
    
    // 同步到WebSocket
    if (_wsHandler != null) {
      _wsHandler!.sendDeleteDish(cartItem).then((success) {
        if (success) {
          logDebug('✅ 删除菜品同步到WebSocket成功: ${cartItem.dish.name}', tag: _logTag);
        } else {
          logDebug('❌ 删除菜品同步到WebSocket失败', tag: _logTag);
          GlobalToast.error('删除菜品失败，请重试');
        }
        setDishLoading(cartItem.dish.id, false);
      }).catchError((error) {
        logDebug('❌ 删除菜品同步到WebSocket异常: $error', tag: _logTag);
        GlobalToast.error('删除菜品异常，请重试');
        setDishLoading(cartItem.dish.id, false);
      });
    } else {
      logDebug('⚠️ WebSocket处理器未初始化，跳过删除菜品同步', tag: _logTag);
      setDishLoading(cartItem.dish.id, false);
    }
    
    logDebug('🗑️ 完全删除购物车项: ${cartItem.dish.name}', tag: _logTag);
  }

  /// 增加购物车项数量（同步操作，无本地更新）
  Future<bool> addCartItemQuantity(CartItem cartItem) async {
    if (!cart.containsKey(cartItem)) {
      logDebug('⚠️ 购物车中未找到该项: ${cartItem.dish.name}', tag: _logTag);
      return false;
    }
    
    // 检查是否正在操作中
    if (isDishLoading(cartItem.dish.id)) {
      logDebug('⚠️ 菜品操作进行中，忽略重复点击: ${cartItem.dish.name}', tag: _logTag);
      return false;
    }
    
    // 设置操作状态
    setDishLoading(cartItem.dish.id, true);
    
    try {
      // 保存操作上下文
      _lastOperationCartItem = cartItem;
    final currentQuantity = cart[cartItem]!;
      _lastOperationQuantity = currentQuantity + 1;
      
      // 发送WebSocket消息并等待结果
      final success = await _sendAddDishWebSocketWithQuantity(cartItem.dish, 1, cartItem.selectedOptions);
      
        if (success) {
        logDebug('✅ 增加菜品数量成功: ${cartItem.dish.name}', tag: _logTag);
        // loading状态由handleWebSocketResponse重置，这里不需要重复重置
        return true;
        } else {
        logDebug('❌ 增加菜品数量失败: ${cartItem.dish.name}', tag: _logTag);
        // loading状态由handleWebSocketResponse重置，这里不需要重复重置
        return false;
      }
    } catch (e) {
      logDebug('❌ 增加菜品数量异常: ${cartItem.dish.name}, error: $e', tag: _logTag);
      // 异常时重置loading状态
      setDishLoading(cartItem.dish.id, false);
      return false;
    }
  }

  /// 发送添加单个菜品的WebSocket消息并等待响应
  Future<bool> _sendAddDishWebSocket(Dish dish, Map<String, List<String>>? selectedOptions) async {
    return await _sendAddDishWebSocketWithQuantity(dish, 1, selectedOptions);
  }

  /// 发送减少菜品数量的WebSocket消息并等待响应
  Future<bool> _sendReduceQuantityWebSocket(CartItem cartItem) async {
    return await _sendRemoveDishWebSocketWithQuantity(cartItem, 1);
  }

  /// 发送添加指定数量菜品的WebSocket消息并等待响应
  Future<bool> _sendAddDishWebSocketWithQuantity(Dish dish, int quantity, Map<String, List<String>>? selectedOptions) async {
    if (_wsHandler == null) {
      logDebug('⚠️ WebSocket处理器未初始化，跳过发送添加指定数量菜品消息: ${dish.name} x$quantity', tag: _logTag);
      return false;
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
        // 绑定登记的动画到该消息ID
        CartAnimationRegistry.bindNextToMessageId(messageId, count: quantity);
        
        logDebug('💾 保存操作上下文映射: messageId=$messageId, dish=${dish.name}, quantity=$quantity', tag: _logTag);
        
        // 清理过期的映射（保留最近10分钟的）
        _cleanupExpiredContextMappings();
        
        // 等待WebSocket响应（设置超时时间）
        return await _waitForWebSocketResponse(messageId, timeout: Duration(seconds: 10));
      } else {
        logDebug('❌ 发送WebSocket消息失败：未获得消息ID', tag: _logTag);
        return false;
      }
    } catch (e) {
      logDebug('❌ 发送WebSocket添加指定数量菜品异常: $e', tag: _logTag);
      return false;
    }
  }

  /// 发送移除指定数量菜品的WebSocket消息并等待响应
  Future<bool> _sendRemoveDishWebSocketWithQuantity(CartItem cartItem, int quantity) async {
    if (_wsHandler == null) {
      logDebug('⚠️ WebSocket处理器未初始化，跳过发送移除指定数量菜品消息: ${cartItem.dish.name} x$quantity', tag: _logTag);
      return false;
    }
    
    // 检查是否有必要的ID
    if (cartItem.cartSpecificationId == null || cartItem.cartId == null) {
      logDebug('⚠️ 移除的菜品缺少ID，无法同步到WebSocket: ${cartItem.dish.name}', tag: _logTag);
      return false;
    }
    
    try {
      logDebug('🗑️ 发送WebSocket移除指定数量菜品: ${cartItem.dish.name} x$quantity', tag: _logTag);
      
      // 调用减少菜品数量来减少指定数量
      // 注意：sendDecreaseQuantityWithId期望负数表示减少，所以传入-quantity
      final messageId = await _wsHandler!.sendDecreaseQuantityWithId(
        cartItem: cartItem,
        incrQuantity: -quantity,
      );
      
      if (messageId != null) {
        // 保存消息ID与操作上下文的映射（用于14005错误恢复）
        _operationContextMap[messageId] = _OperationContext(
          cartItem: cartItem,
          quantity: -quantity, // 负数表示减少操作
        );
        logDebug('💾 保存操作上下文映射: messageId=$messageId, dish=${cartItem.dish.name}, quantity=-$quantity', tag: _logTag);
        
        // 等待WebSocket响应（设置超时时间）
        return await _waitForWebSocketResponse(messageId, timeout: Duration(seconds: 10));
      } else {
        logDebug('❌ 发送WebSocket消息失败：未获得消息ID', tag: _logTag);
        return false;
      }
    } catch (e) {
      logDebug('❌ 发送WebSocket移除指定数量菜品异常: $e', tag: _logTag);
      return false;
    }
  }

  // 已移除：_areOptionsEqual（不再使用）


  /// WebSocket防抖失败回调
  void _onWebSocketDebounceFailed(CartItem cartItem, int quantity) {
    logDebug('❌ WebSocket防抖失败: ${cartItem.dish.name}', tag: _logTag);
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
    
    // 直接设置数量
    cart[cartItem] = newQuantity;
    cart.refresh();
    update();
    
    logDebug('🔄 设置购物车项数量: ${cartItem.dish.name} -> $newQuantity', tag: _logTag);
  }

  /// 处理WebSocket失败（用于OrderController调用）
  void handleWebSocketFailure(CartItem cartItem) {
    logDebug('❌ 处理WebSocket失败: ${cartItem.dish.name}', tag: _logTag);
  }

  /// 处理WebSocket响应（成功或失败）
  void handleWebSocketResponse(String messageId, bool success, {String? errorMessage}) {
    logDebug('📨 处理WebSocket响应: messageId=$messageId, success=$success', tag: _logTag);
    
    // 通过操作上下文找到对应的菜品并重置loading状态
    final context = _operationContextMap[messageId];
    if (context != null) {
      final dishId = context.cartItem.dish.id;
      setDishLoading(dishId, false);
      logDebug('✅ 重置菜品loading状态: ${context.cartItem.dish.name} (dishId=$dishId)', tag: _logTag);
    } else {
      logDebug('⚠️ 未找到messageId对应的操作上下文: $messageId', tag: _logTag);
    }
    
    // 将响应推送到响应流中
    _responseController.add({
      'messageId': messageId,
      'success': success,
      'errorMessage': errorMessage,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    if (!success && errorMessage != null) {
      logDebug('❌ WebSocket操作失败: $errorMessage', tag: _logTag);
    }
    
    // 操作完成后，启动延迟同步机制
    if (success) {
      _scheduleDelayedSync();
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

  /// 从API强制刷新购物车数据（忽略本地状态）
  Future<void> refreshCartFromApi({String? tableId, bool forceRefresh = false}) async {
    // 如果没有传入tableId，尝试从cartInfo中获取
    String? currentTableId = tableId ?? cartInfo.value?.tableId?.toString();
    
    if (currentTableId == null) {
      logDebug('❌ 桌台ID为空，无法刷新购物车数据', tag: _logTag);
      return;
    }
    
    logDebug('🔄 开始强制刷新购物车数据...', tag: _logTag);
    
    try {
      // 强制刷新：直接获取数据，不重试
      if (forceRefresh) {
        try {
          final cartData = await _cartManager.loadCartFromApi(currentTableId);
          
          if (cartData != null) {
            // 获取到有效数据，更新购物车
            cartInfo.value = cartData;
            convertApiCartToLocalCart(forceRefresh: true);
            logDebug('✅ 强制刷新购物车数据成功', tag: _logTag);
          } else {
            // API返回null，清空本地购物车
            logDebug('📭 API返回空数据，清空本地购物车', tag: _logTag);
            cartInfo.value = null;
            convertApiCartToLocalCart(forceRefresh: true);
          }
        } catch (e) {
          // 检查是否是210状态码异常（数据处理中）
          if (e.runtimeType.toString().contains('CartProcessingException')) {
            logDebug('⏳ 强制刷新时遇到210状态码，保留本地数据', tag: _logTag);
            return; // 保留本地数据，不执行清空操作
          }
          logError('❌ 强制刷新购物车数据异常: $e', tag: _logTag);
          // 其他异常也不清空本地购物车，保持现有状态
          return;
        }
      } else {
        // 普通刷新，调用原有逻辑，但需要捕获210异常并重新抛出
        try {
          await loadCartFromApi(tableId: currentTableId, silent: true);
          logDebug('✅ 普通刷新购物车数据成功', tag: _logTag);
        } catch (e) {
          // 重新抛出异常，让调用方处理
          rethrow;
        }
      }
    } catch (e) {
      logError('❌ 强制刷新购物车数据异常: $e', tag: _logTag);
    }
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
    // 不做精度处理，接口返回什么展示什么
    return cart.entries.fold(0.0, (sum, e) => sum + e.key.dish.price * e.value);
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
  
  /// 获取所有操作上下文（供OrderController调用）
  Map<String, _OperationContext> getAllOperationContexts() {
    return Map.from(_operationContextMap);
  }
  
  
  /// 比较两个选项映射是否相等
  // 移除重复的_equal方法，已存在 _areOptionsEqualForContext

  /// 等待WebSocket响应的方法
  Future<bool> _waitForWebSocketResponse(String messageId, {Duration timeout = const Duration(seconds: 10)}) async {
    final completer = Completer<bool>();
    Timer? timeoutTimer;
    
    // 设置超时定时器
    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        logDebug('⏰ WebSocket响应超时: messageId=$messageId', tag: _logTag);
        
        // 超时时也需要重置loading状态
        final context = _operationContextMap[messageId];
        if (context != null) {
          final dishId = context.cartItem.dish.id;
          setDishLoading(dishId, false);
          logDebug('✅ 超时重置菜品loading状态: ${context.cartItem.dish.name} (dishId=$dishId)', tag: _logTag);
        }
        
        completer.complete(false);
      }
    });
    
    // 创建一个监听器来等待响应
    late StreamSubscription subscription;
    subscription = _responseStream.listen((response) {
      if (response['messageId'] == messageId) {
        timeoutTimer?.cancel();
        subscription.cancel();
        
        final success = response['success'] == true;
        logDebug('📨 收到WebSocket响应: messageId=$messageId, success=$success', tag: _logTag);
        
        if (!completer.isCompleted) {
          completer.complete(success);
        }
      }
    });
    
    return completer.future;
  }
  
  /// 响应流控制器
  final StreamController<Map<String, dynamic>> _responseController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get _responseStream => _responseController.stream;
  
  /// 启动延迟同步机制
  void _scheduleDelayedSync() {
    // 取消之前的同步定时器
    _syncTimer?.cancel();
    
    // 设置新的延迟同步定时器
    _syncTimer = Timer(Duration(milliseconds: _stabilityCheckDelayMs), () {
      _performStableSync();
    });
    
    logDebug('⏰ 启动延迟同步机制，${_stabilityCheckDelayMs}ms后执行同步', tag: _logTag);
  }
  
  /// 执行稳定同步
  Future<void> _performStableSync() async {
    // 检查是否有操作正在进行
    if (_hasActiveOperations()) {
      logDebug('⏳ 检测到活跃操作，延迟同步', tag: _logTag);
      _scheduleDelayedSync(); // 重新调度
      return;
    }
    
    // 检查是否已经有同步在进行
    if (_isStableSyncInProgress) {
      logDebug('⏳ 稳定同步已在进行中，跳过', tag: _logTag);
      return;
    }
    
    _isStableSyncInProgress = true;
    logDebug('🔄 开始执行稳定同步...', tag: _logTag);
    
    try {
      // 获取当前桌台ID
      final tableId = cartInfo.value?.tableId?.toString();
      if (tableId == null) {
        logDebug('❌ 桌台ID为空，无法执行稳定同步', tag: _logTag);
        return;
      }
      
      // 执行静默刷新，不显示loading状态
      await loadCartFromApi(tableId: tableId, silent: true);
      logDebug('✅ 稳定同步完成', tag: _logTag);
      
    } catch (e) {
      // 检查是否是210状态码异常
      if (e.runtimeType.toString().contains('CartProcessingException')) {
        logDebug('⏳ 稳定同步遇到210状态码，稍后重试', tag: _logTag);
        // 延迟重试
        Future.delayed(Duration(milliseconds: 1000), () {
          _performStableSync();
        });
      } else {
        logError('❌ 稳定同步异常: $e', tag: _logTag);
      }
    } finally {
      _isStableSyncInProgress = false;
    }
  }
  
  /// 检查是否有活跃的操作
  bool _hasActiveOperations() {
    // 检查是否有菜品正在loading
    for (final loading in dishLoadingStates.values) {
      if (loading) {
        return true;
      }
    }
    
    // 检查是否有待处理的WebSocket操作
    if ((_wsDebounceManager?.pendingOperationsCount ?? 0) > 0) {
      return true;
    }
    
    return false;
  }
  
  /// 手动触发稳定同步（供外部调用）
  void triggerStableSync() {
    logDebug('🔧 手动触发稳定同步', tag: _logTag);
    _syncTimer?.cancel();
    _performStableSync();
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
