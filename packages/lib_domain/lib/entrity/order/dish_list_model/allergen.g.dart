// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allergen.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Allergen _$AllergenFromJson(Map<String, dynamic> json) => Allergen(
  label: json['label'] as String?,
  id: (json['id'] as num?)?.toInt(),
  icon: json['icon'] as String?,
);

Map<String, dynamic> _$AllergenToJson(Allergen instance) => <String, dynamic>{
  'label': instance.label,
  'id': instance.id,
  'icon': instance.icon,
};
