import 'package:json_annotation/json_annotation.dart';

part 'hall.g.dart';

@JsonSerializable()
class Hall {
  @JsonKey(name: 'hall_id')
  int? hallId;
  @JsonKey(name: 'hall_name')
  String? hallName;
  @JsonKey(name: 'table_count')
  int? tableCount;

  Hall({this.hallId, this.hallName, this.tableCount});

  factory Hall.fromJson(Map<String, dynamic> json) => _$HallFromJson(json);

  Map<String, dynamic> toJson() => _$HallToJson(this);
}
