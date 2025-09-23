import 'package:lib_domain/cons/api_request.dart';
import 'package:lib_base/lib_base.dart';

class TakeoutApi {
  /// 获取外卖订单列表
  Future<HttpResultN<Map<String, dynamic>>> getTakeoutList({
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
    
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.takeoutList,
      queryParam: params,
    );
    
    return result.convert();
  }

  /// 获取外卖订单详情
  Future<HttpResultN<Map<String, dynamic>>> getTakeoutDetail({
    required int id,
  }) async {
    final params = <String, dynamic>{
      'id': id,
    };
    
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.takeoutDetail,
      queryParam: params,
    );
    
    return result.convert();
  }
}
