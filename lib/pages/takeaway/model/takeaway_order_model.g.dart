// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'takeaway_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TakeawayOrderListResponse _$TakeawayOrderListResponseFromJson(
  Map<String, dynamic> json,
) => TakeawayOrderListResponse(
  page: (json['page'] as num?)?.toInt(),
  pageSize: (json['page_size'] as num?)?.toInt(),
  isLastPage: json['is_last_page'] as bool?,
  total: (json['total'] as num?)?.toInt(),
  data: (json['data'] as List<dynamic>?)
      ?.map((e) => TakeawayOrderModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TakeawayOrderListResponseToJson(
  TakeawayOrderListResponse instance,
) => <String, dynamic>{
  'page': instance.page,
  'page_size': instance.pageSize,
  'is_last_page': instance.isLastPage,
  'total': instance.total,
  'data': instance.data,
};

TakeawayOrderModel _$TakeawayOrderModelFromJson(Map<String, dynamic> json) =>
    TakeawayOrderModel(
      id: json['id'] as String?,
      orderNo: json['order_no'] as String?,
      orderTime: json['order_time'] as String?,
      orderStatus: (json['order_status'] as num?)?.toInt(),
      orderStatusName: json['order_status_name'] as String?,
      checkoutStatus: (json['checkout_status'] as num?)?.toInt(),
      checkoutStatusName: json['checkout_status_name'] as String?,
      checkoutTime: json['checkout_time'] as String?,
      totalAmount: json['total_amount'] as String?,
      paidAmount: json['paid_amount'] as String?,
      estimatePickupTime: json['estimate_pickup_time'] as String?,
      pickupCode: json['pickup_code'] as String?,
      remark: json['remark'] as String?,
      source: (json['source'] as num?)?.toInt(),
      sourceName: json['source_name'] as String?,
      details: json['details'],
    );

Map<String, dynamic> _$TakeawayOrderModelToJson(TakeawayOrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_no': instance.orderNo,
      'order_time': instance.orderTime,
      'order_status': instance.orderStatus,
      'order_status_name': instance.orderStatusName,
      'checkout_status': instance.checkoutStatus,
      'checkout_status_name': instance.checkoutStatusName,
      'checkout_time': instance.checkoutTime,
      'total_amount': instance.totalAmount,
      'paid_amount': instance.paidAmount,
      'estimate_pickup_time': instance.estimatePickupTime,
      'pickup_code': instance.pickupCode,
      'remark': instance.remark,
      'source': instance.source,
      'source_name': instance.sourceName,
      'details': instance.details,
    };
