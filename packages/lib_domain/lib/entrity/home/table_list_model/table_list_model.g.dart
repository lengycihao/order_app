// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TableListModel _$TableListModelFromJson(Map<String, dynamic> json) =>
    TableListModel(
      hallId: _toNum(json['hall_id']),
      hallName: json['hall_name'] as String?,
      tableId: _toNum(json['table_id']),
      tableName: json['table_name'] as String?,
      standardAdult: _toNum(json['standard_adult']),
      standardChild: _toNum(json['standard_child']),
      currentAdult: _toNum(json['current_adult']),
      currentChild: _toNum(json['current_child']),
      status: _toNum(json['status']),
      businessStatus: _toNum(json['business_status']),
      businessStatusName: json['business_status_name'] as String?,
      mainTableId: _toNum(json['main_table_id']),
      menuId: _toNum(json['menu_id']),
      openTime: json['open_time'] as String?,
      orderTime: json['order_time'] as String?,
      orderDuration: _toNum(json['order_duration']),
      openDuration: _toNum(json['open_duration']),
      checkoutTime: json['checkout_time'] as String?,
      orderAmount: _toNum(json['order_amount']),
      mainTable: json['main_table'],
    );

Map<String, dynamic> _$TableListModelToJson(TableListModel instance) =>
    <String, dynamic>{
      'hall_id': instance.hallId,
      'hall_name': instance.hallName,
      'table_id': instance.tableId,
      'table_name': instance.tableName,
      'standard_adult': instance.standardAdult,
      'standard_child': instance.standardChild,
      'current_adult': instance.currentAdult,
      'current_child': instance.currentChild,
      'status': instance.status,
      'business_status': instance.businessStatus,
      'business_status_name': instance.businessStatusName,
      'main_table_id': instance.mainTableId,
      'menu_id': instance.menuId,
      'open_time': instance.openTime,
      'order_time': instance.orderTime,
      'order_duration': instance.orderDuration,
      'open_duration': instance.openDuration,
      'checkout_time': instance.checkoutTime,
      'order_amount': instance.orderAmount,
      'main_table': instance.mainTable,
    };
