import 'package:lib_domain/cons/api_request.dart';
import 'package:lib_domain/entrity/cart/cart_info_model.dart';
import 'package:lib_base/lib_base.dart';

class CartApi {
  /// 获取购物车信息
  Future<HttpResultN<CartInfoModel>> getCartInfo({
    required String tableId,
  }) async {
    final params = {
      'table_id': tableId,
    };
    
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.cartInfo,
      queryParam: params,
    );
    
    if (result.isSuccess) {
      try {
        final dataJson = result.getDataJson();
        print('🛒 CartAPI dataJson: $dataJson');
        print('🛒 CartAPI dataJson type: ${dataJson.runtimeType}');
        
        final cartModel = CartInfoModel.fromJson(dataJson);
        print('🛒 CartAPI converted model: $cartModel');
        print('🛒 CartAPI model items: ${cartModel.items}');
        
        return result.convert(data: cartModel);
      } catch (e, stackTrace) {
        print('❌ CartAPI conversion error: $e');
        print('❌ StackTrace: $stackTrace');
        return result.convert(); // 返回没有data的结果
      }
    } else {
      return result.convert();
    }
  }
}
