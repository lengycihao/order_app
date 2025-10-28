import 'package:json_annotation/json_annotation.dart';

part 'takeaway_order_model.g.dart';

/// 外卖订单列表响应模型
@JsonSerializable()
class TakeawayOrderListResponse {
  @JsonKey(name: 'page')
  int? page;

  @JsonKey(name: 'page_size')
  int? pageSize;

  @JsonKey(name: 'is_last_page')
  bool? isLastPage;

  @JsonKey(name: 'total')
  int? total;

  @JsonKey(name: 'data')
  List<TakeawayOrderModel>? data;

  TakeawayOrderListResponse({
    this.page,
    this.pageSize,
    this.isLastPage,
    this.total,
    this.data,
  });

  factory TakeawayOrderListResponse.fromJson(Map<String, dynamic> json) {
    return _$TakeawayOrderListResponseFromJson(json);
  }

  Map<String, dynamic> toJson() => _$TakeawayOrderListResponseToJson(this);
}

/// 外卖订单模型
@JsonSerializable()
class TakeawayOrderModel {
  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'order_no')
  String? orderNo;

  @JsonKey(name: 'order_time')
  String? orderTime;

  @JsonKey(name: 'order_status')
  int? orderStatus;

  @JsonKey(name: 'order_status_name')
  String? orderStatusName;

  @JsonKey(name: 'checkout_status')
  int? checkoutStatus;

  @JsonKey(name: 'checkout_status_name')
  String? checkoutStatusName;

  @JsonKey(name: 'checkout_time')
  String? checkoutTime;

  @JsonKey(name: 'total_amount')
  String? totalAmount;

  @JsonKey(name: 'paid_amount')
  String? paidAmount;

  @JsonKey(name: 'estimate_pickup_time')
  String? estimatePickupTime;

  @JsonKey(name: 'pickup_code')
  String? pickupCode;

  @JsonKey(name: 'remark')
  String? remark;

  @JsonKey(name: 'source')
  int? source;

  @JsonKey(name: 'source_name')
  String? sourceName;

  @JsonKey(name: 'details')
  dynamic details;

  TakeawayOrderModel({
    this.id,
    this.orderNo,
    this.orderTime,
    this.orderStatus,
    this.orderStatusName,
    this.checkoutStatus,
    this.checkoutStatusName,
    this.checkoutTime,
    this.totalAmount,
    this.paidAmount,
    this.estimatePickupTime,
    this.pickupCode,
    this.remark,
    this.source,
    this.sourceName,
    this.details,
  });

  factory TakeawayOrderModel.fromJson(Map<String, dynamic> json) {
    return _$TakeawayOrderModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$TakeawayOrderModelToJson(this);

  /// 获取格式化的订单时间
  String get formattedOrderTime {
    if (orderTime == null || orderTime!.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(orderTime!);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return orderTime!;
    }
  }

  /// 获取格式化的总金额
  String get formattedTotalAmount {
    if (totalAmount == null || totalAmount!.isEmpty) return '€ 0';
    return '€ $totalAmount';
  }

  /// 获取格式化的预计取餐时间
  String get formattedEstimatePickupTime {
    if (estimatePickupTime == null || estimatePickupTime!.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(estimatePickupTime!);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return estimatePickupTime!;
    }
  }

  /// 判断是否已结账
  bool get isPaid {
    return checkoutStatus == 1; // 1表示已结账
  }

  /// 判断是否未结账
  bool get isUnpaid {
    return checkoutStatus == 3; // 3表示未结账
  }

  /// 获取订单状态描述（用于调试）
  String get debugStatusInfo {
    return 'ID: $id, OrderNo: $orderNo, CheckoutStatus: $checkoutStatus, CheckoutStatusName: $checkoutStatusName';
  }
}
