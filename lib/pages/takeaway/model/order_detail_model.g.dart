// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderDetailResponse _$OrderDetailResponseFromJson(Map<String, dynamic> json) =>
    OrderDetailResponse(
      orderInfo: json['order_info'] == null
          ? null
          : OrderInfoModel.fromJson(json['order_info'] as Map<String, dynamic>),
      productInfo: (json['product_info'] as List<dynamic>?)
          ?.map((e) => ProductInfoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OrderDetailResponseToJson(
  OrderDetailResponse instance,
) => <String, dynamic>{
  'order_info': instance.orderInfo,
  'product_info': instance.productInfo,
};

OrderInfoModel _$OrderInfoModelFromJson(Map<String, dynamic> json) =>
    OrderInfoModel(
      pickupCode: json['pickup_code'] as String?,
      pickupTime: json['pickup_time'] as String?,
      remark: json['remark'] as String?,
      orderNo: json['order_no'] as String?,
      source: json['source'] as String?,
      orderTime: json['order_time'] as String?,
      checkoutStatus: (json['checkout_status'] as num?)?.toInt(),
      checkoutStatusName: json['checkout_status_name'] as String?,
    );

Map<String, dynamic> _$OrderInfoModelToJson(OrderInfoModel instance) =>
    <String, dynamic>{
      'pickup_code': instance.pickupCode,
      'pickup_time': instance.pickupTime,
      'remark': instance.remark,
      'order_no': instance.orderNo,
      'source': instance.source,
      'order_time': instance.orderTime,
      'checkout_status': instance.checkoutStatus,
      'checkout_status_name': instance.checkoutStatusName,
    };

ProductInfoModel _$ProductInfoModelFromJson(Map<String, dynamic> json) =>
    ProductInfoModel(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      price: json['price'] as String?,
      image: json['image'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      remark: json['remark'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      totalPrice: json['total_price'] as String?,
    );

Map<String, dynamic> _$ProductInfoModelToJson(ProductInfoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price': instance.price,
      'image': instance.image,
      'quantity': instance.quantity,
      'remark': instance.remark,
      'tags': instance.tags,
      'total_price': instance.totalPrice,
    };
