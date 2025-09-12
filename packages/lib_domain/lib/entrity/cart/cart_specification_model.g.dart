// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_specification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartSpecificationModel _$CartSpecificationModelFromJson(
  Map<String, dynamic> json,
) => CartSpecificationModel(
  specificationId: (json['specificationId'] as num?)?.toInt(),
  specificationName: json['specificationName'] as String?,
  optionId: (json['optionId'] as num?)?.toInt(),
  optionName: json['optionName'] as String?,
  optionPrice: (json['optionPrice'] as num?)?.toDouble(),
  customValue: json['customValue'] as String?,
);

Map<String, dynamic> _$CartSpecificationModelToJson(
  CartSpecificationModel instance,
) => <String, dynamic>{
  'specificationId': instance.specificationId,
  'specificationName': instance.specificationName,
  'optionId': instance.optionId,
  'optionName': instance.optionName,
  'optionPrice': instance.optionPrice,
  'customValue': instance.customValue,
};
