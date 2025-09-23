import 'package:flutter/material.dart';
import 'package:order_app/pages/order/components/force_update_dialog.dart';

/// 弹窗管理器 - 确保同时只显示一个弹窗
class DialogManager {
  static final DialogManager _instance = DialogManager._internal();
  factory DialogManager() => _instance;
  DialogManager._internal();

  /// 当前是否有弹窗正在显示
  bool _isDialogShowing = false;
  
  /// 当前弹窗的上下文
  BuildContext? _currentDialogContext;
  
  /// 当前弹窗的类型
  String? _currentDialogType;

  /// 检查是否有弹窗正在显示
  bool get isDialogShowing => _isDialogShowing;

  /// 获取当前弹窗类型
  String? get currentDialogType => _currentDialogType;

  /// 显示409强制更新弹窗
  /// 如果已有弹窗显示，会先关闭当前弹窗再显示新的
  Future<void> showForceUpdateDialog({
    required BuildContext context,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) async {
    logDebug('🔍 检查弹窗状态: isDialogShowing=$_isDialogShowing, currentType=$_currentDialogType');
    
    // 如果已有弹窗显示，先关闭当前弹窗
    if (_isDialogShowing) {
      logDebug('⚠️ 检测到已有弹窗显示，先关闭当前弹窗: $_currentDialogType');
      await _closeCurrentDialog();
    }
    
    // 标记弹窗状态
    _isDialogShowing = true;
    _currentDialogContext = context;
    _currentDialogType = 'force_update';
    
    logDebug('✅ 开始显示409强制更新弹窗');
    
    try {
      await ForceUpdateDialog.show(
        context,
        message: message,
        onConfirm: () {
          logDebug('✅ 用户确认409强制更新');
          _clearDialogState();
          onConfirm();
        },
        onCancel: () {
          logDebug('❌ 用户取消409强制更新');
          _clearDialogState();
          onCancel?.call();
        },
      );
    } catch (e) {
      logDebug('❌ 显示409弹窗异常: $e');
      _clearDialogState();
    }
  }

  /// 显示通用确认弹窗
  /// 如果已有弹窗显示，会先关闭当前弹窗再显示新的
  Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = '确认',
    String cancelText = '取消',
    Color? confirmColor,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) async {
    logDebug('🔍 检查弹窗状态: isDialogShowing=$_isDialogShowing, currentType=$_currentDialogType');
    
    // 如果已有弹窗显示，先关闭当前弹窗
    if (_isDialogShowing) {
      logDebug('⚠️ 检测到已有弹窗显示，先关闭当前弹窗: $_currentDialogType');
      await _closeCurrentDialog();
    }
    
    // 标记弹窗状态
    _isDialogShowing = true;
    _currentDialogContext = context;
    _currentDialogType = 'confirm';
    
    logDebug('✅ 开始显示通用确认弹窗');
    
    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                logDebug('❌ 用户取消通用确认弹窗');
                _clearDialogState();
                onCancel?.call();
                Navigator.of(context).pop(false);
              },
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () {
                logDebug('✅ 用户确认通用确认弹窗');
                _clearDialogState();
                onConfirm?.call();
                Navigator.of(context).pop(true);
              },
              style: TextButton.styleFrom(
                foregroundColor: confirmColor ?? Colors.red,
              ),
              child: Text(confirmText),
            ),
          ],
        ),
      );
      
      return result;
    } catch (e) {
      logDebug('❌ 显示通用确认弹窗异常: $e');
      _clearDialogState();
      return false;
    }
  }

  /// 关闭当前弹窗
  Future<void> _closeCurrentDialog() async {
    if (_currentDialogContext != null && _isDialogShowing) {
      try {
        logDebug('🔄 正在关闭当前弹窗: $_currentDialogType');
        Navigator.of(_currentDialogContext!).pop();
        
        // 等待弹窗关闭动画完成
        await Future.delayed(Duration(milliseconds: 300));
        
        logDebug('✅ 当前弹窗已关闭');
      } catch (e) {
        logDebug('❌ 关闭当前弹窗异常: $e');
      }
    }
    
    _clearDialogState();
  }

  /// 清理弹窗状态
  void _clearDialogState() {
    _isDialogShowing = false;
    _currentDialogContext = null;
    _currentDialogType = null;
    logDebug('🧹 弹窗状态已清理');
  }

  /// 强制关闭所有弹窗（紧急情况使用）
  void forceCloseAllDialogs() {
    if (_isDialogShowing && _currentDialogContext != null) {
      try {
        logDebug('🚨 强制关闭所有弹窗');
        Navigator.of(_currentDialogContext!).pop();
      } catch (e) {
        logDebug('❌ 强制关闭弹窗异常: $e');
      }
    }
    _clearDialogState();
  }

  /// 调试日志
  void logDebug(String message) {
    print('[DialogManager] $message');
  }
}

/// 弹窗管理器单例
final DialogManager dialogManager = DialogManager();
