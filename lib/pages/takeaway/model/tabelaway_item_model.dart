class TabelawayItemModel {
  final String orderNumber;
  final int status; //1未结账  2已结账
  final String time;
  final String price;
  final String? remark;

  const TabelawayItemModel({
    required this.orderNumber,
    required this.status,
    required this.time,
    required this.price,
    this.remark,
  });
}
