import 'dart:async';
import 'package:lib_base/lib_base.dart';
import 'order_constants.dart';
import 'models.dart';
import 'websocket_handler.dart';

/// WebSocket防抖管理器
/// 用于优化WebSocket通信频率，避免频繁发送消息
class WebSocketDebounceManager {
  final WebSocketHandler _wsHandler;
  final String _logTag;
  
  // 防抖定时器映射
  final Map<String, Timer> _debounceTimers = {};
  
  // 待发送的操作队列
  final Map<String, PendingOperation> _pendingOperations = {};
  
  // 失败回调函数
  Function(CartItem, int)? _onWebSocketFailed;
  
  WebSocketDebounceManager({
    required WebSocketHandler wsHandler,
    required String logTag,
  }) : _wsHandler = wsHandler, _logTag = logTag;
  
  /// 设置失败回调函数
  void setFailureCallback(Function(CartItem, int)? onWebSocketFailed) {
    _onWebSocketFailed = onWebSocketFailed;
  }
  
  /// 防抖发送更新数量操作
  void debounceUpdateQuantity({
    required CartItem cartItem,
    required int quantity,
  }) {
    final key = 'update_${cartItem.cartId}_${cartItem.cartSpecificationId}';
    
    // 保存最新的操作参数
    _pendingOperations[key] = PendingOperation(
      type: OperationType.update,
      cartItem: cartItem,
      quantity: quantity,
    );
    
    // 取消之前的定时器
    _debounceTimers[key]?.cancel();
    
    // 设置新的防抖定时器
    _debounceTimers[key] = Timer(
      Duration(milliseconds: OrderConstants.websocketBatchDebounceMs),
      () => _executePendingOperation(key),
    );
    
    logDebug('🔄 WebSocket防抖: 更新数量 ${cartItem.dish.name} -> $quantity', tag: _logTag);
  }
  
  /// 防抖发送减少数量操作
  void debounceDecreaseQuantity({
    required CartItem cartItem,
    required int incrQuantity,
  }) {
    final key = 'decrease_${cartItem.cartId}_${cartItem.cartSpecificationId}';
    
    // 保存最新的操作参数
    _pendingOperations[key] = PendingOperation(
      type: OperationType.decrease,
      cartItem: cartItem,
      incrQuantity: incrQuantity,
    );
    
    // 取消之前的定时器
    _debounceTimers[key]?.cancel();
    
    // 设置新的防抖定时器
    _debounceTimers[key] = Timer(
      Duration(milliseconds: OrderConstants.websocketBatchDebounceMs),
      () => _executePendingOperation(key),
    );
    
    logDebug('🔄 WebSocket防抖: 减少数量 ${cartItem.dish.name} 增量$incrQuantity', tag: _logTag);
  }
  
  /// 立即发送操作（不防抖）
  Future<bool> sendImmediate({
    required CartItem cartItem,
    required int quantity,
  }) async {
    return await _wsHandler.sendUpdateQuantity(
      cartItem: cartItem,
      quantity: quantity,
    );
  }
  
  /// 执行待处理的操作
  void _executePendingOperation(String key) {
    final operation = _pendingOperations.remove(key);
    if (operation == null) return;
    
    _debounceTimers.remove(key);
    
    switch (operation.type) {
      case OperationType.update:
        // 检查是否有必要的ID，如果没有则跳过WebSocket同步
        if (operation.cartItem!.cartSpecificationId == null || operation.cartItem!.cartId == null) {
          logDebug('⚠️ 新菜品缺少ID，跳过WebSocket防抖操作: ${operation.cartItem!.dish.name}', tag: _logTag);
          return;
        }
        
        _wsHandler.sendUpdateQuantity(
          cartItem: operation.cartItem!,
          quantity: operation.quantity!,
        ).then((success) {
          if (!success) {
            logDebug('❌ WebSocket防抖操作发送失败: 更新数量 ${operation.cartItem!.dish.name}', tag: _logTag);
            // 通知失败回调
            _onWebSocketFailed?.call(operation.cartItem!, operation.quantity!);
          } else {
            logDebug('📤 执行WebSocket防抖操作: 更新数量 ${operation.cartItem!.dish.name} -> ${operation.quantity}', tag: _logTag);
          }
        }).catchError((error) {
          logDebug('❌ WebSocket防抖操作异常: 更新数量 ${operation.cartItem!.dish.name}, 错误: $error', tag: _logTag);
          // 通知失败回调
          _onWebSocketFailed?.call(operation.cartItem!, operation.quantity!);
        });
        break;
      case OperationType.decrease:
        // 检查是否有必要的ID，如果没有则跳过WebSocket同步
        if (operation.cartItem!.cartSpecificationId == null || operation.cartItem!.cartId == null) {
          logDebug('⚠️ 新菜品缺少ID，跳过WebSocket防抖操作: ${operation.cartItem!.dish.name}', tag: _logTag);
          return;
        }
        
        _wsHandler.sendDecreaseQuantity(
          cartItem: operation.cartItem!,
          incrQuantity: operation.incrQuantity!,
        ).then((success) {
          if (!success) {
            logDebug('❌ WebSocket防抖操作发送失败: 减少数量 ${operation.cartItem!.dish.name}', tag: _logTag);
            // 通知失败回调
            _onWebSocketFailed?.call(operation.cartItem!, operation.incrQuantity!);
          } else {
            logDebug('📤 执行WebSocket防抖操作: 减少数量 ${operation.cartItem!.dish.name} 增量${operation.incrQuantity}', tag: _logTag);
          }
        }).catchError((error) {
          logDebug('❌ WebSocket防抖操作异常: 减少数量 ${operation.cartItem!.dish.name}, 错误: $error', tag: _logTag);
          // 通知失败回调
          _onWebSocketFailed?.call(operation.cartItem!, operation.incrQuantity!);
        });
        break;
      default:
        logDebug('⚠️ 未知的WebSocket操作类型: ${operation.type}', tag: _logTag);
    }
  }
  
  /// 取消指定商品的所有待处理操作
  void cancelPendingOperations(CartItem cartItem) {
    final keysToRemove = <String>[];
    
    for (final entry in _pendingOperations.entries) {
      if (entry.value.cartItem?.cartId == cartItem.cartId &&
          entry.value.cartItem?.cartSpecificationId == cartItem.cartSpecificationId) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _debounceTimers[key]?.cancel();
      _debounceTimers.remove(key);
      _pendingOperations.remove(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      logDebug('❌ 取消WebSocket防抖操作: ${cartItem.dish.name} (${keysToRemove.length}个)', tag: _logTag);
    }
  }
  
  /// 取消所有待处理的操作
  void cancelAllPendingOperations() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    
    final count = _pendingOperations.length;
    _debounceTimers.clear();
    _pendingOperations.clear();
    
    if (count > 0) {
      logDebug('❌ 取消所有WebSocket防抖操作: $count个', tag: _logTag);
    }
  }
  
  /// 获取待处理操作数量
  int get pendingOperationsCount => _pendingOperations.length;
  
  /// 销毁管理器
  void dispose() {
    cancelAllPendingOperations();
  }
}

/// 待处理的操作
class PendingOperation {
  final OperationType type;
  final CartItem? cartItem;
  final int? quantity;
  final int? incrQuantity;
  
  PendingOperation({
    required this.type,
    this.cartItem,
    this.quantity,
    this.incrQuantity,
  });
}
