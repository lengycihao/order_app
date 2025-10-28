import 'package:flutter/foundation.dart';
import 'package:lib_base/lib_base.dart';
import 'package:lib_domain/api/auth_api.dart';
import 'package:lib_domain/entrity/waiter/waiter_login_model/waiter_login_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // ✅ 公开构造函数，GetIt 可以直接 new 出来
  AuthService();

  static const String _currentUserKey = 'current_user';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  final AuthApi _authApi = AuthApi();

  WaiterLoginModel? _currentUser;
  List<WaiterLoginModel> _userAccounts = [];

  WaiterLoginModel? get currentUser => _currentUser;
  List<WaiterLoginModel> get userAccounts => _userAccounts;

  /// 初始化服务，读取缓存
  Future<void> init() async {
    _currentUser = await _loadCurrentUser();
  }

  Future<HttpResultN<WaiterLoginModel>> loginWithPassword({
    required String phoneNumber,
    required String password,
    String lan = "cn",
  }) async {
    final result = await _authApi.loginWithPassword(
      phoneNumber: phoneNumber,
      password: password,
      lan: lan,
    );

    if (result.isSuccess && result.data != null) {
      await _handleLoginSuccess(result.data!);
    }

    return result;
  }

  Future<void> _handleLoginSuccess(WaiterLoginModel user) async {
    _currentUser = user;
    await _saveCurrentUser(user);

    logger.info(
      '登录成功',
      tag: 'AuthService',
      extra: {'userId': user.waiterId, 'nickname': user.waiterName},
    );

    // Get.offAll(() => ScreenNavPage());
  }

  Future<void> _saveCurrentUser(WaiterLoginModel user) async {
    try {
      await _storage.write(key: _currentUserKey, value: user.toRawJson());
      logger.debug('用户信息已保存到缓存', tag: 'AuthService');
    } catch (e) {
      logger.error('保存用户信息失败: $e', tag: 'AuthService');
    }
  }

  /// 读取缓存用户
  Future<WaiterLoginModel?> _loadCurrentUser() async {
    try {
      final userString = await _storage.read(key: _currentUserKey);
      if (userString != null) {
        return WaiterLoginModel.fromRawJson(userString);
      }
    } catch (e) {
      debugPrint('读取缓存用户失败: $e');
    }
    return null;
  }

  Future<void> loadCurrentUser() async {
    try {
      final userString = await _storage.read(key: _currentUserKey);
      if (userString != null) {
        _currentUser = WaiterLoginModel.fromRawJson(userString);
        logger.debug('从缓存加载用户信息成功: ${_currentUser?.waiterName}', tag: 'AuthService');
      } else {
        logger.debug('缓存中无用户信息', tag: 'AuthService');
      }
    } catch (e) {
      logger.error('从缓存加载用户信息失败: $e', tag: 'AuthService');
      _currentUser = null;
    }
  }

  bool get isLoggedIn => _currentUser != null && _currentUser!.token != null;

  /// 获取当前用户的token
  String? getCurrentToken() {
    final token = _currentUser?.token;
    if (token != null) {
      logger.debug('获取到用户token: ${token.substring(0, 20)}...', tag: 'AuthService');
    } else {
      logger.debug('当前用户token为空', tag: 'AuthService');
    }
    return token;
  }

  /// 强制刷新用户信息（从缓存重新加载）
  Future<void> refreshUserInfo() async {
    logger.info('强制刷新用户信息', tag: 'AuthService');
    _currentUser = await _loadCurrentUser();
    if (_currentUser != null) {
      logger.info('刷新成功，用户: ${_currentUser!.waiterName}', tag: 'AuthService');
    } else {
      logger.info('刷新失败，无缓存用户', tag: 'AuthService');
    }
  }

  /// 修改密码
  Future<HttpResultN<void>> changePassword({
    required String newPassword,
  }) async {
    final result = await _authApi.changePassword(newPassword: newPassword);
    
    if (result.isSuccess) {
      logger.info('密码修改成功', tag: 'AuthService');
    } else {
      logger.error('密码修改失败: ${result.msg}', tag: 'AuthService');
    }
    
    return result;
  }

  /// 登出
  Future<void> logout() async {
    _currentUser = null;
    await _storage.delete(key: _currentUserKey);
    logger.info('用户已登出', tag: 'AuthService');
  }
}
