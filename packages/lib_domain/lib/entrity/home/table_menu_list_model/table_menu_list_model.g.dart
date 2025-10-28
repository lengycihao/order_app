// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_menu_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TableMenuListModel _$TableMenuListModelFromJson(Map<String, dynamic> json) =>
    TableMenuListModel(
      menuId: json['menu_id'] as String?,
      menuName: json['menu_name'] as String?,
      menuType: (json['menu_type'] as num?)?.toInt(),
      menuImage: json['menu_image'] as String?,
      adultPackagePrice: json['adult_package_price'] as String?,
      childPackagePrice: json['child_package_price'] as String?,
      weekRange: json['week_range'] as String?,
      menuFixedCosts: (json['menu_fixed_costs'] as List<dynamic>?)
          ?.map((e) => MenuFixedCost.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TableMenuListModelToJson(TableMenuListModel instance) =>
    <String, dynamic>{
      'menu_id': instance.menuId,
      'menu_name': instance.menuName,
      'menu_type': instance.menuType,
      'menu_image': instance.menuImage,
      'adult_package_price': instance.adultPackagePrice,
      'child_package_price': instance.childPackagePrice,
      'week_range': instance.weekRange,
      'menu_fixed_costs': instance.menuFixedCosts,
    };
