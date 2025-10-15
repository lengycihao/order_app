import 'package:get/get.dart' as gg;
import 'package:order_app/utils/toast_utils.dart';

/// 401未授权错误处理器
/// 提供统一的401错误处理逻辑，支持自定义配置
class UnauthorizedHandler {
  static UnauthorizedHandler? _instance;
  static UnauthorizedHandler get instance => _instance ??= UnauthorizedHandler._();
  
  UnauthorizedHandler._();

  // 防重复处理机制
  bool _isHandling = false;
  DateTime? _lastHandleTime;
  Duration _cooldownDuration = const Duration(seconds: 3);

  // 配置参数
  String _loginRoute = '/login';
  String _defaultMessage = '登录已过期，请重新登录';
  List<String> _fallbackRoutes = ['/login', '/auth', '/signin'];

  /// 配置401处理器
  void configure({
    String? loginRoute,
    String? defaultMessage,
    Duration? cooldownDuration,
    List<String>? fallbackRoutes,
  }) {
    if (loginRoute != null) _loginRoute = loginRoute;
    if (defaultMessage != null) _defaultMessage = defaultMessage;
    if (cooldownDuration != null) _cooldownDuration = cooldownDuration;
    if (fallbackRoutes != null) _fallbackRoutes = fallbackRoutes;
  }

  /// 处理401错误
  /// 返回true表示处理成功，false表示跳过处理（防重复）
  bool handle401Error(String? message) {
    final now = DateTime.now();
    
    // 检查冷却期
    if (_lastHandleTime != null && 
        now.difference(_lastHandleTime!) < _cooldownDuration) {
      print('🔒 401错误在冷却期内，跳过处理');
      return false;
    }

    // 检查是否正在处理
    if (_isHandling) {
      print('🔒 正在处理401错误，跳过重复处理');
      return false;
    }

    // 检查当前是否已经在登录页
    if (_isCurrentlyOnLoginPage()) {
      print('🔒 当前已在登录页，跳过401处理');
      return false;
    }

    // 开始处理
    _isHandling = true;
    _lastHandleTime = now;

    try {
      print('🔐 开始处理401错误');
      
      // 先跳转到登录页
      _navigateToLogin();
      
      // 延迟显示提示消息，确保在登录页显示
      Future.delayed(const Duration(milliseconds: 300), () {
        _showMessage(message);
      });
      
      print('✅ 401错误处理完成');
      return true;
      
    } catch (e) {
      print('❌ 处理401错误失败: $e');
      return false;
    } finally {
      // 延迟重置标志
      Future.delayed(const Duration(milliseconds: 500), () {
        _isHandling = false;
      });
    }
  }

  /// 显示提示消息
  void _showMessage(String? message) {
    try {
      final displayMessage = message ?? _defaultMessage;
      
      // 使用ToastUtils显示提示
      ToastUtils.showError(gg.Get.context!, displayMessage);
      
      print('💬 已显示401提示消息');
    } catch (e) {
      print('❌ 显示401提示失败: $e');
      // 备用提示方式
      print('🔐 认证失败: ${message ?? _defaultMessage}');
    }
  }

  /// 跳转到登录页
  void _navigateToLogin() {
    try {
      print('🔄 自动跳转到登录页...');
      
      // 首先尝试主要路由
      gg.Get.offAllNamed(_loginRoute);
      print('✅ 已跳转到登录页: $_loginRoute');
      
    } catch (e) {
      print('❌ 主要登录路由失败: $e');
      
      // 尝试备用路由
      _tryFallbackRoutes();
    }
  }

  /// 尝试备用路由
  void _tryFallbackRoutes() {
    for (final route in _fallbackRoutes) {
      try {
        gg.Get.offAllNamed(route);
        print('✅ 通过备用路由跳转成功: $route');
        return;
      } catch (e) {
        print('❌ 备用路由失败: $route - $e');
        continue;
      }
    }
    
    print('❌ 所有登录路由都失败');
    _handleNavigationFailure();
  }

  /// 处理导航失败的情况
  void _handleNavigationFailure() {
    try {
      // 显示错误提示
      ToastUtils.showError(gg.Get.context!, '无法跳转到登录页，请手动重启应用');
    } catch (e) {
      print('❌ 显示导航失败提示也失败: $e');
    }
  }


  /// 重置处理状态（用于测试或手动重置）
  void resetState() {
    _isHandling = false;
    _lastHandleTime = null;
    print('🔄 已重置401处理状态');
  }

  /// 检查当前是否在登录页
  bool _isCurrentlyOnLoginPage() {
    try {
      final currentRoute = gg.Get.currentRoute;
      return _fallbackRoutes.contains(currentRoute) || currentRoute == _loginRoute;
    } catch (e) {
      print('❌ 检查当前路由失败: $e');
      return false;
    }
  }

  /// 获取当前状态信息
  Map<String, dynamic> getStatus() {
    return {
      'isHandling': _isHandling,
      'lastHandleTime': _lastHandleTime?.toIso8601String(),
      'cooldownDuration': _cooldownDuration.inSeconds,
      'loginRoute': _loginRoute,
      'currentRoute': gg.Get.currentRoute,
    };
  }
}
