// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_fixed_cost.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MenuFixedCost _$MenuFixedCostFromJson(Map<String, dynamic> json) =>
    MenuFixedCost(
      id: json['id'] as String?,
      name: json['name'] as String?,
      amount: json['amount'] as String?,
      type: (json['type'] as num?)?.toInt(),
      unit: json['unit'] as String?,
    );

Map<String, dynamic> _$MenuFixedCostToJson(MenuFixedCost instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'amount': instance.amount,
      'type': instance.type,
      'unit': instance.unit,
    };
