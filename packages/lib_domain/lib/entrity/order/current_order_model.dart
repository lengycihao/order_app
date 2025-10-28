import 'package:json_annotation/json_annotation.dart';
import 'order_detail_model.dart';
import 'payment_model.dart';

part 'current_order_model.g.dart';

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
class CurrentOrderModel {
  /// 订单ID
  @JsonKey(name: 'id')
  String? orderId;

  /// 订单ID列表
  @JsonKey(name: 'order_ids')
  List<String>? orderIds;

  /// 订单类型
  @JsonKey(name: 'order_type')
  int? orderType;

  /// 总金额
  @JsonKey(name: 'total_amount')
  @StringToDoubleConverter()
  double? totalAmount;

  /// 已结算金额
  @JsonKey(name: 'settled_amount')
  @StringToDoubleConverter()
  double? settledAmount;

  /// 已支付金额
  @JsonKey(name: 'paid_amount')
  @StringToDoubleConverter()
  double? paidAmount;

  /// 折扣金额
  @JsonKey(name: 'discount_amount')
  @StringToDoubleConverter()
  double? discountAmount;

  /// 舍入金额
  @JsonKey(name: 'round_amount')
  @StringToDoubleConverter()
  double? roundAmount;

  /// 支付状态
  @JsonKey(name: 'payment_status')
  int? paymentStatus;

  /// 总数量
  @JsonKey(name: 'quantity')
  int? quantity;

  /// 订单详情列表
  @JsonKey(name: 'details')
  List<OrderDetailModel>? details;

  /// 支付信息列表
  @JsonKey(name: 'payments')
  List<PaymentModel>? payments;

  CurrentOrderModel({
    this.orderId,
    this.orderIds,
    this.orderType,
    this.totalAmount,
    this.settledAmount,
    this.paidAmount,
    this.discountAmount,
    this.roundAmount,
    this.paymentStatus,
    this.quantity,
    this.details,
    this.payments,
  });

  factory CurrentOrderModel.fromJson(Map<String, dynamic> json) {
    return _$CurrentOrderModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CurrentOrderModelToJson(this);
}
