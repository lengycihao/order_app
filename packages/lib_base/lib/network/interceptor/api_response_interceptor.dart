import 'package:dio/dio.dart';
import 'package:get/get.dart' as gg;
import 'package:lib_base/network/interceptor/auth_service.dart';
import 'package:order_app/service/service_locator.dart';
import 'package:order_app/services/language_service.dart';

/// 请求头拦截器 - 负责添加认证信息
class ApiResponseInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 添加认证token
    try {
      String? token;
      
      // 优先尝试从GetIt获取AuthService
      try {
        final authService = getIt<AuthService>();
        token = authService.getCurrentToken();
        print('🔑 从GetIt获取AuthService成功');
      } catch (e) {
        // 如果GetIt获取失败，尝试从GetX获取
        try {
          final authService = gg.Get.find<AuthService>();
          token = authService.getCurrentToken();
          print('🔑 从GetX获取AuthService成功');
        } catch (e2) {
          print('🔑 无法获取AuthService: GetIt错误=$e, GetX错误=$e2');
        }
      }
      
      if (token != null && token.isNotEmpty) {
        options.headers['W-Token'] = token;
        print('🔑 使用用户token: ${token.substring(0, 20)}...');
      } else {
        // 如果没有token，使用默认token（仅用于测试）
        options.headers['W-Token'] = 
            "ChCQ_nVvpUKhvJiyMZDFWJMDuReETt8uwCez7tkXKi0Lh2lTe2Tw_yuHurJ8PIkybynfIUG0vDI_bJJ99wlbB5SChuBO8zAlDYhZKUDWhOlHABJ-pp8uoE9-tTWBKlkFf6SDlmKt86SlTlJKuUQwjTXcTUVzWv1P1LCEodT3C1Y=";
        print('🔑 使用默认token');
      }
    } catch (e) {
      // 如果无法获取AuthService，使用默认token
      options.headers['W-Token'] = 
          "ChCQ_nVvpUKhvJiyMZDFWJMDuReETt8uwCez7tkXKi0Lh2lTe2Tw_yuHurJ8PIkybynfIUG0vDI_bJJ99wlbB5SChuBO8zAlDYhZKUDWhOlHABJ-pp8uoE9-tTWBKlkFf6SDlmKt86SlTlJKuUQwjTXcTUVzWv1P1LCEodT3C1Y=";
      print('🔑 异常情况使用默认token: $e');
    }

    // 添加语言头
    try {
      final languageService = getIt<LanguageService>();
      final serverLanguageCode = languageService.getNetworkLanguageCode();
      
      options.headers['Language'] = serverLanguageCode;
      print('🌐 添加语言头: ${languageService.currentLocale.languageCode} -> $serverLanguageCode');
    } catch (e) {
      // 如果无法获取LanguageService，使用默认语言
      options.headers['Language'] = 'cn';
      print('🌐 无法获取LanguageService，使用默认语言: cn, 错误: $e');
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 这个拦截器现在只负责添加请求头
    // 业务逻辑处理由ApiBusinessInterceptor负责
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 这个拦截器现在只负责添加请求头
    // 错误处理由ApiBusinessInterceptor负责
    super.onError(err, handler);
  }
}

// /// API业务逻辑拦截器
// /// 处理HTTP状态码和API业务状态码的统一逻辑
// class ApiResponseInterceptor extends Interceptor {
//   @override
//   void onResponse(Response response, ResponseInterceptorHandler handler) {
//     try {
//       final processedResponse = _processApiResponse(response);
//       // 将处理后的HttpResultN放入response.data中
//       response.data = processedResponse;
//       super.onResponse(response, handler);
//     } catch (e) {
//       // 如果处理失败，创建错误响应
//       final errorResult = HttpResultN(
//         isSuccess: false,
//         code: -1,
//         msg: 'Response processing failed: ${e.toString()}',
//       );
//       response.data = errorResult;
//       super.onResponse(response, handler);
//     }
//   }

//   @override
//   void onError(DioException err, ErrorInterceptorHandler handler) {
//     // 处理网络错误，转换为统一的HttpResultN格式
//     final errorResult = _handleDioError(err);

