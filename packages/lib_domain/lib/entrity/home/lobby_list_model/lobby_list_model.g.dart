// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lobby_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LobbyListModel _$LobbyListModelFromJson(Map<String, dynamic> json) =>
    LobbyListModel(
      halls: (json['halls'] as List<dynamic>?)
          ?.map((e) => Hall.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalTables: _toInt(json['total_tables']),
    );

Map<String, dynamic> _$LobbyListModelToJson(LobbyListModel instance) =>
    <String, dynamic>{
      'halls': instance.halls,
      'total_tables': instance.totalTables,
    };
