import 'package:json_annotation/json_annotation.dart';

import 'option_item.dart';

part 'option.g.dart';

@JsonSerializable()
class Option {
  String? id;
  String? name;
  @JsonKey(name: 'is_multiple')
  bool? isMultiple;
  @JsonKey(name: 'is_required')
  bool? isRequired;
  List<OptionItem>? items;

  Option({this.id, this.name, this.isMultiple, this.isRequired, this.items});

  factory Option.fromJson(Map<String, dynamic> json) {
    return _$OptionFromJson(json);
  }

  Map<String, dynamic> toJson() => _$OptionToJson(this);
}
