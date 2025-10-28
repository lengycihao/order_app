import 'package:json_annotation/json_annotation.dart';

import 'allergen.dart';
import 'option.dart';

part 'item.g.dart';

@JsonSerializable()
class Item {
  String? id;
  String? name;
  @JsonKey(name: 'category_id')
  String? categoryId;
  String? description;
  String? price;
  @JsonKey(name: 'unit_price')
  String? unitPrice;
  String? image;
  List<String>? tags;
  String? type;
  List<Option>? options;
  @JsonKey(name: 'has_options')
  bool? hasOptions;
  List<Allergen>? allergens;

  Item({
    this.id,
    this.name,
    this.categoryId,
    this.description,
    this.price,
    this.unitPrice,
    this.image,
    this.tags,
    this.type,
    this.options,
    this.hasOptions,
    this.allergens,
  });

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  Map<String, dynamic> toJson() => _$ItemToJson(this);
}
