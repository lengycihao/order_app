import 'package:json_annotation/json_annotation.dart';
import 'cart_specification_model.dart';

part 'cart_item_model.g.dart';

/// 字符串转double的转换器，处理API返回的字符串数字
class StringToDoubleConverter implements JsonConverter<double?, dynamic> {
  const StringToDoubleConverter();

  @override
  double? fromJson(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  @override
  dynamic toJson(double? value) => value;
}

@JsonSerializable()
class CartItemModel {
  /// 购物车项目ID
  @JsonKey(name: 'id')
  int? cartId;
  
  /// 菜品ID
  @JsonKey(name: 'dish_id')
  int? dishId;
  
  /// 菜品名称
  @JsonKey(name: 'name')
  String? dishName;
  
  /// 菜品价格 (对应服务器的 unit_price)
  @JsonKey(name: 'unit_price')
  @StringToDoubleConverter()
  double? price;
  
  /// 原始价格字段 (服务器返回的 price 字段)
  @JsonKey(name: 'price')
  @StringToDoubleConverter()
  double? originalPrice;
  
  /// 数量
  @JsonKey(name: 'quantity')
  int? quantity;
  
  /// 小计价格 (计算字段，通过 price * quantity)
  double? subtotal;
  
  /// 菜品图片
  @JsonKey(name: 'image')
  String? image;
  
  /// 菜品描述
  String? description;
  
  /// 规格ID
  @JsonKey(name: 'cart_specification_id')
  String? specificationId;
  
  /// 状态
  @JsonKey(name: 'status')
  int? status;
  
  /// 菜单价格
  @JsonKey(name: 'menu_price')
  @StringToDoubleConverter()
  double? menuPrice;
  
  /// 价格增量
  @JsonKey(name: 'price_increment')
  @StringToDoubleConverter()
  double? priceIncrement;
  
  /// 税率
  @JsonKey(name: 'tax_rate')
  @StringToDoubleConverter()
  double? taxRate;
  
  /// 过敏原信息
  @JsonKey(name: 'allergens')
  List<Map<String, dynamic>>? allergens;
  
  /// 选项字符串
  @JsonKey(name: 'options_str')
  String? optionsStr;
  
  /// 选项
  @JsonKey(name: 'options')
  dynamic options;
  
  /// 来源
  @JsonKey(name: 'source')
  int? source;
  
  /// 类型
  @JsonKey(name: 'type')
  int? type;
  
  /// 服务员ID
  @JsonKey(name: 'waiter_id')
  int? waiterId;
  
  /// 客户ID
  @JsonKey(name: 'customer_id')
  int? customerId;
  
  /// 浏览器指纹哈希
  @JsonKey(name: 'browser_fingerprint_hash')
  String? browserFingerprintHash;
  
  /// 规格列表
  List<CartSpecificationModel>? specifications;
  
  /// 是否临时菜品
  bool? isTemp;
  
  /// 临时菜品信息（如果是临时菜品）
  TempDishInfo? tempDishInfo;
  
  /// 创建时间
  String? createdAt;
  
  /// 更新时间
  String? updatedAt;

  CartItemModel({
    this.cartId,
    this.dishId,
    this.dishName,
    this.price,
    this.originalPrice,
    this.quantity,
    this.subtotal,
    this.image,
    this.description,
    this.specificationId,
    this.status,
    this.menuPrice,
    this.priceIncrement,
    this.taxRate,
    this.allergens,
    this.optionsStr,
    this.options,
    this.source,
    this.type,
    this.waiterId,
    this.customerId,
    this.browserFingerprintHash,
    this.specifications,
    this.isTemp,
    this.tempDishInfo,
    this.createdAt,
    this.updatedAt,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return _$CartItemModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CartItemModelToJson(this);
}

/// 临时菜品信息
@JsonSerializable()
class TempDishInfo {
  /// 类目ID
  int? categoryId;
  
  /// 类目名称
  String? categoryName;
  
  /// 出菜档口ID
  int? kitchenStationId;
  
  /// 出菜档口名称
  String? kitchenStationName;

  TempDishInfo({
    this.categoryId,
    this.categoryName,
    this.kitchenStationId,
    this.kitchenStationName,
  });

  factory TempDishInfo.fromJson(Map<String, dynamic> json) {
    return _$TempDishInfoFromJson(json);
  }

  Map<String, dynamic> toJson() => _$TempDishInfoToJson(this);
}
