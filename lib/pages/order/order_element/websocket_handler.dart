import 'package:lib_base/lib_base.dart';
import 'package:lib_base/utils/websocket_manager.dart';
import 'package:get/get.dart';
import '../model/dish.dart';
import 'order_constants.dart';
import 'models.dart';
import '../../../utils/toast_utils.dart';

/// WebSocket消息处理器
class WebSocketHandler {
  final WebSocketManager _wsManager;
  final String _tableId;
  final String _logTag;
  
  
  // 已处理的消息ID集合（去重用）
  final Set<String> _processedMessageIds = {};
  
  // 消息监听器
  Function(String, Map<String, dynamic>)? _messageListener;
  
  // 回调函数
  final Function()? onCartRefresh;
  final Function()? onCartAdd;
  final Function()? onCartUpdate;
  final Function()? onCartDelete;
  final Function()? onCartClear;
  final Function(int, int)? onPeopleCountChange;
  final Function(int)? onMenuChange;
  final Function(String)? onTableChange;
  final Function(String, Map<String, dynamic>?)? onForceUpdateRequired;

  WebSocketHandler({
    required WebSocketManager wsManager,
    required String tableId,
    required String logTag,
    this.onCartRefresh,
    this.onCartAdd,
    this.onCartUpdate,
    this.onCartDelete,
    this.onCartClear,
    this.onPeopleCountChange,
    this.onMenuChange,
    this.onTableChange,
    this.onForceUpdateRequired,
  }) : _wsManager = wsManager,
       _tableId = tableId,
       _logTag = logTag;

  /// 初始化WebSocket连接
  Future<bool> initialize(String? token) async {
    try {
      logDebug('🔌 开始初始化桌台ID: $_tableId 的WebSocket连接...', tag: _logTag);

      final success = await _wsManager.initializeTableConnection(
        tableId: _tableId,
        token: token,
      );

      if (success) {
        _setupMessageListener();
        logDebug('✅ 桌台 $_tableId WebSocket连接初始化成功', tag: _logTag);
      } else {
        logDebug('❌ 桌台 $_tableId WebSocket连接初始化失败', tag: _logTag);
      }

      return success;
    } catch (e) {
      logDebug('❌ WebSocket初始化异常: $e', tag: _logTag);
      return false;
    }
  }

  /// 设置消息监听器
  void _setupMessageListener() {
    // 移除旧的监听器（如果存在）
    if (_messageListener != null) {
      _wsManager.removeServerMessageListener(_messageListener!);
    }

    // 创建新的监听器
    _messageListener = (tableId, message) {
      if (tableId == _tableId) {
        _handleMessage(message);
      }
    };

    // 添加服务器消息监听器
    _wsManager.addServerMessageListener(_messageListener!);
    logDebug('✅ WebSocket消息监听器设置完成', tag: _logTag);
  }

  /// 处理WebSocket消息
  void _handleMessage(Map<String, dynamic> message) {
    try {
      final messageType = message['type'] as String?;
      final data = message['data'] as Map<String, dynamic>?;
      final messageId = message['id'] as String?;
      
      // 消息去重检查（除了心跳消息）
      if (messageType != MessageType.heartbeat.value && messageId != null) {
        if (_processedMessageIds.contains(messageId)) {
          return;
        }
        _processedMessageIds.add(messageId);
        
        // 限制集合大小，避免内存泄漏
        if (_processedMessageIds.length > OrderConstants.maxProcessedMessageIds) {
          final oldestIds = _processedMessageIds.take(OrderConstants.messageIdsCleanupSize).toList();
          _processedMessageIds.removeAll(oldestIds);
        }
      }
      
      // 过滤心跳消息的日志输出
      if (messageType != MessageType.heartbeat.value) {
        logDebug('📦 收到WebSocket消息: $message', tag: _logTag);
        logDebug('📦 消息类型: $messageType, 数据: $data', tag: _logTag);
      }
      
      _routeMessage(messageType, data);
    } catch (e) {
      logDebug('❌ 处理WebSocket消息失败: $e', tag: _logTag);
    }
  }

  /// 路由消息到对应的处理器
  void _routeMessage(String? messageType, Map<String, dynamic>? data) {
    if (data == null) return;

    switch (messageType) {
      case 'cart':
        _handleCartMessage(data);
        break;
      case 'table':
        _handleTableMessage(data);
        break;
      case 'cart_response':
        _handleCartResponseMessage(data);
        break;
      case 'heartbeat':
        // 心跳消息不处理
        break;
      default:
        logDebug('⚠️ 未知的消息类型: $messageType', tag: _logTag);
    }
  }

