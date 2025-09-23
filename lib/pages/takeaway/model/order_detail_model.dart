import 'package:json_annotation/json_annotation.dart';

part 'order_detail_model.g.dart';

/// 订单详情响应模型
@JsonSerializable()
class OrderDetailResponse {
  @JsonKey(name: 'order_info')
  OrderInfoModel? orderInfo;

  @JsonKey(name: 'product_info')
  List<ProductInfoModel>? productInfo;

  OrderDetailResponse({
    this.orderInfo,
    this.productInfo,
  });

  factory OrderDetailResponse.fromJson(Map<String, dynamic> json) {
    return _$OrderDetailResponseFromJson(json);
  }

  Map<String, dynamic> toJson() => _$OrderDetailResponseToJson(this);
}

/// 订单信息模型
@JsonSerializable()
class OrderInfoModel {
  @JsonKey(name: 'pickup_code')
  String? pickupCode;

  @JsonKey(name: 'pickup_time')
  String? pickupTime;

  @JsonKey(name: 'remark')
  String? remark;

  @JsonKey(name: 'order_no')
  String? orderNo;

  @JsonKey(name: 'source')
  String? source;

  @JsonKey(name: 'order_time')
  String? orderTime;

  @JsonKey(name: 'checkout_status')
  int? checkoutStatus;

  @JsonKey(name: 'checkout_status_name')
  String? checkoutStatusName;

  OrderInfoModel({
    this.pickupCode,
    this.pickupTime,
    this.remark,
    this.orderNo,
    this.source,
    this.orderTime,
    this.checkoutStatus,
    this.checkoutStatusName,
  });

  factory OrderInfoModel.fromJson(Map<String, dynamic> json) {
    return _$OrderInfoModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$OrderInfoModelToJson(this);

  /// 获取格式化的取餐时间
  String get formattedPickupTime {
    if (pickupTime == null || pickupTime!.isEmpty) return '9999-99-99 00:00:00';
    try {
      final dateTime = DateTime.parse(pickupTime!);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return pickupTime!;
    }
  }

  /// 获取格式化的下单时间
  String get formattedOrderTime {
    if (orderTime == null || orderTime!.isEmpty) return '9999-99-99 00:00:00';
    try {
      final dateTime = DateTime.parse(orderTime!);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return orderTime!;
    }
  }

  /// 获取状态显示文本
  String get statusDisplayText {
    if (checkoutStatus == 1) {
      return '已结账';
    } else if (checkoutStatus == 3) {
      return '未结账';
    } else {
      return checkoutStatusName ?? '处理中';
    }
  }
}

/// 商品信息模型
@JsonSerializable()
class ProductInfoModel {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'price')
  String? price;

  @JsonKey(name: 'image')
  String? image;

  @JsonKey(name: 'quantity')
  int? quantity;

  @JsonKey(name: 'remark')
  String? remark;

  @JsonKey(name: 'tags')
  List<String>? tags;

  @JsonKey(name: 'total_price')
  String? totalPrice;

  ProductInfoModel({
    this.id,
    this.name,
    this.price,
    this.image,
    this.quantity,
    this.remark,
    this.tags,
    this.totalPrice,
  });

  factory ProductInfoModel.fromJson(Map<String, dynamic> json) {
    return _$ProductInfoModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ProductInfoModelToJson(this);

  /// 获取格式化的价格
  String get formattedPrice {
    if (price == null || price!.isEmpty) return '¥0';
    return '¥$price';
  }

  /// 获取格式化的总价
  String get formattedTotalPrice {
    if (totalPrice == null || totalPrice!.isEmpty) return '¥0';
    return '¥$totalPrice';
  }

  /// 获取数量显示文本
  String get quantityText {
    return 'x${quantity ?? 1}';
  }
}
