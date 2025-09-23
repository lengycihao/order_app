// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderDetailModel _$OrderDetailModelFromJson(Map<String, dynamic> json) =>
    OrderDetailModel(
      times: (json['times'] as num?)?.toInt(),
      timesStr: json['times_str'] as String?,
      roundStr: json['round_str'] as String?,
      quantityStr: json['quantity_str'] as String?,
      totalAmount: const StringToDoubleConverter().fromJson(
        json['total_amount'],
      ),
      paymentStatus: (json['payment_status'] as num?)?.toInt(),
      paymentId: (json['payment_id'] as num?)?.toInt(),
      dishes: (json['dishes'] as List<dynamic>?)
          ?.map((e) => OrderedDishModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OrderDetailModelToJson(
  OrderDetailModel instance,
) => <String, dynamic>{
  'times': instance.times,
  'times_str': instance.timesStr,
  'round_str': instance.roundStr,
  'quantity_str': instance.quantityStr,
  'total_amount': const StringToDoubleConverter().toJson(instance.totalAmount),
  'payment_status': instance.paymentStatus,
  'payment_id': instance.paymentId,
  'dishes': instance.dishes,
};
