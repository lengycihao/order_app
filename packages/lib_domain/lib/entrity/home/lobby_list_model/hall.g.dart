// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hall.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Hall _$HallFromJson(Map<String, dynamic> json) => Hall(
  hallId: _toInt(json['hall_id']),
  hallName: json['hall_name'] as String?,
  tableCount: _toInt(json['table_count']),
);

Map<String, dynamic> _$HallToJson(Hall instance) => <String, dynamic>{
  'hall_id': instance.hallId,
  'hall_name': instance.hallName,
  'table_count': instance.tableCount,
};
