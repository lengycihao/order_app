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
    
    // 处理状态码210（数据处理中）的特殊情况
    if (result.code == 210) {
      print('⚠️ CartAPI 返回状态码210，数据处理中，返回null保留本地数据');
      return HttpResultN<CartInfoModel>(
        isSuccess: false,
        code: 210,
        msg: '数据处理中',
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
      return result.convert();
    }
  }
}
