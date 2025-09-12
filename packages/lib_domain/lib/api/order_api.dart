import 'package:lib_domain/cons/api_request.dart';
import 'package:lib_domain/entrity/order/current_order_model.dart';
import 'package:lib_base/lib_base.dart';

class OrderApi {
  /// 提交订单
  Future<HttpResultN<Map<String, dynamic>>> submitOrder({
    required int tableId,
  }) async {
    final params = {
      'table_id': tableId,
    };
    
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.submitOrder,
      jsonParam: params,
    );
    
    return result.convert();
  }

  /// 获取当前订单信息
  Future<HttpResultN<CurrentOrderModel>> getCurrentOrder({
    required String tableId,
  }) async {
    final params = {
      'table_id': tableId,
    };
    
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.currentOrder,
      queryParam: params,
    );
    
    // 处理特殊状态码：210表示数据可能还在处理中
    if (result.code == 210) {
      print('⚠️ 收到状态码210，数据可能还在处理中');
      return HttpResultN<CurrentOrderModel>(
        isSuccess: false,
        code: 210,
        msg: '数据处理中，请稍后重试',
        data: null,
      );
    }
    
    if (result.isSuccess) {
      try {
        final dataJson = result.getDataJson();
        print('📋 OrderAPI dataJson: $dataJson');
        
        // 检查dataJson是否为空
        if (dataJson.isEmpty) {
          print('❌ OrderAPI dataJson为空');
          return HttpResultN<CurrentOrderModel>(
            isSuccess: false,
            code: result.code,
            msg: '响应数据为空',
            data: null,
          );
        }
        
        final orderModel = CurrentOrderModel.fromJson(dataJson);
        print('📋 OrderAPI converted model: $orderModel');
        
        return result.convert(data: orderModel);
      } catch (e, stackTrace) {
        print('❌ OrderAPI conversion error: $e');
        print('❌ StackTrace: $stackTrace');
        return HttpResultN<CurrentOrderModel>(
          isSuccess: false,
          code: result.code,
          msg: '数据解析失败: $e',
          data: null,
        );
      }
    } else {
      return result.convert();
    }
  }
}
