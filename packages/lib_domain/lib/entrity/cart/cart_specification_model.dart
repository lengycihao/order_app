import 'package:json_annotation/json_annotation.dart';

part 'cart_specification_model.g.dart';

@JsonSerializable()
class CartSpecificationModel {
  /// 规格ID
  int? specificationId;
  
  /// 规格名称
  String? specificationName;
  
  /// 规格选项ID
  int? optionId;
  
  /// 规格选项名称
  String? optionName;
  
  /// 规格选项价格
  double? optionPrice;
  
  /// 自定义值（如果有）
  String? customValue;

  CartSpecificationModel({
    this.specificationId,
    this.specificationName,
    this.optionId,
    this.optionName,
    this.optionPrice,
    this.customValue,
  });

  factory CartSpecificationModel.fromJson(Map<String, dynamic> json) {
    return _$CartSpecificationModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CartSpecificationModelToJson(this);
}
