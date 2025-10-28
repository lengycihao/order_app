// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_info_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartInfoModel _$CartInfoModelFromJson(Map<String, dynamic> json) =>
    CartInfoModel(
      cartId: json['id'] as String?,
      tableId: json['table_id'] as String?,
      items: (json['dishes'] as List<dynamic>?)
          ?.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalQuantity: (json['quantity'] as num?)?.toInt(),
      totalPrice: const StringToDoubleConverter().fromJson(json['total_price']),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      remark: json['remark'] as String?,
    );

Map<String, dynamic> _$CartInfoModelToJson(
  CartInfoModel instance,
) => <String, dynamic>{
  'id': instance.cartId,
  'table_id': instance.tableId,
  'dishes': instance.items,
  'quantity': instance.totalQuantity,
  'total_price': const StringToDoubleConverter().toJson(instance.totalPrice),
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'remark': instance.remark,
};