  /// 处理购物车相关消息
  void _handleCartMessage(Map<String, dynamic> data) {
    final action = data['action'] as String?;
    
    switch (action) {
      case 'refresh':
        onCartRefresh?.call();
        break;
      case 'add':
        onCartAdd?.call();
        break;
      case 'update':
        onCartUpdate?.call();
        break;
      case 'delete':
        onCartDelete?.call();
        break;
      case 'clear':
        onCartClear?.call();
        break;
      default:
        logDebug('⚠️ 未知的购物车操作: $action', tag: _logTag);
    }
  }

  /// 处理桌台相关消息
  void _handleTableMessage(Map<String, dynamic> data) {
    final action = data['action'] as String?;
    
    switch (action) {
      case 'change_menu':
        final menuId = data['menu_id'] as int?;
        if (menuId != null) onMenuChange?.call(menuId);
        break;
      case 'change_people_count':
        final adultCount = data['adult_count'] as int?;
        final childCount = data['child_count'] as int?;
        if (adultCount != null && childCount != null) {
          onPeopleCountChange?.call(adultCount, childCount);
        }
        break;
      case 'change_table':
        final tableName = data['table_name'] as String?;
        if (tableName != null) onTableChange?.call(tableName);
        break;
      default:
        logDebug('⚠️ 未知的桌台操作: $action', tag: _logTag);
    }
  }

  /// 处理购物车响应消息（操作确认）
  void _handleCartResponseMessage(Map<String, dynamic> data) {
    try {
      logDebug('📨 收到服务器操作确认消息: $data', tag: _logTag);
      
      final code = data['code'] as int?;
      final message = data['message'] as String?;
      final originalId = data['original_id'] as String?;
      
      if (code != null && message != null) {
        logDebug('📝 收到服务器二次确认消息: 代码$code, 消息$message, 原始ID$originalId', tag: _logTag);
        
        if (code == 0) {
          // 操作成功
          logDebug('✅ 操作成功，更新购物车UI', tag: _logTag);
        } else if (code == 409) {
          // 需要强制操作确认
          logDebug('⚠️ 收到409状态码，需要用户确认强制操作', tag: _logTag);
          onForceUpdateRequired?.call(message, data);
        } else if (code == 404) {
          // 404错误 - 显示具体错误信息
          logDebug('❌ 收到404错误: $message', tag: _logTag);
          _showErrorMessage('操作失败', message);
          // 停止loading状态
          _stopLoadingState();
        } else {
          // 其他操作失败
          logDebug('❌ 操作失败: $message', tag: _logTag);
          _showErrorMessage('操作失败', message);
          // 停止loading状态
          _stopLoadingState();
        }
      }
    } catch (e) {
      logDebug('❌ 处理服务器操作确认消息失败: $e', tag: _logTag);
      // 异常情况下也停止loading状态
      _stopLoadingState();
    }
  }
  
  /// 显示错误消息
  void _showErrorMessage(String title, String message) {
    try {
      // 使用ToastUtils显示错误消息
      final context = Get.context;
      if (context != null) {
        ToastUtils.showError(context, message);
      }
    } catch (e) {
      logDebug('❌ 显示错误消息失败: $e', tag: _logTag);
    }
  }

  /// 停止loading状态
  void _stopLoadingState() {
    try {
      // 通过回调通知Controller停止loading状态
      onCartUpdate?.call();
    } catch (e) {
      logDebug('❌ 停止loading状态失败: $e', tag: _logTag);
    }
  }

  /// 发送添加菜品到购物车
  Future<bool> sendAddDish({
    required Dish dish,
    required int quantity,
    Map<String, List<String>>? selectedOptions,
    bool forceOperate = false,
  }) async {
    try {
      final dishId = int.tryParse(dish.id) ?? 0;
      final options = _convertOptionsToServerFormat(selectedOptions);
      
      logDebug('📤 添加菜品参数: 桌台ID=$_tableId, 菜品ID=$dishId, 数量=$quantity', tag: _logTag);
      
      final success = await _wsManager.sendAddDishToCart(
        tableId: _tableId,
        dishId: dishId,
        quantity: quantity,
        options: options,
        forceOperate: forceOperate,
      );
      
      if (success) {
        logDebug('📤 添加菜品到WebSocket: ${dish.name} x$quantity', tag: _logTag);
      } else {
        logDebug('❌ 添加菜品同步到WebSocket失败', tag: _logTag);
      }
      
      return success;
    } catch (e) {
      logDebug('❌ 同步添加菜品到WebSocket异常: $e', tag: _logTag);
      return false;
    }
  }

