// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Item _$ItemFromJson(Map<String, dynamic> json) => Item(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  categoryId: (json['category_id'] as num?)?.toInt(),
  description: json['description'] as String?,
  price: json['price'] as String?,
  unitPrice: json['unit_price'] as String?,
  image: json['image'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  type: (json['type'] as num?)?.toInt(),
  options: (json['options'] as List<dynamic>?)
      ?.map((e) => Option.fromJson(e as Map<String, dynamic>))
      .toList(),
  hasOptions: json['has_options'] as bool?,
  allergens: (json['allergens'] as List<dynamic>?)
      ?.map((e) => Allergen.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'category_id': instance.categoryId,
  'description': instance.description,
  'price': instance.price,
  'unit_price': instance.unitPrice,
  'image': instance.image,
  'tags': instance.tags,
  'type': instance.type,
  'options': instance.options,
  'has_options': instance.hasOptions,
  'allergens': instance.allergens,
};