//     // 创建一个包含错误信息的响应
//     final errorResponse = Response(
//       statusCode: err.response?.statusCode ?? -1,
//       statusMessage: err.response?.statusMessage ?? 'Network Error',
//       data: errorResult,
//       requestOptions: err.requestOptions,
//     );

//     // 将错误转换为成功响应，让上层统一处理
//     handler.resolve(errorResponse);
//   }

//   /// 处理API响应的核心逻辑
//   HttpResultN _processApiResponse(Response response) {
//     // 处理HTTP状态码
//     if (!_isHttpStatusValid(response.statusCode)) {
//       return HttpResultN(
//         isSuccess: false,
//         code: response.statusCode ?? -1,
//         msg: _getHttpStatusMessage(response.statusCode),
//       );
//     }

//     // 解析响应数据
//     Map<String, dynamic> jsonMap;
//     try {
//       jsonMap = _parseResponseData(response.data);
//     } catch (e) {
//       return HttpResultN(
//         isSuccess: false,
//         code: -1,
//         msg: 'Failed to parse response: ${e.toString()}',
//       );
//     }

//     // 提取通用字段
//     final apiCode = _extractApiCode(jsonMap);
//     final message = _extractMessage(jsonMap);
//     final errorCode = _extractErrorCode(jsonMap);

//     // 处理API业务状态码
//     return _processApiBusinessLogic(jsonMap, apiCode, message, errorCode);
//   }

//   /// 检查HTTP状态码是否有效
//   bool _isHttpStatusValid(int? statusCode) {
//     if (statusCode == null) return false;

//     // 可以在这里配置哪些HTTP状态码被认为是有效的
//     const validStatusCodes = {200, 201, 202, 204, 401, 422, 429};
//     return validStatusCodes.contains(statusCode);
//   }

//   /// 获取HTTP状态码对应的错误消息
//   String _getHttpStatusMessage(int? statusCode) {
//     switch (statusCode) {
//       case 400:
//         return 'Bad Request';
//       case 401:
//         return 'Unauthorized';
//       case 403:
//         return 'Forbidden';
//       case 404:
//         return 'Not Found';
//       case 405:
//         return 'Method Not Allowed';
//       case 408:
//         return 'Request Timeout';
//       case 409:
//         return 'Conflict';
//       case 422:
//         return 'Unprocessable Entity';
//       case 429:
//         return 'Too Many Requests';
//       case 500:
//         return 'Internal Server Error';
//       case 502:
//         return 'Bad Gateway';
//       case 503:
//         return 'Service Unavailable';
//       case 504:
//         return 'Gateway Timeout';
//       default:
//         return 'HTTP Error: $statusCode';
//     }
//   }

//   /// 解析响应数据
//   Map<String, dynamic> _parseResponseData(dynamic data) {
//     if (data is Map<String, dynamic>) {
//       return data;
//     } else if (data is String) {
//       return json.decode(data) as Map<String, dynamic>;
//     } else {
//       throw FormatException(
//         'Unsupported response data type: ${data.runtimeType}',
//       );
//     }
//   }

//   /// 提取API状态码 code
//   int? _extractApiCode(Map<String, dynamic> jsonMap) {
//     final keys = _getCodeKeys();
//     return _extractIntValue(jsonMap, keys);
//   }

//   /// 提取错误码 errorCode
//   int? _extractErrorCode(Map<String, dynamic> jsonMap) {
//     final keys = _getErrorCodeKeys();
//     return _extractIntValue(jsonMap, keys);
//   }

//   /// 提取消息 message
//   String? _extractMessage(Map<String, dynamic> jsonMap) {
//     final keys = _getMessageKeys();
//     return _extractStringValue(jsonMap, keys);
//   }

//   /// 处理API业务逻辑
//   HttpResultN _processApiBusinessLogic(
//     Map<String, dynamic> jsonMap,
//     int? apiCode,
//     String? message,
//     int? errorCode,
//   ) {
//     // 如果没有API状态码，根据数据结构判断
//     if (apiCode == null) {
//       final dataKey = _getDataKey();
//       return jsonMap.containsKey(dataKey)
//           ? _createSuccessResult(jsonMap, 200, message)
//           : HttpResultN(
//               isSuccess: false,
//               code: errorCode ?? -1,
//               msg: message ?? 'Invalid API response format',
//             );
//     }

