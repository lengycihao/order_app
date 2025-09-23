import 'package:json_annotation/json_annotation.dart';

part 'takeaway_order_detail_model.g.dart';

/// 外卖订单详情响应模型
@JsonSerializable()
class TakeawayOrderDetailResponse {
  final int? id;
  @JsonKey(name: 'order_no')
  final String? orderNo;
  @JsonKey(name: 'order_time')
  final String? orderTime;
  @JsonKey(name: 'order_status')
  final int? orderStatus;
  @JsonKey(name: 'order_status_name')
  final String? orderStatusName;
  @JsonKey(name: 'checkout_status')
  final int? checkoutStatus;
  @JsonKey(name: 'checkout_status_name')
  final String? checkoutStatusName;
  @JsonKey(name: 'checkout_time')
  final String? checkoutTime;
  @JsonKey(name: 'total_amount')
  final String? totalAmount;
  @JsonKey(name: 'paid_amount')
  final String? paidAmount;
  @JsonKey(name: 'estimate_pickup_time')
  final String? estimatePickupTime;
  @JsonKey(name: 'pickup_code')
  final String? pickupCode;
  final String? remark;
  final int? source;
  @JsonKey(name: 'source_name')
  final String? sourceName;
  final List<TakeawayOrderDetailItem>? details;

  TakeawayOrderDetailResponse({
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

  factory TakeawayOrderDetailResponse.fromJson(Map<String, dynamic> json) {
    return _$TakeawayOrderDetailResponseFromJson(json);
  }

  Map<String, dynamic> toJson() => _$TakeawayOrderDetailResponseToJson(this);

  /// 获取格式化的订单时间
  String get formattedOrderTime {
    if (orderTime == null || orderTime!.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(orderTime!);
      return '${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return orderTime!;
    }
  }

  /// 获取格式化的总金额
  String get formattedTotalAmount {
    if (totalAmount == null || totalAmount!.isEmpty) return '€0.00';
    try {
      final amount = double.parse(totalAmount!);
      return '€${amount.toStringAsFixed(2)}';
    } catch (e) {
      return '€$totalAmount';
    }
  }

  /// 获取格式化的已付金额
  String get formattedPaidAmount {
    if (paidAmount == null || paidAmount!.isEmpty) return '€0.00';
    try {
      final amount = double.parse(paidAmount!);
      return '€${amount.toStringAsFixed(2)}';
    } catch (e) {
      return '€$paidAmount';
    }
  }

  /// 获取格式化的预计取餐时间
  String get formattedEstimatePickupTime {
    if (estimatePickupTime == null || estimatePickupTime!.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(estimatePickupTime!);
      return '${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return estimatePickupTime!;
    }
  }

  /// 是否已结账
  bool get isPaid => checkoutStatus == 1;

  /// 是否未结账
  bool get isUnpaid => checkoutStatus == 3;
}

/// 外卖订单详情商品项模型
@JsonSerializable()
class TakeawayOrderDetailItem {
  final int? id;
  @JsonKey(name: 'dish_id')
  final int? dishId;
  final String? name;
  final int? quantity;
  final String? price;
  @JsonKey(name: 'menu_price')
  final String? menuPrice;
  @JsonKey(name: 'price_increment')
  final String? priceIncrement;
  @JsonKey(name: 'unit_price')
  final String? unitPrice;
  @JsonKey(name: 'tax_rate')
  final String? taxRate;
  final String? image;
  final List<AllergenInfo>? allergens;
  @JsonKey(name: 'options_str')
  final String? optionsStr;
  @JsonKey(name: 'round_str')
  final String? roundStr;
  @JsonKey(name: 'quantity_str')
  final String? quantityStr;
  @JsonKey(name: 'cooking_status')
  final int? cookingStatus;
  @JsonKey(name: 'cooking_status_name')
  final String? cookingStatusName;
  @JsonKey(name: 'process_status')
  final int? processStatus;
  @JsonKey(name: 'process_status_name')
  final String? processStatusName;
  @JsonKey(name: 'cooking_timeout')
  final String? cookingTimeout;
  final String? remark;
  final List<String>? tags;

  TakeawayOrderDetailItem({
    this.id,
    this.dishId,
    this.name,
    this.quantity,
    this.price,
    this.menuPrice,
    this.priceIncrement,
    this.unitPrice,
    this.taxRate,
    this.image,
    this.allergens,
    this.optionsStr,
    this.roundStr,
    this.quantityStr,
    this.cookingStatus,
    this.cookingStatusName,
    this.processStatus,
    this.processStatusName,
    this.cookingTimeout,
    this.remark,
    this.tags,
  });

  factory TakeawayOrderDetailItem.fromJson(Map<String, dynamic> json) {
    return _$TakeawayOrderDetailItemFromJson(json);
  }

  Map<String, dynamic> toJson() => _$TakeawayOrderDetailItemToJson(this);

  /// 获取格式化的价格
  String get formattedPrice {
    if (price == null || price!.isEmpty) return '€0.00';
    try {
      final amount = double.parse(price!);
      return '€${amount.toStringAsFixed(2)}';
    } catch (e) {
      return '€$price';
    }
  }

  /// 获取格式化的单价
  String get formattedUnitPrice {
    if (unitPrice == null || unitPrice!.isEmpty) return '€0.00';
    try {
      final amount = double.parse(unitPrice!);
      return '€${amount.toStringAsFixed(2)}';
    } catch (e) {
      return '€$unitPrice';
    }
  }

  /// 获取格式化的烹饪超时时间
  String get formattedCookingTimeout {
    if (cookingTimeout == null || cookingTimeout!.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(cookingTimeout!);
      return '${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return cookingTimeout!;
    }
  }

  /// 获取数量显示文本
  String get quantityText {
    return 'x${quantity ?? 1}';
  }
}

/// 过敏原信息模型
@JsonSerializable()
class AllergenInfo {
  final String? label;
  final int? id;
  final String? icon;

  AllergenInfo({
    this.label,
    this.id,
    this.icon,
  });

  factory AllergenInfo.fromJson(Map<String, dynamic> json) {
    return _$AllergenInfoFromJson(json);
  }

  Map<String, dynamic> toJson() => _$AllergenInfoToJson(this);
}
