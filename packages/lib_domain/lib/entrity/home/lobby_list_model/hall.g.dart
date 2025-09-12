// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hall.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Hall _$HallFromJson(Map<String, dynamic> json) => Hall(
  hallId: (json['hall_id'] as num?)?.toInt(),
  hallName: json['hall_name'] as String?,
  tableCount: (json['table_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$HallToJson(Hall instance) => <String, dynamic>{
  'hall_id': instance.hallId,
  'hall_name': instance.hallName,
  'table_count': instance.tableCount,
};
