// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'option_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OptionItem _$OptionItemFromJson(Map<String, dynamic> json) => OptionItem(
  id: (json['id'] as num?)?.toInt(),
  label: json['label'] as String?,
  value: (json['value'] as num?)?.toInt(),
  price: json['price'] as String?,
);

Map<String, dynamic> _$OptionItemToJson(OptionItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'value': instance.value,
      'price': instance.price,
    };
