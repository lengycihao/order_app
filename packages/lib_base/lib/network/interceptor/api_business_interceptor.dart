import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:lib_base/network/http_resultN.dart';
import 'package:lib_base/cons/api_constants.dart';
import 'package:lib_base/network/interceptor/unauthorized_handler.dart';

/// API业务逻辑拦截器
/// 统一处理HTTP状态码和API业务状态码，确保错误能正确传递
class ApiBusinessInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      // 处理HTTP状态码
      if (!_isHttpStatusValid(response.statusCode)) {
        final errorResult = _createErrorResult(
          response.statusCode ?? -1,
          _getHttpStatusMessage(response.statusCode),
        );
        response.data = errorResult;
        super.onResponse(response, handler);
        return;
      }

      // 解析响应数据
      Map<String, dynamic> jsonMap;
      try {
        jsonMap = _parseResponseData(response.data);
      } catch (e) {
        final errorResult = _createErrorResult(
          -1,
          'Failed to parse response: ${e.toString()}',
        );
        response.data = errorResult;
        super.onResponse(response, handler);
        return;
      }

      // 提取业务状态码和消息
      final apiCode = _extractApiCode(jsonMap);
      final message = _extractMessage(jsonMap);
      final data = jsonMap['data'];

      // 处理业务逻辑
      final result = _processApiBusinessLogic(
        jsonMap,
        apiCode,
        message,
        data,
        response.statusCode ?? 200,
      );

      // 将处理后的结果放入response.data
      response.data = result;
      super.onResponse(response, handler);
    } catch (e) {
      // 如果处理失败，创建错误响应
      final errorResult = _createErrorResult(
        -1,
        'Response processing failed: ${e.toString()}',
      );
      response.data = errorResult;
      super.onResponse(response, handler);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 处理网络错误，转换为统一的HttpResultN格式
    final errorResult = _handleDioError(err);

    // 创建一个包含错误信息的响应
    final errorResponse = Response(
      statusCode: err.response?.statusCode ?? -1,
      statusMessage: err.response?.statusMessage ?? 'Network Error',
      data: errorResult,
      requestOptions: err.requestOptions,
    );

    // 将错误转换为成功响应，让上层统一处理
    handler.resolve(errorResponse);
  }

  /// 检查HTTP状态码是否有效
  bool _isHttpStatusValid(int? statusCode) {
    if (statusCode == null) return false;
    // 允许的状态码：成功状态码和需要特殊处理的错误状态码
    // 210: 数据处理中，需要重试
    const validStatusCodes = {200, 201, 202, 204, 210, 401, 403, 404, 422, 429, 500};
    return validStatusCodes.contains(statusCode);
  }

  /// 获取HTTP状态码对应的错误消息
  String _getHttpStatusMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 405:
        return 'Method Not Allowed';
      case 408:
        return 'Request Timeout';
      case 409:
        return 'Conflict';
      case 422:
        return 'Unprocessable Entity';
      case 429:
        return 'Too Many Requests';
      case 500:
        return 'Internal Server Error';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      case 504:
        return 'Gateway Timeout';
      default:
        return 'HTTP Error: $statusCode';
    }
  }

  /// 解析响应数据
  Map<String, dynamic> _parseResponseData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is String) {
      return json.decode(data) as Map<String, dynamic>;
    } else {
      throw FormatException(
        'Unsupported response data type: ${data.runtimeType}',
      );
    }
  }

  /// 提取API状态码
  int? _extractApiCode(Map<String, dynamic> jsonMap) {
    final keys = ['code', 'status', 'statusCode', 'retCode'];
    return _extractIntValue(jsonMap, keys);
  }

  /// 提取消息
  String? _extractMessage(Map<String, dynamic> jsonMap) {
    final keys = ['message', 'msg', 'description', 'detail', 'retMessage'];
    return _extractStringValue(jsonMap, keys);
  }

  /// 处理API业务逻辑
  HttpResultN _processApiBusinessLogic(
    Map<String, dynamic> jsonMap,
    int? apiCode,
    String? message,
    dynamic data,
    int httpStatusCode,
  ) {
    // 如果没有API状态码，根据数据结构判断
    if (apiCode == null) {
      return jsonMap.containsKey('data')
          ? _createSuccessResult(data, httpStatusCode, message)
          : _createErrorResult(
              -1,
              message ?? 'Invalid API response format',
            );
    }

    // 根据API状态码处理业务逻辑
    switch (apiCode) {
      case 200:
      case 0: // 有些API使用0表示成功
        return _createSuccessResult(data, apiCode, message);

      case 210: // 数据处理中，需要重试
        return _createErrorResult(apiCode, message ?? '数据处理中，请稍后重试');

      case 401:
        return _handleUnauthorized(apiCode, message);

      case 403:
        return _handleForbidden(apiCode, message);

      case 404:
        return _handleNotFound(apiCode, message);

      case 422:
        return _handleValidationError(apiCode, message);

      case 429:
        return _handleRateLimit(apiCode, message);

      case 500:
        return _handleServerError(apiCode, message);

      default:
        return _handleGenericError(apiCode, message);
    }
  }

  /// 创建成功结果
  HttpResultN _createSuccessResult(dynamic data, int code, String? message) {
    return HttpResultN(
      isSuccess: true,
      code: code,
      msg: message ?? 'Success',
      dataJson: data,
    );
  }

  /// 创建错误结果
  HttpResultN _createErrorResult(int code, String message) {
    return HttpResultN(
      isSuccess: false,
      code: code,
      msg: message,
    );
  }

  /// 处理未授权错误
  HttpResultN _handleUnauthorized(int code, String? message) {
    // 使用专门的UnauthorizedHandler处理401错误
    final handled = UnauthorizedHandler.instance.handle401Error(message);
    
    if (!handled) {
      print('🔒 401错误被跳过处理（防重复机制）');
    }

    return _createErrorResult(
      code,
      message ?? 'Unauthorized - Please login again',
    );
  }

  /// 处理禁止访问错误
  HttpResultN _handleForbidden(int code, String? message) {
    return _createErrorResult(
      code,
      message ?? 'Access forbidden - Insufficient permissions',
    );
  }

  /// 处理资源不存在错误
  HttpResultN _handleNotFound(int code, String? message) {
    return _createErrorResult(
      code,
      message ?? 'Resource not found',
    );
  }

  /// 处理验证错误
  HttpResultN _handleValidationError(int code, String? message) {
    return _createErrorResult(
      code,
      message ?? 'Validation failed - Please check your input',
    );
  }

  /// 处理频率限制错误
  HttpResultN _handleRateLimit(int code, String? message) {
    return _createErrorResult(
      code,
      message ?? 'Too many requests - Please try again later',
    );
  }

  /// 处理服务器错误
  HttpResultN _handleServerError(int code, String? message) {
    return _createErrorResult(
      code,
      message ?? 'Server error - Please try again later',
    );
  }

  /// 处理通用错误
  HttpResultN _handleGenericError(int apiCode, String? message) {
    return _createErrorResult(
      apiCode,
      message ?? 'Request failed',
    );
  }

  /// 处理Dio网络错误
  HttpResultN _handleDioError(DioException e) {
    if (e.response != null) {
      // 如果有响应，尝试解析响应中的错误信息
      try {
        final jsonMap = _parseResponseData(e.response!.data);
        final message = _extractMessage(jsonMap);

        return _createErrorResult(
          e.response!.statusCode ?? -1,
          message ??
              "HTTP ${e.response!.statusCode}: ${e.response!.statusMessage ?? 'Unknown error'}",
        );
      } catch (_) {
        // 解析失败，使用默认错误信息
        return _createErrorResult(
          e.response!.statusCode ?? -1,
          "HTTP ${e.response!.statusCode}: ${e.response!.statusMessage ?? 'Unknown error'}",
        );
      }
    }

    // 网络层错误
    return _createErrorResult(
      _getDioErrorCode(e.type),
      _getDioErrorMessage(e),
    );
  }

  /// 获取Dio错误对应的错误码
  int _getDioErrorCode(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return ApiConstants.connectionTimeout;
      case DioExceptionType.sendTimeout:
        return ApiConstants.sendTimeout;
      case DioExceptionType.receiveTimeout:
        return ApiConstants.receiveTimeout;
      case DioExceptionType.cancel:
        return ApiConstants.requestCancelled;
      case DioExceptionType.connectionError:
        return ApiConstants.connectionError;
      case DioExceptionType.badCertificate:
        return ApiConstants.certificateError;
      case DioExceptionType.badResponse:
        return ApiConstants.badResponse;
      case DioExceptionType.unknown:
        return ApiConstants.networkError;
    }
  }

  /// 获取Dio错误对应的错误消息
  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络后重试';
      case DioExceptionType.sendTimeout:
        return '发送超时，请检查网络后重试';
      case DioExceptionType.receiveTimeout:
        return '接收超时，请检查网络后重试';
      case DioExceptionType.cancel:
        return '请求取消';
      case DioExceptionType.connectionError:
        return '网络异常，请检查网络后重试';
      case DioExceptionType.badCertificate:
        return 'SSL证书错误，请检查网络后重试';
      case DioExceptionType.badResponse:
        return '响应格式错误，请检查网络后重试';
      case DioExceptionType.unknown:
        if (e.error != null) {
          if (e.error.toString().contains("HandshakeException")) {
            return "SSL握手失败，请检查网络后重试";
          } else {
            return e.error.toString();
          }
        } else {
          return e.message ?? "未知网络错误，请检查网络后重试";
        }
    }
  }

  /// 提取整数值
  int? _extractIntValue(Map<String, dynamic> jsonMap, List<String> keys) {
    for (final key in keys) {
      if (jsonMap.containsKey(key)) {
        final value = jsonMap[key];
        if (value is int) return value;
        if (value is String) return int.tryParse(value);
      }
    }
    return null;
  }

  /// 提取字符串值
  String? _extractStringValue(Map<String, dynamic> jsonMap, List<String> keys) {
    for (final key in keys) {
      if (jsonMap.containsKey(key)) {
        final value = jsonMap[key];
        if (value is String) return value;
        return value?.toString();
      }
    }
    return null;
  }
}
