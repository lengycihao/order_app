// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrentOrderModel _$CurrentOrderModelFromJson(
  Map<String, dynamic> json,
) => CurrentOrderModel(
  orderId: json['id'] as String?,
  orderIds: (json['order_ids'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  orderType: (json['order_type'] as num?)?.toInt(),
  totalAmount: const StringToDoubleConverter().fromJson(json['total_amount']),
  settledAmount: const StringToDoubleConverter().fromJson(
    json['settled_amount'],
  ),
  paidAmount: const StringToDoubleConverter().fromJson(json['paid_amount']),
  discountAmount: const StringToDoubleConverter().fromJson(
    json['discount_amount'],
  ),
  roundAmount: const StringToDoubleConverter().fromJson(json['round_amount']),
  paymentStatus: (json['payment_status'] as num?)?.toInt(),
  quantity: (json['quantity'] as num?)?.toInt(),
  details: (json['details'] as List<dynamic>?)
      ?.map((e) => OrderDetailModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  payments: (json['payments'] as List<dynamic>?)
      ?.map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CurrentOrderModelToJson(
  CurrentOrderModel instance,
) => <String, dynamic>{
  'id': instance.orderId,
  'order_ids': instance.orderIds,
  'order_type': instance.orderType,
  'total_amount': const StringToDoubleConverter().toJson(instance.totalAmount),
  'settled_amount': const StringToDoubleConverter().toJson(
    instance.settledAmount,
  ),
  'paid_amount': const StringToDoubleConverter().toJson(instance.paidAmount),
  'discount_amount': const StringToDoubleConverter().toJson(
    instance.discountAmount,
  ),
  'round_amount': const StringToDoubleConverter().toJson(instance.roundAmount),
  'payment_status': instance.paymentStatus,
  'quantity': instance.quantity,
  'details': instance.details,
  'payments': instance.payments,
};
