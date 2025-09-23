import 'package:lib_domain/cons/api_request.dart';
import 'package:lib_base/lib_base.dart';

class TakeoutApi {
  /// 获取外卖订单列表
  Future<HttpResultN<dynamic>> getTakeoutList({
    required int queryType, // 1已结账 2未结账
    int page = 1,
    int pageSize = 20,
    String? pickupCode,
  }) async {
    final params = <String, dynamic>{
      'query_type': queryType,
      'page': page,
      'page_size': pageSize,
    };
    
    if (pickupCode != null && pickupCode.isNotEmpty) {
      params['pickup_code'] = pickupCode;
    }
    
    logDebug('🚀 外卖API请求参数: $params', tag: 'TakeoutApi');
    
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.takeoutList,
      queryParam: params,
    );
    
    logDebug('📡 外卖API原始响应: ${result.dataJson}', tag: 'TakeoutApi');
    
    // 直接返回原始结果，让控制器处理数据解析
    return result;
  }

  /// 获取外卖订单详情
  Future<HttpResultN<dynamic>> getTakeoutDetail({
    required int id,
  }) async {
    final params = <String, dynamic>{
      'id': id,
    };
    
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.takeoutDetail,
      queryParam: params,
    );
    
    // 直接返回原始结果，让控制器处理数据解析
    return result;
  }
}
