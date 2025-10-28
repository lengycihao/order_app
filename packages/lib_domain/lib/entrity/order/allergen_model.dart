import 'package:json_annotation/json_annotation.dart';

part 'allergen_model.g.dart';

@JsonSerializable()
class AllergenModel {
  /// 过敏原标签
  @JsonKey(name: 'label')
  String? label;

  /// 过敏原ID
  @JsonKey(name: 'id')
  String? id;

  /// 过敏原图标
  @JsonKey(name: 'icon')
  String? icon;

  AllergenModel({
    this.label,
    this.id,
    this.icon,
  });

  factory AllergenModel.fromJson(Map<String, dynamic> json) {
    return _$AllergenModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$AllergenModelToJson(this);
}
