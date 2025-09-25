import 'dart:async';
import 'package:lib_base/lib_base.dart';
import 'order_constants.dart';
import 'models.dart';

/// 本地购物车管理器
/// 用于管理连续点击时的本地状态，避免频繁的WebSocket请求
class LocalCartManager {
  final String _logTag;
  
  // 防抖定时器映射
  final Map<String, Timer> _debounceTimers = {};
  
  // 待发送的操作队列
  final Map<String, PendingLocalOperation> _pendingOperations = {};
  
  // 回调函数
  Function(CartItem, int)? _onQuantityChanged;
  Function(CartItem, int)? _onWebSocketSend;
  Function(CartItem, int)? _onWebSocketFailed;
  
  LocalCartManager({required String logTag}) : _logTag = logTag;
  
  /// 设置回调函数
  void setCallbacks({
    Function(CartItem, int)? onQuantityChanged,
    Function(CartItem, int)? onWebSocketSend,
    Function(CartItem, int)? onWebSocketFailed,
  }) {
    _onQuantityChanged = onQuantityChanged;
    _onWebSocketSend = onWebSocketSend;
    _onWebSocketFailed = onWebSocketFailed;
  }
  
  /// 生成购物车项的本地键
  String _generateLocalKey(CartItem cartItem) {
    return '${cartItem.dish.id}_${cartItem.cartSpecificationId ?? 'default'}';
  }
  
  /// 增加菜品数量（本地优先）
  void addDishQuantity(CartItem cartItem, int currentQuantity) {
    final key = _generateLocalKey(cartItem);
    final newQuantity = currentQuantity + 1;
    
    logDebug('🔍 LocalCartManager.addDishQuantity 调试信息:', tag: _logTag);
    logDebug('  菜品: ${cartItem.dish.name}', tag: _logTag);
    logDebug('  当前数量: $currentQuantity', tag: _logTag);
    logDebug('  新数量: $newQuantity', tag: _logTag);
    logDebug('  规格选项: ${cartItem.selectedOptions}', tag: _logTag);
    
    // 立即更新UI
    if (_onQuantityChanged != null) {
      logDebug('  调用onQuantityChanged回调', tag: _logTag);
      _onQuantityChanged!(cartItem, newQuantity);
    } else {
      logDebug('  ⚠️ onQuantityChanged回调为null', tag: _logTag);
    }
    
    // 防抖发送WebSocket消息
    _debounceWebSocketOperation(key, cartItem, newQuantity);
    
    logDebug('➕ 本地增加数量: ${cartItem.dish.name} $currentQuantity -> $newQuantity', tag: _logTag);
  }
  
  /// 减少菜品数量（本地优先）
  void removeDishQuantity(CartItem cartItem, int currentQuantity) {
    final key = _generateLocalKey(cartItem);
    final newQuantity = currentQuantity - 1;
    
    // 立即更新UI
    if (_onQuantityChanged != null) {
      _onQuantityChanged!(cartItem, newQuantity);
    }
    
    // 防抖发送WebSocket消息
    _debounceWebSocketOperation(key, cartItem, newQuantity);
    
    logDebug('➖ 本地减少数量: ${cartItem.dish.name} $currentQuantity -> $newQuantity', tag: _logTag);
  }
  
  /// 设置菜品数量（本地优先）
  void setDishQuantity(CartItem cartItem, int targetQuantity) {
    final key = _generateLocalKey(cartItem);
    
    // 立即更新UI
    if (_onQuantityChanged != null) {
      _onQuantityChanged!(cartItem, targetQuantity);
    }
    
    // 防抖发送WebSocket消息
    _debounceWebSocketOperation(key, cartItem, targetQuantity);
    
    logDebug('🔄 本地设置数量: ${cartItem.dish.name} -> $targetQuantity', tag: _logTag);
  }
  
