import 'package:json_annotation/json_annotation.dart';
import 'cart_item_model.dart';
import 'package:lib_base/lib_base.dart';

part 'cart_info_model.g.dart';

@JsonSerializable()
class CartInfoModel {
  /// 购物车ID
  @JsonKey(name: 'id')
  int? cartId;
  
  /// 桌台ID
  @JsonKey(name: 'table_id')
  int? tableId;
  
  /// 购物车项目列表
  @JsonKey(name: 'dishes')
  List<CartItemModel>? items;
  
  /// 总数量
  @JsonKey(name: 'quantity')
  int? totalQuantity;
  
  /// 总价格
  @JsonKey(name: 'total_price')
  @StringToDoubleConverter()
  double? totalPrice;
  
  /// 创建时间
  String? createdAt;
  
  /// 更新时间
  String? updatedAt;

  CartInfoModel({
    this.cartId,
    this.tableId,
    this.items,
    this.totalQuantity,
    this.totalPrice,
    this.createdAt,
    this.updatedAt,
  });

  factory CartInfoModel.fromJson(Map<String, dynamic> json) {
    return _$CartInfoModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CartInfoModelToJson(this);
}
