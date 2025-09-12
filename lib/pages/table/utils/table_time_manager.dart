import 'dart:async';
import 'package:flutter/foundation.dart';

/// 桌台时间管理器 - 全局单例，统一管理所有桌台的时间更新
/// 性能优化：使用单个Timer管理所有桌台的时间更新，而不是每个桌台都创建Timer
class TableTimeManager {
  static final TableTimeManager _instance = TableTimeManager._internal();
  factory TableTimeManager() => _instance;
  TableTimeManager._internal();

  Timer? _globalTimer;
  final Map<String, TableTimeData> _tableTimes = {};
  final Map<String, VoidCallback> _callbacks = {};

  /// 注册桌台时间更新
  void registerTable(String tableId, int initialDuration, VoidCallback onUpdate) {
    _tableTimes[tableId] = TableTimeData(
      initialDuration: initialDuration,
      startTime: DateTime.now(),
    );
    _callbacks[tableId] = onUpdate;
    
    _startGlobalTimer();
  }

  /// 注销桌台时间更新
  void unregisterTable(String tableId) {
    _tableTimes.remove(tableId);
    _callbacks.remove(tableId);
    
    if (_tableTimes.isEmpty) {
      _stopGlobalTimer();
    }
  }

  /// 更新桌台的初始时间（当桌台数据刷新时）
  void updateTableInitialTime(String tableId, int newInitialDuration) {
    final existing = _tableTimes[tableId];
    if (existing != null) {
      _tableTimes[tableId] = TableTimeData(
        initialDuration: newInitialDuration,
        startTime: DateTime.now(),
      );
    }
  }

  /// 获取桌台当前时间
  int getCurrentDuration(String tableId) {
    final data = _tableTimes[tableId];
    if (data == null) return 0;
    
    final elapsed = DateTime.now().difference(data.startTime).inSeconds;
    return data.initialDuration + elapsed;
  }

  void _startGlobalTimer() {
    if (_globalTimer != null) return;
    
    _globalTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      // 批量更新所有注册的桌台
      for (final callback in _callbacks.values) {
        callback();
      }
    });
  }

  void _stopGlobalTimer() {
    _globalTimer?.cancel();
    _globalTimer = null;
  }

  /// 清理所有资源
  void dispose() {
    _stopGlobalTimer();
    _tableTimes.clear();
    _callbacks.clear();
  }
}

/// 桌台时间数据
class TableTimeData {
  final int initialDuration;
  final DateTime startTime;

  TableTimeData({
    required this.initialDuration,
    required this.startTime,
  });
}
