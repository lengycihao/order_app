import 'dart:async';
import 'dart:math';
import 'websocket_util.dart';
import '../logging/logging.dart';

/// 菜品规格选项
class DishOption {
  final int id; // 规格名称id
  final List<int> itemIds; // 规格对应的值的id列表
  final List<String> customValues; // 自定义值（暂时不用）

  const DishOption({
    required this.id,
    required this.itemIds,
    this.customValues = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_ids': itemIds,
      'custom_values': customValues,
    };
  }

  factory DishOption.fromJson(Map<String, dynamic> json) {
    return DishOption(
      id: json['id'] as int,
      itemIds: (json['item_ids'] as List<dynamic>).cast<int>(),
      customValues: (json['custom_values'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

/// WebSocket管理器 - 专注于业务逻辑管理
class WebSocketManager {
  static final WebSocketManager _instance = WebSocketManager._internal();
  factory WebSocketManager() => _instance;
  WebSocketManager._internal();

  /// 桌台连接映射
  final Map<String, WebSocketUtil> _tableConnections = {};
  
  /// 当前活跃的桌台ID
  String? _currentActiveTableId;
  
  /// 服务器消息监听器
  final List<Function(String tableId, Map<String, dynamic> message)> _serverMessageListeners = [];
  
  /// 已处理的消息ID集合（用于去重）
  final Set<String> _processedMessageIds = <String>{};

  /// 获取当前活跃桌台ID
  String? get currentActiveTableId => _currentActiveTableId;
  
  /// 获取所有连接的桌台ID列表
  List<String> get connectedTableIds => _tableConnections.keys.toList();
  
  /// 获取连接统计信息
  Map<String, dynamic> get connectionStats {
    return {
      'total_connections': _tableConnections.length,
      'active_table_id': _currentActiveTableId,
      'connected_tables': _tableConnections.keys.toList(),
    };
  }

  /// 初始化桌台连接
  Future<bool> initializeTableConnection({
    required String tableId,
    String? serverUrl,
    String? token,
  }) async {
    try {
      // 如果已经连接，先断开
      if (_tableConnections.containsKey(tableId)) {
        await disconnectTable(tableId);
      }

      logDebug('🔌 初始化桌台 $tableId 的WebSocket连接...', tag: 'WebSocketManager');

      final config = WebSocketConfig(
        serverUrl: serverUrl ?? 'ws://129.204.154.113:8050/api/waiter/ws',
        tableId: tableId,
        token: token,
      );

      final wsUtil = WebSocketUtil();
      final success = await wsUtil.initialize(config);

      if (success) {
        _tableConnections[tableId] = wsUtil;
        _currentActiveTableId = tableId;
        
        logDebug('✅ 桌台 $tableId WebSocket连接建立成功', tag: 'WebSocketManager');
        
        // 设置连接状态监听
        wsUtil.addConnectionStateListener((state) {
          logDebug('🔌 桌台 $tableId 连接状态: $state', tag: 'WebSocketManager');
          if (state == WebSocketConnectionState.disconnected) {
            // 连接断开时，从管理器中移除
            _tableConnections.remove(tableId);
            if (_currentActiveTableId == tableId) {
              _currentActiveTableId = null;
            }
          }
        });

        // 设置原始消息监听器
        wsUtil.addRawMessageListener((messageData) {
          _handleServerMessage(tableId, messageData);
        });
        
        return true;
      } else {
        logDebug('❌ 桌台 $tableId WebSocket连接建立失败', tag: 'WebSocketManager');
        return false;
      }
    } catch (e) {
      logDebug('❌ 初始化桌台 $tableId 连接失败: $e', tag: 'WebSocketManager');
      return false;
    }
  }

  /// 断开指定桌台连接
  Future<void> disconnectTable(String tableId) async {
    final connection = _tableConnections[tableId];
    if (connection != null) {
      // 先dispose，确保停止重连
      connection.dispose();
      _tableConnections.remove(tableId);
      if (_currentActiveTableId == tableId) {
        _currentActiveTableId = null;
      }
      logDebug('🔌 桌台 $tableId 连接已断开并清理', tag: 'WebSocketManager');
    }
  }

  /// 断开所有连接
  Future<void> disconnectAll() async {
    for (final tableId in _tableConnections.keys.toList()) {
      await disconnectTable(tableId);
    }
    logDebug('🔌 所有桌台连接已断开', tag: 'WebSocketManager');
  }

  /// 切换活跃桌台
  void switchActiveTable(String tableId) {
    if (_tableConnections.containsKey(tableId)) {
      _currentActiveTableId = tableId;
      logDebug('🔄 切换到桌台 $tableId', tag: 'WebSocketManager');
    } else {
      logDebug('❌ 桌台 $tableId 未连接，无法切换', tag: 'WebSocketManager');
    }
  }

  /// 生成20位随机消息ID
  String _generateMessageId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(20, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// 发送添加菜品到购物车消息
  Future<bool> sendAddDishToCart({
    required String tableId,
    required int dishId,
    required int quantity,
    List<DishOption> options = const [],
    bool forceOperate = false,
  }) async {
    final connection = _tableConnections[tableId];
    if (connection == null) {
      logDebug('❌ 桌台 $tableId 未连接，无法发送消息', tag: 'WebSocketManager');
      return false;
    }

    try {
      final message = {
        'id': _generateMessageId(),
        'type': 'cart',
        'data': {
          'action': 'add',
          'dish_id': dishId,
          'quantity': quantity,
          'options': options.map((option) => option.toJson()).toList(),
          'force_operate': forceOperate,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      final success = await connection.sendRawMessage(message);
      if (success) {
        logDebug('📤 发送添加菜品消息: 桌台$tableId, 菜品$dishId, 数量$quantity', tag: 'WebSocketManager');
      }
      return success;
    } catch (e) {
      logDebug('❌ 发送添加菜品消息失败: $e', tag: 'WebSocketManager');
      return false;
    }
  }

  /// 发送添加菜品到购物车消息（带自定义消息ID）
  Future<bool> sendAddDishToCartWithId({
    required String tableId,
    required int dishId,
    required int quantity,
    List<DishOption> options = const [],
    bool forceOperate = false,
    required String messageId,
  }) async {
    final connection = _tableConnections[tableId];
    if (connection == null) {
      logDebug('❌ 桌台 $tableId 未连接，无法发送消息', tag: 'WebSocketManager');
      return false;
    }

    try {
      final message = {
        'id': messageId,
        'type': 'cart',
        'data': {
          'action': 'add',
          'dish_id': dishId,
          'quantity': quantity,
          'options': options.map((option) => option.toJson()).toList(),
          'force_operate': forceOperate,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      final success = await connection.sendRawMessage(message);
      if (success) {
        logDebug('📤 发送添加菜品消息: 桌台$tableId, 菜品$dishId, 数量$quantity, 消息ID$messageId', tag: 'WebSocketManager');
      }
      return success;
    } catch (e) {
      logDebug('❌ 发送添加菜品消息失败: $e', tag: 'WebSocketManager');
      return false;
    }
  }


  /// 发送更新菜品数量消息
  Future<bool> sendUpdateDishQuantity({
    required String tableId,
    required int quantity,
    required int cartId,
    required String cartSpecificationId,
  }) async {
    return sendUpdateDishQuantityWithId(
      tableId: tableId,
      quantity: quantity,
      cartId: cartId,
      cartSpecificationId: cartSpecificationId,
      messageId: _generateMessageId(),
    );
  }

  /// 发送更新菜品数量消息（带消息ID）
  Future<bool> sendUpdateDishQuantityWithId({
    required String tableId,
    required int quantity,
    required int cartId,
    required String cartSpecificationId,
    required String messageId,
  }) async {
    final connection = _tableConnections[tableId];
    if (connection == null) {
      logDebug('❌ 桌台 $tableId 未连接，无法发送消息', tag: 'WebSocketManager');
      return false;
    }

    try {
      final message = {
        'id': messageId,
        'type': 'cart',
        'data': {
          'action': 'update',
          'quantity': quantity,
          'cart_id': cartId,
          'cart_specification_id': cartSpecificationId,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      final success = await connection.sendRawMessage(message);
      if (success) {
        logDebug('📤 发送更新菜品数量消息: 桌台$tableId, 购物车ID$cartId, 规格ID$cartSpecificationId, 数量$quantity, 消息ID$messageId', tag: 'WebSocketManager');
      }
      return success;
    } catch (e) {
      logDebug('❌ 发送更新菜品数量消息失败: $e', tag: 'WebSocketManager');
      return false;
    }
  }

  /// 发送减少菜品数量消息（使用incr_quantity字段）
  Future<bool> sendDecreaseDishQuantity({
    required String tableId,
    required int cartId,
    required String cartSpecificationId,
    required int incrQuantity, // 负数表示减少
  }) async {
    return sendDecreaseDishQuantityWithId(
      tableId: tableId,
      cartId: cartId,
      cartSpecificationId: cartSpecificationId,
      incrQuantity: incrQuantity,
      messageId: _generateMessageId(),
    );
  }

  /// 发送减少菜品数量消息（带消息ID，使用incr_quantity字段）
  Future<bool> sendDecreaseDishQuantityWithId({
    required String tableId,
    required int cartId,
    required String cartSpecificationId,
    required int incrQuantity, // 负数表示减少
    required String messageId,
  }) async {
    final connection = _tableConnections[tableId];
    if (connection == null) {
      logDebug('❌ 桌台 $tableId 未连接，无法发送消息', tag: 'WebSocketManager');
      return false;
    }

    try {
      final message = {
        'id': messageId,
        'type': 'cart',
        'data': {
          'action': 'update',
          'incr_quantity': incrQuantity, // 使用incr_quantity字段
          'cart_id': cartId,
          'cart_specification_id': cartSpecificationId,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      final success = await connection.sendRawMessage(message);
      if (success) {
        logDebug('📤 发送减少菜品数量消息: 桌台$tableId, 购物车ID$cartId, 规格ID$cartSpecificationId, 增量$incrQuantity, 消息ID$messageId', tag: 'WebSocketManager');
      }
      return success;
    } catch (e) {
      logDebug('❌ 发送减少菜品数量消息失败: $e', tag: 'WebSocketManager');
      return false;
    }
  }

  /// 发送删除菜品消息
  Future<bool> sendDeleteDish({
    required String tableId,
    required String cartSpecificationId,
    required int cartId,
  }) async {
    return sendDeleteDishWithId(
      tableId: tableId,
      cartSpecificationId: cartSpecificationId,
      cartId: cartId,
      messageId: _generateMessageId(),
    );
  }

  /// 发送删除菜品消息（带消息ID）
  Future<bool> sendDeleteDishWithId({
    required String tableId,
    required String cartSpecificationId,
    required int cartId,
    required String messageId,
  }) async {
    final connection = _tableConnections[tableId];
    if (connection == null) {
      logDebug('❌ 桌台 $tableId 未连接，无法发送消息', tag: 'WebSocketManager');
      return false;
    }

    try {
      final message = {
        'id': messageId,
        'type': 'cart',
        'data': {
          'action': 'delete',
          'cart_specification_id': cartSpecificationId,
          'cart_id': cartId,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      final success = await connection.sendRawMessage(message);
      if (success) {
        logDebug('📤 发送删除菜品消息: 桌台$tableId, 购物车ID$cartId, 规格ID$cartSpecificationId, 消息ID$messageId', tag: 'WebSocketManager');
      }
      return success;
    } catch (e) {
      logDebug('❌ 发送删除菜品消息失败: $e', tag: 'WebSocketManager');
      return false;
    }
  }

  /// 发送清空购物车消息
  Future<bool> sendClearCart({
    required String tableId,
  }) async {
    final connection = _tableConnections[tableId];
    if (connection == null) {
      logDebug('❌ 桌台 $tableId 未连接，无法发送消息', tag: 'WebSocketManager');
      return false;
    }

    try {
      final message = {
        'id': _generateMessageId(),
        'type': 'cart',
        'data': {
          'action': 'clear',
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      final success = await connection.sendRawMessage(message);
      if (success) {
        logDebug('📤 发送清空购物车消息: 桌台$tableId', tag: 'WebSocketManager');
      }
      return success;
    } catch (e) {
      logDebug('❌ 发送清空购物车消息失败: $e', tag: 'WebSocketManager');
      return false;
    }
  }

  /// 发送购物车备注消息
  Future<bool> sendCartRemark({
    required String tableId,
    required String remark,
  }) async {
    final connection = _tableConnections[tableId];
    if (connection == null) {
      logDebug('❌ 桌台 $tableId 未连接，无法发送消息', tag: 'WebSocketManager');
      return false;
    }

    try {
      final message = {
        'id': _generateMessageId(),
        'type': 'cart',
        'data': {
          'action': 'remark',
          'remark': remark,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      final success = await connection.sendRawMessage(message);
      if (success) {
        logDebug('📤 发送购物车备注消息: 桌台$tableId, 备注=$remark', tag: 'WebSocketManager');
      }
      return success;
    } catch (e) {
      logDebug('❌ 发送购物车备注消息失败: $e', tag: 'WebSocketManager');
      return false;
    }
  }

  /// 发送刷新购物车消息
  Future<bool> sendRefreshCart({
    required String tableId,
  }) async {
    final connection = _tableConnections[tableId];
    if (connection == null) {
      logDebug('❌ 桌台 $tableId 未连接，无法发送消息', tag: 'WebSocketManager');
      return false;
    }

    try {
      final message = {
        'id': _generateMessageId(),
        'type': 'cart',
        'data': {
          'action': 'refresh',
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      final success = await connection.sendRawMessage(message);
      if (success) {
        logDebug('📤 发送刷新购物车消息: 桌台$tableId', tag: 'WebSocketManager');
      }
      return success;
    } catch (e) {
      logDebug('❌ 发送刷新购物车消息失败: $e', tag: 'WebSocketManager');
      return false;
    }
  }


  /// 处理服务器消息
  void _handleServerMessage(String tableId, Map<String, dynamic> messageData) {
    try {
      // 验证消息中的table_id是否匹配当前桌台
      final messageTableId = messageData['table_id']?.toString();
      if (messageTableId != null && messageTableId != tableId) {
        logDebug('⚠️ 收到其他桌台($messageTableId)的消息，当前桌台($tableId),消息类型(${messageData['type']})，跳过处理', tag: 'WebSocketManager');
        return;
      }
      
      final type = messageData['type'] as String?;
      final data = messageData['data'] as Map<String, dynamic>? ?? {};
      final messageId = messageData['id'] as String?;
      
      // 消息去重检查（除了心跳消息）
      if (type != 'heartbeat' && messageId != null) {
        if (_processedMessageIds.contains(messageId)) {
          // 跳过已处理的消息
          return;
        }
        // 记录已处理的消息ID
        _processedMessageIds.add(messageId);
        
        // 限制集合大小，避免内存泄漏
        if (_processedMessageIds.length > 1000) {
          final oldestIds = _processedMessageIds.take(200).toList();
          _processedMessageIds.removeAll(oldestIds);
        }
      }
      
      // 过滤心跳消息的日志输出
      if (type != 'heartbeat') {
        logDebug('📨 桌台 $tableId 收到服务器消息: $type', tag: 'WebSocketManager');
      }
      
      if (type == 'cart') {
        final action = data['action'] as String?;
        switch (action) {
          case 'add':
            logDebug('➕ 收到服务器菜品添加消息: $data', tag: 'WebSocketManager');
            break;
          case 'add_temp':
            logDebug('➕ 收到服务器临时菜品添加消息: $data', tag: 'WebSocketManager');
            break;
          case 'update':
            logDebug('🔄 收到服务器菜品更新消息: $data', tag: 'WebSocketManager');
            break;
          case 'delete':
            logDebug('🗑️ 收到服务器菜品删除消息: $data', tag: 'WebSocketManager');
            break;
          case 'clear':
            logDebug('🧹 收到服务器购物车清空消息: $data', tag: 'WebSocketManager');
            break;
          case 'refresh':
            logDebug('🔄 收到服务器购物车刷新消息: $data', tag: 'WebSocketManager');
            break;
          case 'remark':
            logDebug('📝 收到服务器购物车备注消息: $data', tag: 'WebSocketManager');
            break;
          default:
            logDebug('❓ 收到未知购物车操作: $action', tag: 'WebSocketManager');
        }
      } else if (type == 'table') {
        final action = data['action'] as String?;
        switch (action) {
          case 'change_menu':
            logDebug('📋 收到服务器修改菜单消息: $data', tag: 'WebSocketManager');
            break;
          case 'change_people_count':
            logDebug('👥 收到服务器修改人数消息: $data', tag: 'WebSocketManager');
            break;
          case 'change_table':
            logDebug('🔄 收到服务器更换桌子消息: $data', tag: 'WebSocketManager');
            break;
          default:
            logDebug('❓ 收到未知桌台操作: $action', tag: 'WebSocketManager');
        }
      } else if (type == 'cart_response') {
        final code = data['code'] as int?;
        final message = data['message'] as String?;
        final originalId = data['original_id'] as String?;
        logDebug('📨 收到服务器二次确认消息: 代码$code, 消息$message, 原始ID$originalId', tag: 'WebSocketManager');
      } else if (type == 'heartbeat') {
        // 心跳消息不输出日志
      } else {
        logDebug('❓ 收到未知类型消息: $type', tag: 'WebSocketManager');
      }

      // 通知服务器消息监听器
      for (final listener in _serverMessageListeners) {
        try {
          listener(tableId, messageData);
        } catch (e) {
          logDebug('❌ 服务器消息监听器执行出错: $e', tag: 'WebSocketManager');
        }
      }
    } catch (e) {
      logDebug('❌ 处理服务器消息失败: $e', tag: 'WebSocketManager');
    }
  }

  /// 添加服务器消息监听器
  void addServerMessageListener(Function(String tableId, Map<String, dynamic> message) listener) {
    _serverMessageListeners.add(listener);
    logDebug('📝 添加服务器消息监听器', tag: 'WebSocketManager');
  }

  /// 移除服务器消息监听器
  void removeServerMessageListener(Function(String tableId, Map<String, dynamic> message) listener) {
    _serverMessageListeners.remove(listener);
    logDebug('🗑️ 移除服务器消息监听器', tag: 'WebSocketManager');
  }

  /// 检查桌台是否已连接
  bool isTableConnected(String tableId) {
    return _tableConnections.containsKey(tableId) && 
           _tableConnections[tableId]!.isConnected;
  }

  /// 发送更换人数消息
  Future<bool> sendChangePeopleCount({
    required String tableId,
    required int adultCount,
    required int childCount,
  }) async {
    final connection = _tableConnections[tableId];
    if (connection == null) {
      logDebug('❌ 桌台 $tableId 未连接，无法发送消息', tag: 'WebSocketManager');
      return false;
    }

    try {
      final message = {
        'id': _generateMessageId(),
        'type': 'table',
        'data': {
          'action': 'change_people_count',
          'adult_count': adultCount,
          'child_count': childCount,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      final success = await connection.sendRawMessage(message);
      if (success) {
        logDebug('📤 发送更换人数消息: 桌台$tableId, 成人$adultCount, 儿童$childCount', tag: 'WebSocketManager');
      }
      return success;
    } catch (e) {
      logDebug('❌ 发送更换人数消息失败: $e', tag: 'WebSocketManager');
      return false;
    }
  }

  /// 发送更换桌子消息
  Future<bool> sendChangeTable({
    required String tableId,
    required int newTableId,
    required String newTableName,
  }) async {
    final connection = _tableConnections[tableId];
    if (connection == null) {
      logDebug('❌ 桌台 $tableId 未连接，无法发送消息', tag: 'WebSocketManager');
      return false;
    }

    try {
      final message = {
        'id': _generateMessageId(),
        'type': 'table',
        'data': {
          'action': 'change_table',
          'table_id': newTableId,
          'table_name': newTableName,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      final success = await connection.sendRawMessage(message);
      if (success) {
        logDebug('📤 发送更换桌子消息: 桌台$tableId, 新桌台$newTableId($newTableName)', tag: 'WebSocketManager');
      }
      return success;
    } catch (e) {
      logDebug('❌ 发送更换桌子消息失败: $e', tag: 'WebSocketManager');
      return false;
    }
  }

  /// 发送更换菜单消息
  Future<bool> sendChangeMenu({
    required String tableId,
    required int menuId,
  }) async {
    final connection = _tableConnections[tableId];
    if (connection == null) {
      logDebug('❌ 桌台 $tableId 未连接，无法发送消息', tag: 'WebSocketManager');
      return false;
    }

    try {
      final message = {
        'id': _generateMessageId(),
        'type': 'table',
        'data': {
          'action': 'change_menu',
          'menu_id': menuId,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      final success = await connection.sendRawMessage(message);
      if (success) {
        logDebug('📤 发送更换菜单消息: 桌台$tableId, 菜单$menuId', tag: 'WebSocketManager');
      }
      return success;
    } catch (e) {
      logDebug('❌ 发送更换菜单消息失败: $e', tag: 'WebSocketManager');
      return false;
    }
  }

  /// 获取桌台连接状态
  WebSocketConnectionState? getTableConnectionState(String tableId) {
    final connection = _tableConnections[tableId];
    return connection?.connectionState;
  }

  /// 清理资源
  void dispose() {
    disconnectAll();
    _serverMessageListeners.clear();
    logDebug('🧹 WebSocket管理器资源已清理', tag: 'WebSocketManager');
  }
}

/// WebSocket管理器单例
final WebSocketManager wsManager = WebSocketManager();