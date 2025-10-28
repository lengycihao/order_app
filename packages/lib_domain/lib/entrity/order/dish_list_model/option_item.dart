import 'package:json_annotation/json_annotation.dart';

part 'option_item.g.dart';

@JsonSerializable()
class OptionItem {
  String? id;
  String? label;
  String? value;
  String? price;

  OptionItem({
    this.id,
    this.label,
    this.value,
    this.price,
  });

  factory OptionItem.fromJson(Map<String, dynamic> json) => _$OptionItemFromJson(json);

  Map<String, dynamic> toJson() => _$OptionItemToJson(this);
}
