import 'package:json_annotation/json_annotation.dart';

import 'hall.dart';

part 'lobby_list_model.g.dart';

/// 通用数字转换函数，兼容 int、double、String
int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

@JsonSerializable()
class LobbyListModel {
  List<Hall>? halls;
  @JsonKey(name: 'total_tables', fromJson: _toInt)
  int? totalTables;

  LobbyListModel({this.halls, this.totalTables});

  factory LobbyListModel.fromJson(Map<String, dynamic> json) {
    return _$LobbyListModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$LobbyListModelToJson(this);
}
