import 'package:lib_base/lib_base.dart';
import '../components/error_notification_manager.dart';

/// 错误处理器
class ErrorHandler {
  final String _logTag;
  final ErrorNotificationManager _errorNotificationManager = ErrorNotificationManager();

  ErrorHandler({required String logTag}) : _logTag = logTag;

  /// 处理通用错误
  void handleGenericError(int code, String message) {
    logDebug('❓ 错误代码: $code, 消息: $message', tag: _logTag);
    _errorNotificationManager.showErrorNotification(
      title: '操作失败',
      message: message,
      errorCode: code.toString(),
    );
  }

  /// 处理API错误
  void handleApiError(String operation, String error) {
    logDebug('❌ $operation 失败: $error', tag: _logTag);
    _errorNotificationManager.showErrorNotification(
      title: '操作失败',
      message: error,
      errorCode: 'api_error',
    );
  }

  /// 处理异常
  void handleException(String operation, dynamic exception) {
    logDebug('❌ $operation 异常: $exception', tag: _logTag);
    _errorNotificationManager.showErrorNotification(
      title: '系统异常',
      message: '操作异常: $exception',
      errorCode: 'system_exception',
    );
  }
}
