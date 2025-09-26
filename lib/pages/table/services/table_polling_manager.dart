import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lib_base/logging/logging.dart';

/// 桌台轮询管理器
/// 负责管理桌台数据的定时轮询
class TablePollingManager {
  final String _logTag = 'TablePollingManager';
  
  Timer? _pollingTimer;
  bool _isPollingActive = false;
  Duration _pollingInterval = const Duration(seconds: 5);
  
  VoidCallback? _onPollingCallback;

  /// 启动轮询
  void startPolling({VoidCallback? onPolling}) {
    if (_isPollingActive) {
      logDebug('⚠️ 轮询已在运行中，跳过启动', tag: _logTag);
      return;
    }
    
    _onPollingCallback = onPolling;
    _isPollingActive = true;
    
    _pollingTimer = Timer.periodic(_pollingInterval, (timer) {
      _performPolling();
    });
    
    logDebug('🔄 轮询已启动，间隔: ${_pollingInterval.inSeconds}秒', tag: _logTag);
  }

  /// 停止轮询
  void stopPolling() {
    if (!_isPollingActive) {
      logDebug('⚠️ 轮询未运行，跳过停止', tag: _logTag);
      return;
    }
    
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPollingActive = false;
    _onPollingCallback = null;
    
    logDebug('⏹️ 轮询已停止', tag: _logTag);
  }

  /// 暂停轮询（页面不可见时调用）
  void pausePolling() {
    stopPolling();
    logDebug('⏸️ 轮询已暂停', tag: _logTag);
  }

  /// 恢复轮询（页面可见时调用）
  void resumePolling({VoidCallback? onPolling}) {
    if (!_isPollingActive) {
      startPolling(onPolling: onPolling);
      logDebug('▶️ 轮询已恢复', tag: _logTag);
    }
  }

  /// 执行轮询
  void _performPolling() {
    if (_onPollingCallback != null) {
      logDebug('🔄 执行轮询刷新...', tag: _logTag);
      _onPollingCallback!();
    }
  }

  /// 设置轮询间隔
  void setPollingInterval(Duration interval) {
    _pollingInterval = interval;
    logDebug('⚙️ 轮询间隔已设置为: ${interval.inSeconds}秒', tag: _logTag);
    
    // 如果轮询正在运行，重启以应用新间隔
    if (_isPollingActive) {
      stopPolling();
      startPolling(onPolling: _onPollingCallback);
    }
  }

  /// 检查轮询是否活跃
  bool get isPollingActive => _isPollingActive;

  /// 获取轮询状态信息
  Map<String, dynamic> getPollingStatus() {
    return {
      'isActive': _isPollingActive,
      'interval': _pollingInterval.inSeconds,
      'hasCallback': _onPollingCallback != null,
    };
  }

  /// 销毁管理器
  void dispose() {
    stopPolling();
    logDebug('🗑️ TablePollingManager 已销毁', tag: _logTag);
  }
}
