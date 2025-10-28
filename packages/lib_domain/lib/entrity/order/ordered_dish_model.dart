import 'package:json_annotation/json_annotation.dart';
import 'allergen_model.dart';

part 'ordered_dish_model.g.dart';

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
class OrderedDishModel {
  /// 订单菜品ID
  @JsonKey(name: 'id')
  String? id;

  /// 菜品ID
  @JsonKey(name: 'dish_id')
  String? dishId;

  /// 菜品名称
  @JsonKey(name: 'name')
  String? name;

  /// 菜品类型
  @JsonKey(name: 'dish_type')
  int? dishType;

  /// 数量
  @JsonKey(name: 'quantity')
  int? quantity;

  /// 价格
  @JsonKey(name: 'price')
  @StringToDoubleConverter()
  double? price;

  /// 菜单价格
  @JsonKey(name: 'menu_price')
  @StringToDoubleConverter()
  double? menuPrice;

  /// 价格增量
  @JsonKey(name: 'price_increment')
  @StringToDoubleConverter()
  double? priceIncrement;

  /// 单价
  @JsonKey(name: 'unit_price')
  @StringToDoubleConverter()
  double? unitPrice;

  /// 税率
  @JsonKey(name: 'tax_rate')
  @StringToDoubleConverter()
  double? taxRate;

  /// 菜品图片
  @JsonKey(name: 'image')
  String? image;

  /// 过敏原信息
  @JsonKey(name: 'allergens')
  List<AllergenModel>? allergens;

  /// 选项字符串
  @JsonKey(name: 'options_str')
  String? optionsStr;

  /// 轮次字符串
  @JsonKey(name: 'round_str')
  String? roundStr;

  /// 数量字符串
  @JsonKey(name: 'quantity_str')
  String? quantityStr;

  /// 烹饪状态
  @JsonKey(name: 'cooking_status')
  int? cookingStatus;

  /// 烹饪状态名称
  @JsonKey(name: 'cooking_status_name')
  String? cookingStatusName;

  /// 处理状态
  @JsonKey(name: 'process_status')
  int? processStatus;

  /// 处理状态名称
  @JsonKey(name: 'process_status_name')
  String? processStatusName;

  /// 烹饪超时时间
  @JsonKey(name: 'cooking_timeout')
  String? cookingTimeout;

  OrderedDishModel({
    this.id,
    this.dishId,
    this.name,
    this.dishType,
    this.quantity,
    this.price,
    this.menuPrice,
    this.priceIncrement,
    this.unitPrice,
    this.taxRate,
    this.image,
    this.allergens,
    this.optionsStr,
    this.roundStr,
    this.quantityStr,
    this.cookingStatus,
    this.cookingStatusName,
    this.processStatus,
    this.processStatusName,
    this.cookingTimeout,
  });

  factory OrderedDishModel.fromJson(Map<String, dynamic> json) {
    return _$OrderedDishModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$OrderedDishModelToJson(this);
}
