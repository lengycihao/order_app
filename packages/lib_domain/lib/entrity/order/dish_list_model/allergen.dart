import 'package:json_annotation/json_annotation.dart';

part 'allergen.g.dart';

@JsonSerializable()
class Allergen {
  String? label;
  int? id;
  String? icon;

  Allergen({this.label, this.id, this.icon});

  factory Allergen.fromJson(Map<String, dynamic> json) {
    return _$AllergenFromJson(json);
  }

  Map<String, dynamic> toJson() => _$AllergenToJson(this);
}
