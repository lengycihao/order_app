import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// WebSocket连接状态
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// WebSocket配置
class WebSocketConfig {
  final String serverUrl;
  final String tableId;
  final String? token;
  final String? language;

  const WebSocketConfig({
    required this.serverUrl,
    required this.tableId,
    this.token,
    this.language,
  });

  /// 构建完整的WebSocket URL
  String buildFullUrl() {
    final uri = Uri.parse(serverUrl);
    final queryParams = <String, String>{
      'table_id': tableId,
    };
    
    if (token != null && token!.isNotEmpty) {
      queryParams['W-Token'] = token!;
    }
    
    return uri.replace(queryParameters: queryParams).toString();
  }

  /// 从URL解析配置
  static WebSocketConfig fromUrl(String fullUrl) {
    final uri = Uri.parse(fullUrl);
    return WebSocketConfig(
      serverUrl: '${uri.scheme}://${uri.host}:${uri.port}${uri.path}',
      tableId: uri.queryParameters['table_id'] ?? '',
      token: uri.queryParameters['W-Token'],
    );
  }

  @override
  String toString() {
    return 'WebSocketConfig(serverUrl: $serverUrl, tableId: $tableId, token: ${token?.substring(0, 20) ?? 'null'}..., language: $language)';
  }
}

/// WebSocket工具类 - 专注于底层连接管理
class WebSocketUtil {
  static final WebSocketUtil _instance = WebSocketUtil._internal();
  factory WebSocketUtil() => _instance;
  WebSocketUtil._internal();

  WebSocket? _webSocket;
  String? _serverUrl;
  String? _currentTableId;
  String? _currentLanguage;
  
  /// 连接状态
  final ValueNotifier<WebSocketConnectionState> _connectionState = 
      ValueNotifier(WebSocketConnectionState.disconnected);
  
  /// 重连定时器
  Timer? _reconnectTimer;
  
  /// 心跳定时器
  Timer? _heartbeatTimer;
  
  /// 是否已dispose，防止dispose后继续重连
  bool _isDisposed = false;
  
  /// 原始消息监听器（用于接收服务器消息）
  final List<Function(Map<String, dynamic>)> _rawMessageListeners = [];
  
  /// 连接状态监听器
  final List<Function(WebSocketConnectionState)> _connectionStateListeners = [];

  /// 获取当前连接状态
  WebSocketConnectionState get connectionState => _connectionState.value;
  
  /// 获取当前桌台ID
  String? get currentTableId => _currentTableId;
  
  /// 是否已连接
  bool get isConnected => _connectionState.value == WebSocketConnectionState.connected;

  /// 初始化WebSocket连接
  Future<bool> initialize(WebSocketConfig config) async {
    try {
      _serverUrl = config.buildFullUrl();
      _currentTableId = config.tableId;
      _currentLanguage = config.language;
      
      debugPrint('🔌 WebSocket初始化配置: $config');
      debugPrint('🔌 WebSocket连接URL: $_serverUrl');
      
      return await _connect();
    } catch (e) {
      debugPrint('❌ WebSocket初始化失败: $e');
      _connectionState.value = WebSocketConnectionState.error;
      return false;
    }
  }

