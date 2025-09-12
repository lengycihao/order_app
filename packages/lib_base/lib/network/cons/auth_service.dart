// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:lib_base/lib_base.dart';
// import 'package:lib_domain/api/auth_api.dart';
// import 'package:lib_domain/entrity/waiter/waiter_login_model/waiter_login_model.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:get/get.dart';
// import 'package:order_app/pages/nav/screen_nav_page.dart';

// class AuthService {
//   // ✅ 公开构造函数，GetIt 可以直接 new 出来
//   AuthService();

//   static const String _userAccountsKey = 'user_accounts';
//   static const String _currentUserKey = 'current_user';
//   static const FlutterSecureStorage _storage = FlutterSecureStorage();

//   final AuthApi _authApi = AuthApi();

//   WaiterLoginModel? _currentUser;
//   List<WaiterLoginModel> _userAccounts = [];

//   WaiterLoginModel? get currentUser => _currentUser;
//   List<WaiterLoginModel> get userAccounts => _userAccounts;

//   /// 初始化服务，读取缓存
//   Future<void> init() async {
//     _currentUser = await _loadCurrentUser();
//   }

//   Future<HttpResultN<WaiterLoginModel>> loginWithPassword({
//     required String phoneNumber,
//     required String password,
//     String lan = "cn",
//   }) async {
//     final result = await _authApi.loginWithPassword(
//       phoneNumber: phoneNumber,
//       password: password,
//       lan: lan,
//     );

//     if (result.isSuccess && result.data != null) {
//       await _handleLoginSuccess(result.data!);
//     }

//     return result;
//   }

//   Future<void> _handleLoginSuccess(WaiterLoginModel user) async {
//     _currentUser = user;
//     await _saveCurrentUser(user);

//     logger.info(
//       '登录成功',
//       tag: 'AuthService',
//       extra: {'userId': user.waiterId, 'nickname': user.waiterName},
//     );

//     // Get.offAll(() => ScreenNavPage());
//   }

//   Future<void> _saveCurrentUser(WaiterLoginModel user) async {
//     await _storage.write(key: _currentUserKey, value: user.toRawJson());
//   }

//   /// 读取缓存用户
//   Future<WaiterLoginModel?> _loadCurrentUser() async {
//     try {
//       final userString = await _storage.read(key: _currentUserKey);
//       if (userString != null) {
//         return WaiterLoginModel.fromRawJson(userString);
//       }
//     } catch (e) {
//       debugPrint('读取缓存用户失败: $e');
//     }
//     return null;
//   }

//   Future<void> loadCurrentUser() async {
//     final userString = await _storage.read(key: _currentUserKey);
//     if (userString != null) {
//       _currentUser = WaiterLoginModel.fromRawJson(userString);
//     }
//   }

//   bool get isLoggedIn => _currentUser != null && _currentUser!.token != null;
// }
