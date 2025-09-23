import 'package:json_annotation/json_annotation.dart';

part 'menu_fixed_cost.g.dart';

@JsonSerializable()
class MenuFixedCost {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'amount')
  String? amount;

  @JsonKey(name: 'type')
  int? type;

  @JsonKey(name: 'unit')
  String? unit;

  MenuFixedCost({
    this.id,
    this.name,
    this.amount,
    this.type,
    this.unit,
  });

  factory MenuFixedCost.fromJson(Map<String, dynamic> json) {
    return _$MenuFixedCostFromJson(json);
  }

  Map<String, dynamic> toJson() => _$MenuFixedCostToJson(this);
}
