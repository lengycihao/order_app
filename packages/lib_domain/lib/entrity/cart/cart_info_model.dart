import 'package:json_annotation/json_annotation.dart';
import 'cart_item_model.dart';

part 'cart_info_model.g.dart';

@JsonSerializable()
class CartInfoModel {
  /// 购物车ID
  @JsonKey(name: 'id')
  String? cartId;
  
  /// 桌台ID
  @JsonKey(name: 'table_id')
  String? tableId;
  
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
  
  /// 备注
  @JsonKey(name: 'remark')
  String? remark;

  CartInfoModel({
    this.cartId,
    this.tableId,
    this.items,
    this.totalQuantity,
    this.totalPrice,
    this.createdAt,
    this.updatedAt,
    this.remark,
  });

  factory CartInfoModel.fromJson(Map<String, dynamic> json) {
    return _$CartInfoModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CartInfoModelToJson(this);
}