  /// 建立WebSocket连接
  Future<bool> _connect() async {
    if (_serverUrl == null) {
      debugPrint('❌ WebSocket服务器地址未设置');
      return false;
    }

    try {
      _connectionState.value = WebSocketConnectionState.connecting;
      debugPrint('🔌 正在连接WebSocket: $_serverUrl');

      // 构建headers
      final headers = <String, String>{
        'tableId': _currentTableId!,
      };
      
      // 添加语言头（如果有的话）
      if (_currentLanguage != null && _currentLanguage!.isNotEmpty) {
        headers['Language'] = _currentLanguage!;
        debugPrint('🌐 WebSocket添加语言头: $_currentLanguage');
      }

      _webSocket = await WebSocket.connect(
        _serverUrl!,
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      _connectionState.value = WebSocketConnectionState.connected;
      debugPrint('✅ WebSocket连接成功');

      // 设置消息监听
      _webSocket!.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      // 启动心跳
      _startHeartbeat();

      // 通知连接状态变化
      _notifyConnectionStateChange();

      return true;
    } catch (e) {
      debugPrint('❌ WebSocket连接失败: $e');
      _connectionState.value = WebSocketConnectionState.error;
      _notifyConnectionStateChange();
      _scheduleReconnect();
      return false;
    }
  }

  /// 处理接收到的消息
  void _onMessage(dynamic data) {
    try {
      final Map<String, dynamic> messageJson = jsonDecode(data as String);
      
      // 过滤心跳消息的日志输出
      final messageType = messageJson['type'] as String?;
      if (messageType != 'heartbeat') {
        debugPrint('📨 收到WebSocket原始消息: $messageJson');
      }
      
      // 触发原始消息监听器
      for (final listener in _rawMessageListeners) {
        try {
          listener(messageJson);
        } catch (e) {
          debugPrint('❌ 原始消息监听器执行出错: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ 解析WebSocket消息失败: $e');
    }
  }

  /// 处理连接错误
  void _onError(dynamic error) {
    debugPrint('❌ WebSocket连接错误: $error');
    _connectionState.value = WebSocketConnectionState.error;
    _notifyConnectionStateChange();
    _scheduleReconnect();
  }

  /// 处理连接关闭
  void _onDone() {
    debugPrint('🔌 WebSocket连接已关闭');
    _connectionState.value = WebSocketConnectionState.disconnected;
    _notifyConnectionStateChange();
    _scheduleReconnect();
  }

  /// 发送原始JSON消息
  Future<bool> sendRawMessage(Map<String, dynamic> messageData) async {
    if (_connectionState.value != WebSocketConnectionState.connected) {
      debugPrint('⚠️ WebSocket未连接，无法发送消息');
      return false;
    }

    try {
      final messageJson = jsonEncode(messageData);
      _webSocket?.add(messageJson);
      
      // 过滤心跳消息的日志输出
      final messageType = messageData['type'] as String?;
      if (messageType != 'heartbeat') {
        debugPrint('📤 发送WebSocket消息: $messageData');
      }
      return true;
    } catch (e) {
      debugPrint('❌ 发送WebSocket消息失败: $e');
      return false;
    }
  }

  /// 启动心跳机制
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_connectionState.value == WebSocketConnectionState.connected) {
        _sendHeartbeat();
      }
    });
  }

  /// 发送心跳
  void _sendHeartbeat() {
    final heartbeatMessage = {
      'id': _generateMessageId(),
      'type': 'heartbeat',
      'data': {},
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    
    sendRawMessage(heartbeatMessage);
  }

  /// 生成20位随机消息ID
  String _generateMessageId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final randomPart = List.generate(20 - random.length, (index) => 
        chars[DateTime.now().microsecond % chars.length]).join();
    return random + randomPart;
  }

  /// 安排重连
  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive == true || _isDisposed) return;
    
    _connectionState.value = WebSocketConnectionState.reconnecting;
    _notifyConnectionStateChange();
    
    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      if (_isDisposed) {
        debugPrint('⚠️ WebSocket已dispose，取消重连');
        return;
      }
      debugPrint('🔄 尝试重新连接WebSocket...');
      await _connect();
    });
  }

  /// 通知连接状态变化
  void _notifyConnectionStateChange() {
    for (final listener in _connectionStateListeners) {
      try {
        listener(_connectionState.value);
      } catch (e) {
        debugPrint('❌ 连接状态监听器执行出错: $e');
      }
    }
  }

  /// 添加原始消息监听器
  void addRawMessageListener(Function(Map<String, dynamic>) listener) {
    _rawMessageListeners.add(listener);
    debugPrint('📝 添加原始消息监听器');
  }

  /// 移除原始消息监听器
  void removeRawMessageListener(Function(Map<String, dynamic>) listener) {
    _rawMessageListeners.remove(listener);
    debugPrint('🗑️ 移除原始消息监听器');
  }

  /// 添加连接状态监听器
  void addConnectionStateListener(Function(WebSocketConnectionState) listener) {
    _connectionStateListeners.add(listener);
    debugPrint('📝 添加连接状态监听器');
  }

  /// 移除连接状态监听器
  void removeConnectionStateListener(Function(WebSocketConnectionState) listener) {
    _connectionStateListeners.remove(listener);
    debugPrint('🗑️ 移除连接状态监听器');
  }

  /// 手动重连
  Future<bool> reconnect() async {
    debugPrint('🔄 手动重连WebSocket...');
    await disconnect();
    return await _connect();
  }

  /// 断开连接
  Future<void> disconnect() async {
    debugPrint('🔌 断开WebSocket连接...');
    
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    
    await _webSocket?.close();
    _webSocket = null;
    
    _connectionState.value = WebSocketConnectionState.disconnected;
    _notifyConnectionStateChange();
    
    debugPrint('✅ WebSocket连接已断开');
  }

  /// 清理资源
  void dispose() {
    _isDisposed = true;
    disconnect();
    _rawMessageListeners.clear();
    _connectionStateListeners.clear();
    debugPrint('🧹 WebSocket资源已清理');
  }
}

/// WebSocket工具类单例
final WebSocketUtil wsUtil = WebSocketUtil();