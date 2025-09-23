class HistoryAccount {
  final String username;
  final String password;
  final DateTime lastLoginTime;

  HistoryAccount({
    required this.username,
    required this.password,
    required this.lastLoginTime,
  });

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'lastLoginTime': lastLoginTime.toIso8601String(),
    };
  }

  // 从JSON创建对象
  factory HistoryAccount.fromJson(Map<String, dynamic> json) {
    return HistoryAccount(
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      lastLoginTime: DateTime.parse(json['lastLoginTime'] ?? DateTime.now().toIso8601String()),
    );
  }

  // 复制对象
  HistoryAccount copyWith({
    String? username,
    String? password,
    DateTime? lastLoginTime,
  }) {
    return HistoryAccount(
      username: username ?? this.username,
      password: password ?? this.password,
      lastLoginTime: lastLoginTime ?? this.lastLoginTime,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryAccount && other.username == username;
  }

  @override
  int get hashCode => username.hashCode;
}
