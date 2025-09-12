// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dish_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DishListModel _$DishListModelFromJson(Map<String, dynamic> json) =>
    DishListModel(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DishListModelToJson(DishListModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'items': instance.items,
    };
