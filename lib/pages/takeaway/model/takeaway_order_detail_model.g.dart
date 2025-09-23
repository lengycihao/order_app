// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'takeaway_order_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TakeawayOrderDetailResponse _$TakeawayOrderDetailResponseFromJson(
  Map<String, dynamic> json,
) => TakeawayOrderDetailResponse(
  id: (json['id'] as num?)?.toInt(),
  orderNo: json['order_no'] as String?,
  orderTime: json['order_time'] as String?,
  orderStatus: (json['order_status'] as num?)?.toInt(),
  orderStatusName: json['order_status_name'] as String?,
  checkoutStatus: (json['checkout_status'] as num?)?.toInt(),
  checkoutStatusName: json['checkout_status_name'] as String?,
  checkoutTime: json['checkout_time'] as String?,
  totalAmount: json['total_amount'] as String?,
  paidAmount: json['paid_amount'] as String?,
  estimatePickupTime: json['estimate_pickup_time'] as String?,
  pickupCode: json['pickup_code'] as String?,
  remark: json['remark'] as String?,
  source: (json['source'] as num?)?.toInt(),
  sourceName: json['source_name'] as String?,
  details: (json['details'] as List<dynamic>?)
      ?.map((e) => TakeawayOrderDetailItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TakeawayOrderDetailResponseToJson(
  TakeawayOrderDetailResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'order_no': instance.orderNo,
  'order_time': instance.orderTime,
  'order_status': instance.orderStatus,
  'order_status_name': instance.orderStatusName,
  'checkout_status': instance.checkoutStatus,
  'checkout_status_name': instance.checkoutStatusName,
  'checkout_time': instance.checkoutTime,
  'total_amount': instance.totalAmount,
  'paid_amount': instance.paidAmount,
  'estimate_pickup_time': instance.estimatePickupTime,
  'pickup_code': instance.pickupCode,
  'remark': instance.remark,
  'source': instance.source,
  'source_name': instance.sourceName,
  'details': instance.details,
};

TakeawayOrderDetailItem _$TakeawayOrderDetailItemFromJson(
  Map<String, dynamic> json,
) => TakeawayOrderDetailItem(
  id: (json['id'] as num?)?.toInt(),
  dishId: (json['dish_id'] as num?)?.toInt(),
  name: json['name'] as String?,
  quantity: (json['quantity'] as num?)?.toInt(),
  price: json['price'] as String?,
  menuPrice: json['menu_price'] as String?,
  priceIncrement: json['price_increment'] as String?,
  unitPrice: json['unit_price'] as String?,
  taxRate: json['tax_rate'] as String?,
  image: json['image'] as String?,
  allergens: (json['allergens'] as List<dynamic>?)
      ?.map((e) => AllergenInfo.fromJson(e as Map<String, dynamic>))
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

Map<String, dynamic> _$TakeawayOrderDetailItemToJson(
  TakeawayOrderDetailItem instance,
) => <String, dynamic>{
  'id': instance.id,
  'dish_id': instance.dishId,
  'name': instance.name,
  'quantity': instance.quantity,
  'price': instance.price,
  'menu_price': instance.menuPrice,
  'price_increment': instance.priceIncrement,
  'unit_price': instance.unitPrice,
  'tax_rate': instance.taxRate,
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

AllergenInfo _$AllergenInfoFromJson(Map<String, dynamic> json) => AllergenInfo(
  label: json['label'] as String?,
  id: (json['id'] as num?)?.toInt(),
  icon: json['icon'] as String?,
);

Map<String, dynamic> _$AllergenInfoToJson(AllergenInfo instance) =>
    <String, dynamic>{
      'label': instance.label,
      'id': instance.id,
      'icon': instance.icon,
    };