  /// 防抖WebSocket操作
  void _debounceWebSocketOperation(String key, CartItem cartItem, int quantity) {
    // 获取原始数量（如果之前有操作，使用之前的数量作为原始数量）
    int originalQuantity = quantity;
    if (_pendingOperations.containsKey(key)) {
      originalQuantity = _pendingOperations[key]!.originalQuantity;
    }
    
    // 保存最新的操作参数
    _pendingOperations[key] = PendingLocalOperation(
      cartItem: cartItem,
      quantity: quantity,
      originalQuantity: originalQuantity,
      timestamp: DateTime.now(),
    );
    
    // 取消之前的定时器
    _debounceTimers[key]?.cancel();
    
    // 设置新的防抖定时器
    _debounceTimers[key] = Timer(
      Duration(milliseconds: OrderConstants.localCartDebounceMs),
      () => _executePendingOperation(key),
    );
  }
  
  /// 执行待处理的WebSocket操作
  void _executePendingOperation(String key) {
    final operation = _pendingOperations.remove(key);
    if (operation == null) return;
    
    _debounceTimers.remove(key);
    
    // 发送WebSocket消息
    if (_onWebSocketSend != null) {
      _onWebSocketSend!(operation.cartItem, operation.quantity);
    }
    
    logDebug('📤 执行WebSocket操作: ${operation.cartItem.dish.name} -> ${operation.quantity}', tag: _logTag);
  }
  
  /// 处理WebSocket操作失败
  void handleWebSocketFailure(CartItem cartItem) {
    final key = _generateLocalKey(cartItem);
    final operation = _pendingOperations[key];
    
    if (operation != null) {
      // 恢复到原始数量
      if (_onQuantityChanged != null) {
        _onQuantityChanged!(cartItem, operation.originalQuantity);
      }
      
      // 通知失败回调
      if (_onWebSocketFailed != null) {
        _onWebSocketFailed!(cartItem, operation.originalQuantity);
      }
      
      // 清除待处理操作
      _debounceTimers[key]?.cancel();
      _debounceTimers.remove(key);
      _pendingOperations.remove(key);
      
      logDebug('❌ WebSocket操作失败，回滚数量: ${cartItem.dish.name} ${operation.quantity} -> ${operation.originalQuantity}', tag: _logTag);
    }
  }
  
  /// 清除指定商品的所有待处理操作
  void clearPendingOperations(CartItem cartItem) {
    final key = _generateLocalKey(cartItem);
    _debounceTimers[key]?.cancel();
    _debounceTimers.remove(key);
    _pendingOperations.remove(key);
  }
  
  /// 清除所有待处理的操作
  void clearAllPendingOperations() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    
    final count = _pendingOperations.length;
    _debounceTimers.clear();
    _pendingOperations.clear();
    
    if (count > 0) {
      logDebug('🧹 清除所有待处理操作: $count个', tag: _logTag);
    }
  }
  
  /// 立即发送所有待处理的操作
  void flushAllPendingOperations() {
    final operations = Map<String, PendingLocalOperation>.from(_pendingOperations);
    
    for (final entry in operations.entries) {
      _debounceTimers[entry.key]?.cancel();
      _debounceTimers.remove(entry.key);
      _pendingOperations.remove(entry.key);
      
      if (_onWebSocketSend != null) {
        _onWebSocketSend!(entry.value.cartItem, entry.value.quantity);
      }
    }
    
    if (operations.isNotEmpty) {
      logDebug('🚀 立即发送所有待处理操作: ${operations.length}个', tag: _logTag);
    }
  }
  
  /// 获取待处理操作数量
  int get pendingOperationsCount => _pendingOperations.length;
  
  /// 销毁管理器
  void dispose() {
    clearAllPendingOperations();
  }
}

/// 待处理的本地操作
class PendingLocalOperation {
  final CartItem cartItem;
  final int quantity;
  final int originalQuantity; // 原始数量，用于失败时回滚
  final DateTime timestamp;
  
  PendingLocalOperation({
    required this.cartItem,
    required this.quantity,
    required this.originalQuantity,
    required this.timestamp,
  });
}