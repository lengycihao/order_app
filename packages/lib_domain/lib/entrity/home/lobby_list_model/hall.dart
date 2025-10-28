import 'package:json_annotation/json_annotation.dart';

part 'hall.g.dart';

/// 通用数字转换函数，兼容 int、double、String
int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

@JsonSerializable()
class Hall {
  @JsonKey(name: 'hall_id', fromJson: _toInt)
  int? hallId;
  @JsonKey(name: 'hall_name')
  String? hallName;
  @JsonKey(name: 'table_count', fromJson: _toInt)
  int? tableCount;

  Hall({this.hallId, this.hallName, this.tableCount});

  factory Hall.fromJson(Map<String, dynamic> json) => _$HallFromJson(json);

  Map<String, dynamic> toJson() => _$HallToJson(this);
}
