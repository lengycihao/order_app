// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartItemModel _$CartItemModelFromJson(Map<String, dynamic> json) =>
    CartItemModel(
      cartId: (json['id'] as num?)?.toInt(),
      dishId: (json['dish_id'] as num?)?.toInt(),
      dishName: json['name'] as String?,
      price: const StringToDoubleConverter().fromJson(json['unit_price']),
      originalPrice: const StringToDoubleConverter().fromJson(json['price']),
      quantity: (json['quantity'] as num?)?.toInt(),
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      image: json['image'] as String?,
      description: json['description'] as String?,
      specificationId: json['cart_specification_id'] as String?,
      status: (json['status'] as num?)?.toInt(),
      menuPrice: const StringToDoubleConverter().fromJson(json['menu_price']),
      priceIncrement: const StringToDoubleConverter().fromJson(
        json['price_increment'],
      ),
      taxRate: const StringToDoubleConverter().fromJson(json['tax_rate']),
      allergens: (json['allergens'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      optionsStr: json['options_str'] as String?,
      options: json['options'],
      source: (json['source'] as num?)?.toInt(),
      type: (json['type'] as num?)?.toInt(),
      dishType: (json['dish_type'] as num?)?.toInt(),
      waiterId: (json['waiter_id'] as num?)?.toInt(),
      customerId: (json['customer_id'] as num?)?.toInt(),
      browserFingerprintHash: json['browser_fingerprint_hash'] as String?,
      specifications: (json['specifications'] as List<dynamic>?)
          ?.map(
            (e) => CartSpecificationModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      isTemp: json['isTemp'] as bool?,
      tempDishInfo: json['tempDishInfo'] == null
          ? null
          : TempDishInfo.fromJson(json['tempDishInfo'] as Map<String, dynamic>),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$CartItemModelToJson(CartItemModel instance) =>
    <String, dynamic>{
      'id': instance.cartId,
      'dish_id': instance.dishId,
      'name': instance.dishName,
      'unit_price': const StringToDoubleConverter().toJson(instance.price),
      'price': const StringToDoubleConverter().toJson(instance.originalPrice),
      'quantity': instance.quantity,
      'subtotal': instance.subtotal,
      'image': instance.image,
      'description': instance.description,
      'cart_specification_id': instance.specificationId,
      'status': instance.status,
      'menu_price': const StringToDoubleConverter().toJson(instance.menuPrice),
      'price_increment': const StringToDoubleConverter().toJson(
        instance.priceIncrement,
      ),
      'tax_rate': const StringToDoubleConverter().toJson(instance.taxRate),
      'allergens': instance.allergens,
      'options_str': instance.optionsStr,
      'options': instance.options,
      'source': instance.source,
      'type': instance.type,
      'dish_type': instance.dishType,
      'waiter_id': instance.waiterId,
      'customer_id': instance.customerId,
      'browser_fingerprint_hash': instance.browserFingerprintHash,
      'specifications': instance.specifications,
      'isTemp': instance.isTemp,
      'tempDishInfo': instance.tempDishInfo,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

TempDishInfo _$TempDishInfoFromJson(Map<String, dynamic> json) => TempDishInfo(
  categoryId: (json['categoryId'] as num?)?.toInt(),
  categoryName: json['categoryName'] as String?,
  kitchenStationId: (json['kitchenStationId'] as num?)?.toInt(),
  kitchenStationName: json['kitchenStationName'] as String?,
);

Map<String, dynamic> _$TempDishInfoToJson(TempDishInfo instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'kitchenStationId': instance.kitchenStationId,
      'kitchenStationName': instance.kitchenStationName,
    };