  /// 发送更新菜品数量
  Future<bool> sendUpdateQuantity({
    required CartItem cartItem,
    required int quantity,
    bool forceOperate = false,
  }) async {
    if (cartItem.cartSpecificationId == null || cartItem.cartId == null) {
      logDebug('⚠️ cartSpecificationId或cartId为空，跳过WebSocket同步', tag: _logTag);
      return false;
    }

    try {
      final success = await _wsManager.sendUpdateDishQuantity(
        tableId: _tableId,
        quantity: quantity,
        cartId: cartItem.cartId!,
        cartSpecificationId: cartItem.cartSpecificationId!,
        forceOperate: forceOperate,
      );

      if (success) {
        logDebug('📤 更新菜品数量已同步到WebSocket: ${cartItem.dish.name} x$quantity, 强制操作: $forceOperate', tag: _logTag);
      } else {
        logDebug('❌ 更新菜品数量同步到WebSocket失败', tag: _logTag);
      }
      
      return success;
    } catch (e) {
      logDebug('❌ 同步更新菜品数量到WebSocket异常: $e', tag: _logTag);
      return false;
    }
  }

  /// 发送减少菜品数量
  Future<bool> sendDecreaseQuantity({
    required CartItem cartItem,
    required int incrQuantity,
  }) async {
    if (cartItem.cartSpecificationId == null || cartItem.cartId == null) {
      logDebug('⚠️ cartSpecificationId或cartId为空，跳过WebSocket同步', tag: _logTag);
      return false;
    }

    try {
      final success = await _wsManager.sendDecreaseDishQuantity(
        tableId: _tableId,
        cartId: cartItem.cartId!,
        cartSpecificationId: cartItem.cartSpecificationId!,
        incrQuantity: incrQuantity,
      );

      if (success) {
        logDebug('📤 减少菜品数量已同步到WebSocket: ${cartItem.dish.name} 增量$incrQuantity', tag: _logTag);
      } else {
        logDebug('❌ 减少菜品数量同步到WebSocket失败', tag: _logTag);
      }
      
      return success;
    } catch (e) {
      logDebug('❌ 同步减少菜品数量到WebSocket异常: $e', tag: _logTag);
      return false;
    }
  }

  /// 发送删除菜品
  Future<bool> sendDeleteDish(CartItem cartItem) async {
    if (cartItem.cartSpecificationId == null || cartItem.cartId == null) {
      logDebug('⚠️ cartSpecificationId或cartId为空，跳过WebSocket同步', tag: _logTag);
      return false;
    }

    try {
      final success = await _wsManager.sendDeleteDish(
        tableId: _tableId,
        cartSpecificationId: cartItem.cartSpecificationId!,
        cartId: cartItem.cartId!,
      );

      if (success) {
        logDebug('📤 删除菜品已同步到WebSocket: ${cartItem.dish.name}', tag: _logTag);
      } else {
        logDebug('❌ 删除菜品同步到WebSocket失败', tag: _logTag);
      }
      
      return success;
    } catch (e) {
      logDebug('❌ 同步删除菜品到WebSocket异常: $e', tag: _logTag);
      return false;
    }
  }

  /// 发送清空购物车
  Future<bool> sendClearCart() async {
    try {
      final success = await _wsManager.sendClearCart(tableId: _tableId);

      if (success) {
        logDebug('📤 清空购物车已同步到WebSocket', tag: _logTag);
      } else {
        logDebug('❌ 清空购物车同步到WebSocket失败', tag: _logTag);
      }

      return success;
    } catch (e) {
      logDebug('❌ 同步清空购物车到WebSocket异常: $e', tag: _logTag);
      return false;
    }
  }

  /// 转换规格选项为服务器格式
  List<DishOption> _convertOptionsToServerFormat(Map<String, List<String>>? selectedOptions) {
    if (selectedOptions == null || selectedOptions.isEmpty) {
      return [];
    }

    final options = <DishOption>[];
    
    selectedOptions.forEach((optionIdStr, itemIdStrs) {
      if (itemIdStrs.isNotEmpty) {
        final optionId = int.tryParse(optionIdStr) ?? 0;
        final itemIds = itemIdStrs.map((idStr) => int.tryParse(idStr) ?? 0).toList();
        
        if (optionId > 0 && itemIds.any((id) => id > 0)) {
          options.add(DishOption(
            id: optionId,
            itemIds: itemIds,
            customValues: [],
          ));
        }
      }
    });
    
    return options;
  }


  /// 清理资源
  void dispose() {
    if (_messageListener != null) {
      _wsManager.removeServerMessageListener(_messageListener!);
      _messageListener = null;
    }
    _wsManager.disconnectTable(_tableId);
    _processedMessageIds.clear();
  }
}