//     // 根据API状态码处理业务逻辑
//     switch (apiCode) {
//       case 200:
//       case 0: // 有些API使用0表示成功
//         return _createSuccessResult(jsonMap, apiCode, message);

//       case 401:
//         return _handleUnauthorized(apiCode, message);

//       case 403:
//         return _handleForbidden(apiCode, message);

//       case 404:
//         return _handleNotFound(apiCode, message);

//       case 422:
//         return _handleValidationError(apiCode, message);

//       case 429:
//         return _handleRateLimit(apiCode, message);

//       case 500:
//         return _handleServerError(apiCode, message);

//       default:
//         return _handleGenericError(apiCode, errorCode, message);
//     }
//   }

//   /// 创建成功结果 data
//   HttpResultN _createSuccessResult(
//     Map<String, dynamic> jsonMap,
//     int code,
//     String? message,
//   ) {
//     final dataKey = _getDataKey();
//     final data = jsonMap[dataKey];

//     return data is List<dynamic>
//         ? HttpResultN(isSuccess: true, code: code, msg: message, listJson: data)
//         : HttpResultN(isSuccess: true, code: code, msg: message, dataJson: data);
//   }

//   /// 处理未授权错误
//   HttpResultN _handleUnauthorized(int code, String? message) {
//     // 可以在这里添加自动登出逻辑
//     // AuthService.logout();

//     return HttpResultN(
//       isSuccess: false,
//       code: code,
//       msg: message ?? 'Unauthorized - Please login again',
//     );
//   }

//   /// 处理禁止访问错误
//   HttpResultN _handleForbidden(int code, String? message) {
//     return HttpResultN(
//       isSuccess: false,
//       code: code,
//       msg: message ?? 'Access forbidden - Insufficient permissions',
//     );
//   }

//   /// 处理资源不存在错误
//   HttpResultN _handleNotFound(int code, String? message) {
//     return HttpResultN(
//       isSuccess: false,
//       code: code,
//       msg: message ?? 'Resource not found',
//     );
//   }

//   /// 处理验证错误
//   HttpResultN _handleValidationError(int code, String? message) {
//     return HttpResultN(
//       isSuccess: false,
//       code: code,
//       msg: message ?? 'Validation failed - Please check your input',
//     );
//   }

//   /// 处理频率限制错误
//   HttpResultN _handleRateLimit(int code, String? message) {
//     return HttpResultN(
//       isSuccess: false,
//       code: code,
//       msg: message ?? 'Too many requests - Please try again later',
//     );
//   }

//   /// 处理服务器错误
//   HttpResultN _handleServerError(int code, String? message) {
//     return HttpResultN(
//       isSuccess: false,
//       code: code,
//       msg: message ?? 'Server error - Please try again later',
//     );
//   }

//   /// 处理通用错误
//   HttpResultN _handleGenericError(
//     int? apiCode,
//     int? errorCode,
//     String? message,
//   ) {
//     return HttpResultN(
//       isSuccess: false,
//       code: errorCode ?? apiCode ?? -1,
//       msg: message ?? 'Request failed',
//     );
//   }

//   /// 处理Dio网络错误
//   HttpResultN _handleDioError(DioException e) {
//     if (e.response != null) {
//       // 如果有响应，尝试解析响应中的错误信息
//       try {
//         final jsonMap = _parseResponseData(e.response!.data);
//         final message = _extractMessage(jsonMap);

//         return HttpResultN(
//           isSuccess: false,
//           code: e.response!.statusCode ?? -1,
//           msg:
//               message ??
//               "HTTP ${e.response!.statusCode}: ${e.response!.statusMessage ?? 'Unknown error'}",
//         );
//       } catch (_) {
//         // 解析失败，使用默认错误信息
//         return HttpResultN(
//           isSuccess: false,
//           code: e.response!.statusCode ?? -1,
//           msg:
//               "HTTP ${e.response!.statusCode}: ${e.response!.statusMessage ?? 'Unknown error'}",
//         );
//       }
//     }

