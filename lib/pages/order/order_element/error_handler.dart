import 'package:lib_base/lib_base.dart';
import '../../../utils/toast_utils.dart';

/// 错误处理器
class ErrorHandler {
  final String _logTag;

  ErrorHandler({required String logTag}) : _logTag = logTag;

  /// 处理通用错误
  void handleGenericError(int code, String message) {
    logDebug('❓ 错误代码: $code, 消息: $message', tag: _logTag);
    GlobalToast.error(message);
  }

  /// 处理API错误
  void handleApiError(String operation, String error) {
    logDebug('❌ $operation 失败: $error', tag: _logTag);
    GlobalToast.error(error);
  }

  /// 处理异常
  void handleException(String operation, dynamic exception) {
    logDebug('❌ $operation 异常: $exception', tag: _logTag);
    GlobalToast.error('操作异常: $exception');
  }
}
