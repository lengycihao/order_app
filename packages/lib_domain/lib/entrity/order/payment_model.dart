import 'package:json_annotation/json_annotation.dart';

part 'payment_model.g.dart';

@JsonSerializable()
class PaymentModel {
  /// 支付ID
  @JsonKey(name: 'id')
  int? id;

  /// 支付方式
  @JsonKey(name: 'payment_method')
  String? paymentMethod;

  /// 支付金额
  @JsonKey(name: 'amount')
  double? amount;

  /// 支付状态
  @JsonKey(name: 'status')
  int? status;

  /// 支付时间
  @JsonKey(name: 'created_at')
  String? createdAt;

  PaymentModel({
    this.id,
    this.paymentMethod,
    this.amount,
    this.status,
    this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return _$PaymentModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$PaymentModelToJson(this);
}
