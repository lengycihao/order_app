import 'package:json_annotation/json_annotation.dart';

part 'table_list_model.g.dart';

/// 通用数字转换函数，兼容 int、double、String
num _toNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

/// 字符串转换函数，兼容 int、double、String
String _toString(dynamic value) {
  if (value == null) return '0';
  if (value is String) return value;
  if (value is num) return value.toString();
  return '0';
}

/// 合并的桌台信息
@JsonSerializable()
class MergedTableInfo {
  @JsonKey(name: 'table_id', fromJson: _toString)
  final String tableId;

  @JsonKey(name: 'table_name')
  final String tableName;

  MergedTableInfo({
    required this.tableId,
    required this.tableName,
  });

  factory MergedTableInfo.fromJson(Map<String, dynamic> json) =>
      _$MergedTableInfoFromJson(json);

  Map<String, dynamic> toJson() => _$MergedTableInfoToJson(this);
}

@JsonSerializable()
class TableListModel {
  @JsonKey(name: 'hall_id', fromJson: _toString)
  final String hallId;

  @JsonKey(name: 'hall_name')
  final String? hallName;

  @JsonKey(name: 'table_id', fromJson: _toString)
  final String tableId;

  @JsonKey(name: 'table_name')
  final String? tableName;

  @JsonKey(name: 'standard_adult', fromJson: _toNum)
  final num standardAdult;

  @JsonKey(name: 'standard_child', fromJson: _toNum)
  final num standardChild;

  @JsonKey(name: 'current_adult', fromJson: _toNum)
  final num currentAdult;

  @JsonKey(name: 'current_child', fromJson: _toNum)
  final num currentChild;

  @JsonKey(name: 'status', fromJson: _toNum)
  final num status;

  @JsonKey(name: 'business_status', fromJson: _toNum)
  final num businessStatus;

  @JsonKey(name: 'business_status_name')
  final String? businessStatusName;

  @JsonKey(name: 'main_table_id', fromJson: _toString)
  final String mainTableId;

  @JsonKey(name: 'menu_id', fromJson: _toString)
  final String menuId;

  @JsonKey(name: 'open_time')
  final String? openTime;

  @JsonKey(name: 'order_time')
  final String? orderTime;

  @JsonKey(name: 'order_duration', fromJson: _toNum)
  final num orderDuration;

  @JsonKey(name: 'open_duration', fromJson: _toNum)
  final num openDuration;

  @JsonKey(name: 'checkout_time')
  final String? checkoutTime;

  @JsonKey(name: 'order_amount', fromJson: _toNum)
  final num orderAmount;

  @JsonKey(name: 'order_id', fromJson: _toString)
  final String orderId;

  @JsonKey(name: 'main_table')
  final dynamic mainTable;

  @JsonKey(name: 'merged_tables')
  final List<MergedTableInfo>? mergedTables;

  TableListModel({
    required this.hallId,
    this.hallName,
    required this.tableId,
    this.tableName,
    required this.standardAdult,
    required this.standardChild,
    required this.currentAdult,
    required this.currentChild,
    required this.status,
    required this.businessStatus,
    this.businessStatusName,
    required this.mainTableId,
    required this.menuId,
    this.openTime,
    this.orderTime,
    required this.orderDuration,
    required this.openDuration,
    this.checkoutTime,
    required this.orderAmount,
    required this.orderId,
    this.mainTable,
    this.mergedTables,
  });

  factory TableListModel.fromJson(Map<String, dynamic> json) =>
      _$TableListModelFromJson(json);

  Map<String, dynamic> toJson() => _$TableListModelToJson(this);
}
