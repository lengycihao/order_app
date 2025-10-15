import 'package:lib_domain/cons/api_request.dart';
import 'package:lib_domain/entrity/cart/cart_info_model.dart';
import 'package:lib_domain/entrity/cart/cart_item_model.dart';
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
    
    // 检查是否是210状态码（数据处理中）
    if (result.code == 210) {
      print('⏳ CartAPI 遇到210状态码，数据处理中');
      // 210状态码时返回失败结果，让上层处理异常
      return HttpResultN<CartInfoModel>(
        isSuccess: false,
        code: 210,
        msg: '数据处理中...',
        data: null,
      );
    }
    
    if (result.isSuccess) {
      try {
        final dataJson = result.getDataJson();
        print('🛒 CartAPI dataJson: $dataJson');
        print('🛒 CartAPI dataJson type: ${dataJson.runtimeType}');
        
        // 检查数据是否为空
        if (dataJson.isEmpty) {
          print('⚠️ CartAPI 返回空数据，创建空购物车');
          final emptyCart = CartInfoModel(
            cartId: null,
            tableId: int.tryParse(tableId),
            items: <CartItemModel>[],
            totalQuantity: 0,
            totalPrice: 0.0,
            createdAt: null,
            updatedAt: null,
          );
          return HttpResultN<CartInfoModel>(
            isSuccess: true,
            code: result.code,
            msg: result.msg,
            data: emptyCart,
          );
        }
        
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
      // 重要：210状态码等错误情况，直接返回失败结果，不要转换为空购物车
      print('❌ CartAPI 请求失败: code=${result.code}, msg=${result.msg}');
      return result.convert();
    }
  }
}