//     // 网络层错误
//     return HttpResultN(
//       isSuccess: false,
//       code: _getDioErrorCode(e.type),
//       msg: _getDioErrorMessage(e),
//     );
//   }

//   /// 获取Dio错误对应的错误码
//   int _getDioErrorCode(DioExceptionType type) {
//     switch (type) {
//       case DioExceptionType.connectionTimeout:
//         return -1001;
//       case DioExceptionType.sendTimeout:
//         return -1002;
//       case DioExceptionType.receiveTimeout:
//         return -1003;
//       case DioExceptionType.cancel:
//         return -1004;
//       case DioExceptionType.connectionError:
//         return -1005;
//       case DioExceptionType.badCertificate:
//         return -1006;
//       case DioExceptionType.badResponse:
//         return -1007;
//       case DioExceptionType.unknown:
//         return -1000;
//     }
//   }

//   /// 获取Dio错误对应的错误消息
//   String _getDioErrorMessage(DioException e) {
//     switch (e.type) {
//       case DioExceptionType.connectionTimeout:
//         return 'Connection timeout - Please check your network';
//       case DioExceptionType.sendTimeout:
//         return 'Send timeout - Request took too long';
//       case DioExceptionType.receiveTimeout:
//         return 'Receive timeout - Server response took too long';
//       case DioExceptionType.cancel:
//         return 'Request cancelled';
//       case DioExceptionType.connectionError:
//         return 'Network connection error - Please check your internet';
//       case DioExceptionType.badCertificate:
//         return 'SSL certificate error - Secure connection failed';
//       case DioExceptionType.badResponse:
//         return 'Bad response format from server';
//       case DioExceptionType.unknown:
//         if (e.error != null) {
//           if (e.error.toString().contains("HandshakeException")) {
//             return "SSL handshake failed - Please check your network connection";
//           } else {
//             return e.error.toString();
//           }
//         } else {
//           return e.message ?? "Unknown network error occurred";
//         }
//     }
//   }

//   // Helper methods for optimized fallback logic
//   List<String> _getCodeKeys() {
//     try {
//       final responseConfig = AppConfig.instance.responseConfig;
//       return [responseConfig.codeKey, 'code', 'status', 'statusCode'];
//     } catch (_) {
//       return ['code', 'status', 'statusCode'];
//     }
//   }

//   List<String> _getErrorCodeKeys() {
//     try {
//       final responseConfig = AppConfig.instance.responseConfig;
//       return [
//         responseConfig.errorCodeKey,
//         'errorCode',
//         'error_code',
//         'errCode',
//       ];
//     } catch (_) {
//       return ['errorCode', 'error_code', 'errCode'];
//     }
//   }

//   List<String> _getMessageKeys() {
//     try {
//       final responseConfig = AppConfig.instance.responseConfig;
//       return [
//         responseConfig.messageKey,
//         responseConfig.errorMessageKey,
//         'message',
//         'msg',
//         'description',
//         'detail',
//       ];
//     } catch (_) {
//       return ['message', 'msg', 'description', 'detail'];
//     }
//   }

//   String _getDataKey() {
//     try {
//       return AppConfig.instance.responseConfig.dataKey;
//     } catch (_) {
//       return 'data';
//     }
//   }

//   int? _extractIntValue(Map<String, dynamic> jsonMap, List<String> keys) {
//     for (final key in keys) {
//       if (jsonMap.containsKey(key)) {
//         final value = jsonMap[key];
//         if (value is int) return value;
//         if (value is String) return int.tryParse(value);
//       }
//     }
//     return null;
//   }

//   String? _extractStringValue(Map<String, dynamic> jsonMap, List<String> keys) {
//     for (final key in keys) {
//       if (jsonMap.containsKey(key)) {
//         final value = jsonMap[key];
//         if (value is String) return value;
//         return value?.toString();
//       }
//     }
//     return null;
//   }
// }
