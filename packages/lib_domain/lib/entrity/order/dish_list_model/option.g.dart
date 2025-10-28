// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'option.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Option _$OptionFromJson(Map<String, dynamic> json) => Option(
  id: json['id'] as String?,
  name: json['name'] as String?,
  isMultiple: json['is_multiple'] as bool?,
  isRequired: json['is_required'] as bool?,
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => OptionItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OptionToJson(Option instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'is_multiple': instance.isMultiple,
  'is_required': instance.isRequired,
  'items': instance.items,
};
