// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ordered_dish_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderedDishModel _$OrderedDishModelFromJson(Map<String, dynamic> json) =>
    OrderedDishModel(
      id: json['id'] as String?,
      dishId: json['dish_id'] as String?,
      name: json['name'] as String?,
      dishType: (json['dish_type'] as num?)?.toInt(),
      quantity: (json['quantity'] as num?)?.toInt(),
      price: const StringToDoubleConverter().fromJson(json['price']),
      menuPrice: const StringToDoubleConverter().fromJson(json['menu_price']),
      priceIncrement: const StringToDoubleConverter().fromJson(
        json['price_increment'],
      ),
      unitPrice: const StringToDoubleConverter().fromJson(json['unit_price']),
      taxRate: const StringToDoubleConverter().fromJson(json['tax_rate']),
      image: json['image'] as String?,
      allergens: (json['allergens'] as List<dynamic>?)
          ?.map((e) => AllergenModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      optionsStr: json['options_str'] as String?,
      roundStr: json['round_str'] as String?,
      quantityStr: json['quantity_str'] as String?,
      cookingStatus: (json['cooking_status'] as num?)?.toInt(),
      cookingStatusName: json['cooking_status_name'] as String?,
      processStatus: (json['process_status'] as num?)?.toInt(),
      processStatusName: json['process_status_name'] as String?,
      cookingTimeout: json['cooking_timeout'] as String?,
    );

Map<String, dynamic> _$OrderedDishModelToJson(OrderedDishModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'dish_id': instance.dishId,
      'name': instance.name,
      'dish_type': instance.dishType,
      'quantity': instance.quantity,
      'price': const StringToDoubleConverter().toJson(instance.price),
      'menu_price': const StringToDoubleConverter().toJson(instance.menuPrice),
      'price_increment': const StringToDoubleConverter().toJson(
        instance.priceIncrement,
      ),
      'unit_price': const StringToDoubleConverter().toJson(instance.unitPrice),
      'tax_rate': const StringToDoubleConverter().toJson(instance.taxRate),
      'image': instance.image,
      'allergens': instance.allergens,
      'options_str': instance.optionsStr,
      'round_str': instance.roundStr,
      'quantity_str': instance.quantityStr,
      'cooking_status': instance.cookingStatus,
      'cooking_status_name': instance.cookingStatusName,
      'process_status': instance.processStatus,
      'process_status_name': instance.processStatusName,
      'cooking_timeout': instance.cookingTimeout,
    };
