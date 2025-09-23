// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrentOrderModel _$CurrentOrderModelFromJson(Map<String, dynamic> json) =>
    CurrentOrderModel(
      orderId: (json['id'] as num?)?.toInt(),
      orderType: (json['order_type'] as num?)?.toInt(),
      totalAmount: const StringToDoubleConverter().fromJson(
        json['total_amount'],
      ),
      settledAmount: const StringToDoubleConverter().fromJson(
        json['settled_amount'],
      ),
      paidAmount: const StringToDoubleConverter().fromJson(json['paid_amount']),
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
  'order_type': instance.orderType,
  'total_amount': const StringToDoubleConverter().toJson(instance.totalAmount),
  'settled_amount': const StringToDoubleConverter().toJson(
    instance.settledAmount,
  ),
  'paid_amount': const StringToDoubleConverter().toJson(instance.paidAmount),
  'quantity': instance.quantity,
  'details': instance.details,
  'payments': instance.payments,
};
