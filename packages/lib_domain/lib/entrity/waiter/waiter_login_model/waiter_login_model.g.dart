// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waiter_login_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WaiterLoginModel _$WaiterLoginModelFromJson(Map<String, dynamic> json) =>
    WaiterLoginModel(
      token: json['token'] as String?,
      waiterId: json['waiter_id'] as String?,
      waiterName: json['waiter_name'] as String?,
      languageCode: json['language_code'] as String?,
      merchantId: json['merchant_id'] as String?,
      storeId: json['store_id'] as String?,
      avatar: json['avatar'] as String?,
    );

Map<String, dynamic> _$WaiterLoginModelToJson(WaiterLoginModel instance) =>
    <String, dynamic>{
      'token': instance.token,
      'waiter_id': instance.waiterId,
      'waiter_name': instance.waiterName,
      'language_code': instance.languageCode,
      'merchant_id': instance.merchantId,
      'store_id': instance.storeId,
      'avatar': instance.avatar,
    };
