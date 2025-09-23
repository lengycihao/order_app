// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allergen_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllergenModel _$AllergenModelFromJson(Map<String, dynamic> json) =>
    AllergenModel(
      label: json['label'] as String?,
      id: (json['id'] as num?)?.toInt(),
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$AllergenModelToJson(AllergenModel instance) =>
    <String, dynamic>{
      'label': instance.label,
      'id': instance.id,
      'icon': instance.icon,
    };
