class WaiterInfoModel {
  final String name;
  final String account;
  final String avatar;
  final String storeName;
  final String authExpireTime;
  final int surplusDays;

  WaiterInfoModel({
    required this.name,
    required this.account,
    required this.avatar,
    required this.storeName,
    required this.authExpireTime,
    required this.surplusDays,
  });

  factory WaiterInfoModel.fromJson(Map<String, dynamic> json) {
    return WaiterInfoModel(
      name: json['name'] ?? '',
      account: json['account'] ?? '',
      avatar: json['avatar'] ?? '',
      storeName: json['store_name'] ?? '',
      authExpireTime: json['auth_expire_time'] ?? '',
      surplusDays: json['surplus_days'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'account': account,
      'avatar': avatar,
      'store_name': storeName,
      'auth_expire_time': authExpireTime,
      'surplus_days': surplusDays,
    };
  }

  /// 格式化到期时间为 YYYY-MM-DD 格式
  String get formattedExpireDate {
    try {
      if (authExpireTime.isEmpty) return '';
      // 如果已经是 YYYY-MM-DD HH:mm:ss 格式，只取日期部分
      if (authExpireTime.contains(' ')) {
        return authExpireTime.split(' ')[0];
      }
      return authExpireTime;
    } catch (e) {
      return authExpireTime;
    }
  }
}
