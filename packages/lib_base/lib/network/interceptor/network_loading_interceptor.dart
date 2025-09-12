import 'package:dio/dio.dart';
import 'package:lib_base/network/cons/http_header_key.dart';
import 'package:lib_base/utils/loading_manager.dart';

/// 网络Loading拦截器
/// 负责统一管理网络请求的loading显示
class NetworkLoadingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final headers = options.headers;
    final isShowLoadingDialog = _getBoolHeader(
      headers,
      HttpHeaderKey.showLoadingDialog,
    );

    if (isShowLoadingDialog) {
      LoadingManager.instance.showLoading();
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final headers = response.requestOptions.headers;
    final isShowLoadingDialog = _getBoolHeader(
      headers,
      HttpHeaderKey.showLoadingDialog,
    );

    if (isShowLoadingDialog) {
      LoadingManager.instance.hideLoading();
    }

    super.onResponse(response, handler);
  }

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    final headers = err.requestOptions.headers;
    final isShowLoadingDialog = _getBoolHeader(
      headers,
      HttpHeaderKey.showLoadingDialog,
    );

    if (isShowLoadingDialog) {
      LoadingManager.instance.hideLoading();
    }

    super.onError(err, handler);
  }

  bool _getBoolHeader(Map<String, dynamic> headers, String key) {
    return headers[key] != null &&
        headers[key].toString().toLowerCase() == 'true';
  }
}
