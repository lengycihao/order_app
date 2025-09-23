import 'package:lib_base/lib_base.dart';
import 'package:lib_base/utils/websocket_manager.dart';

/// WebSocket生命周期管理器
/// 用于管理不同页面的WebSocket连接状态
class WebSocketLifecycleManager {
  static final WebSocketLifecycleManager _instance = WebSocketLifecycleManager._internal();
  factory WebSocketLifecycleManager() => _instance;
  WebSocketLifecycleManager._internal();

  /// 当前页面类型
  String? _currentPageType;
  
  /// 页面类型枚举
  static const String PAGE_TAKEAWAY = 'takeaway';
  static const String PAGE_ORDER = 'order';
  static const String PAGE_TABLE = 'table';
  static const String PAGE_OTHER = 'other';

  /// 设置当前页面类型
  void setCurrentPageType(String pageType) {
    if (_currentPageType != pageType) {
      logDebug('🔄 页面切换: $_currentPageType -> $pageType', tag: 'WebSocketLifecycleManager');
      _currentPageType = pageType;
      _handlePageSwitch(pageType);
    }
  }

  /// 处理页面切换
  void _handlePageSwitch(String pageType) {
    switch (pageType) {
      case PAGE_TAKEAWAY:
        _handleTakeawayPage();
        break;
      case PAGE_ORDER:
        _handleOrderPage();
        break;
      case PAGE_TABLE:
        _handleTablePage();
        break;
      default:
        _handleOtherPage();
    }
  }

  /// 处理桌台页面（外卖页面）
  void _handleTakeawayPage() {
    try {
      // 桌台页面不需要WebSocket连接，清理所有连接
      wsManager.disconnectAll();
      logDebug('🧹 桌台页面：已清理所有WebSocket连接', tag: 'WebSocketLifecycleManager');
    } catch (e) {
      logDebug('❌ 桌台页面清理WebSocket连接失败: $e', tag: 'WebSocketLifecycleManager');
    }
  }

  /// 处理点餐页面
  void _handleOrderPage() {
    try {
      // 点餐页面需要WebSocket连接，但需要确保只连接当前桌台
      logDebug('📱 点餐页面：WebSocket连接由页面自行管理', tag: 'WebSocketLifecycleManager');
    } catch (e) {
      logDebug('❌ 点餐页面WebSocket管理失败: $e', tag: 'WebSocketLifecycleManager');
    }
  }

  /// 处理桌台管理页面
  void _handleTablePage() {
    try {
      // 桌台管理页面不需要WebSocket连接
      wsManager.disconnectAll();
      logDebug('🧹 桌台管理页面：已清理所有WebSocket连接', tag: 'WebSocketLifecycleManager');
    } catch (e) {
      logDebug('❌ 桌台管理页面清理WebSocket连接失败: $e', tag: 'WebSocketLifecycleManager');
    }
  }

  /// 处理其他页面
  void _handleOtherPage() {
    try {
      // 其他页面根据需要进行WebSocket管理
      logDebug('📱 其他页面：WebSocket连接状态保持不变', tag: 'WebSocketLifecycleManager');
    } catch (e) {
      logDebug('❌ 其他页面WebSocket管理失败: $e', tag: 'WebSocketLifecycleManager');
    }
  }

  /// 获取当前页面类型
  String? get currentPageType => _currentPageType;

  /// 检查是否需要WebSocket连接
  bool needsWebSocketConnection() {
    return _currentPageType == PAGE_ORDER;
  }

  /// 清理所有连接
  void cleanupAllConnections() {
    try {
      wsManager.disconnectAll();
      _currentPageType = null;
      logDebug('🧹 已清理所有WebSocket连接', tag: 'WebSocketLifecycleManager');
    } catch (e) {
      logDebug('❌ 清理所有WebSocket连接失败: $e', tag: 'WebSocketLifecycleManager');
    }
  }

  /// 获取连接状态信息
  Map<String, dynamic> getConnectionStatus() {
    return {
      'current_page_type': _currentPageType,
      'needs_websocket': needsWebSocketConnection(),
      'websocket_stats': wsManager.connectionStats,
    };
  }
}

/// WebSocket生命周期管理器单例
final WebSocketLifecycleManager wsLifecycleManager = WebSocketLifecycleManager();
