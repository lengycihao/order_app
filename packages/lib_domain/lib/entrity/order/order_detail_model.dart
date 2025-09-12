import 'package:json_annotation/json_annotation.dart';
import 'ordered_dish_model.dart';

part 'order_detail_model.g.dart';

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
class OrderDetailModel {
  /// 下单次数
  @JsonKey(name: 'times')
  int? times;

  /// 下单次数字符串
  @JsonKey(name: 'times_str')
  String? timesStr;

  /// 轮次字符串
  @JsonKey(name: 'round_str')
  String? roundStr;

  /// 数量字符串
  @JsonKey(name: 'quantity_str')
  String? quantityStr;

  /// 总金额
  @JsonKey(name: 'total_amount')
  @StringToDoubleConverter()
  double? totalAmount;

  /// 支付状态
  @JsonKey(name: 'payment_status')
  int? paymentStatus;

  /// 支付ID
  @JsonKey(name: 'payment_id')
  int? paymentId;

  /// 菜品列表
  @JsonKey(name: 'dishes')
  List<OrderedDishModel>? dishes;

  OrderDetailModel({
    this.times,
    this.timesStr,
    this.roundStr,
    this.quantityStr,
    this.totalAmount,
    this.paymentStatus,
    this.paymentId,
    this.dishes,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return _$OrderDetailModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$OrderDetailModelToJson(this);
}
