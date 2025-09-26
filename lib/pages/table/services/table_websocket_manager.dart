import 'dart:async';
import 'package:get/get.dart';
import 'package:lib_base/utils/websocket_manager.dart';
import 'package:lib_base/logging/logging.dart';

/// 桌台WebSocket状态管理器
/// 负责管理WebSocket连接状态监控
class TableWebSocketManager {
  final WebSocketManager _wsManager;
  final String _logTag = 'TableWebSocketManager';
  
  Timer? _statusTimer;
  final isWebSocketConnected = false.obs;

  TableWebSocketManager({required WebSocketManager wsManager}) 
      : _wsManager = wsManager;

  /// 初始化WebSocket连接状态监听
  void initializeStatusMonitoring() {
    // 定期检查WebSocket连接状态
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkConnectionStatus();
    });
    
    logDebug('🔌 WebSocket状态监控已启动', tag: _logTag);
  }

  /// 检查连接状态
  void _checkConnectionStatus() {
    final stats = _wsManager.connectionStats;
    final isConnected = stats['total_connections'] > 0;
    
    if (isWebSocketConnected.value != isConnected) {
      isWebSocketConnected.value = isConnected;
      logDebug('🔌 WebSocket连接状态变化: $isConnected', tag: _logTag);
    }
  }

  /// 获取WebSocket连接统计信息
  Map<String, dynamic> getConnectionStats() {
    return _wsManager.connectionStats;
  }

  /// 手动检查连接状态
  void checkConnectionStatus() {
    _checkConnectionStatus();
  }

  /// 销毁管理器
  void dispose() {
    _statusTimer?.cancel();
    _statusTimer = null;
    logDebug('🗑️ TableWebSocketManager 已销毁', tag: _logTag);
  }
}
