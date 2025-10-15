class WaiterSettingModel {
  final bool confirmOrderBeforeSubmit;

  WaiterSettingModel({
    required this.confirmOrderBeforeSubmit,
  });

  factory WaiterSettingModel.fromJson(Map<String, dynamic> json) {
    return WaiterSettingModel(
      confirmOrderBeforeSubmit: json['confirm_order_before_submit'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'confirm_order_before_submit': confirmOrderBeforeSubmit,
    };
  }
}
