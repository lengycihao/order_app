import 'package:json_annotation/json_annotation.dart';

import 'hall.dart';

part 'lobby_list_model.g.dart';

@JsonSerializable()
class LobbyListModel {
  List<Hall>? halls;
  @JsonKey(name: 'total_tables')
  int? totalTables;

  LobbyListModel({this.halls, this.totalTables});

  factory LobbyListModel.fromJson(Map<String, dynamic> json) {
    return _$LobbyListModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$LobbyListModelToJson(this);
}
