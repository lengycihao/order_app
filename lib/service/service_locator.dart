import 'package:get_it/get_it.dart';
import 'package:lib_base/network/interceptor/auth_service.dart';
import 'package:lib_base/lib_base.dart';
import 'package:order_app/services/language_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ✅ 注册 AuthService 单例
  final authService = AuthService();
  getIt.registerSingleton<AuthService>(authService);

  // 注册 LanguageService 单例
  final languageService = LanguageService();
  getIt.registerSingleton<LanguageService>(languageService);

  // 初始化 AuthService
  await authService.init();
  
  // 初始化 LanguageService
  await languageService.initialize();

  // // 注册购物车缓存服务（使用GetX）
  // Get.put<CartCacheService>(CartCacheService(), permanent: true);

  logger.info('Service locator setup completed', tag: 'ServiceLocator');
}

/// Clean up all registered services
Future<void> cleanupServiceLocator() async {
  logger.info('Cleaning up service locator', tag: 'ServiceLocator');

  // Reset GetIt instance
  await getIt.reset();

  logger.info('Service locator cleanup completed', tag: 'ServiceLocator');
}

/// Convenience methods for common service access
extension ServiceLocatorExtensions on GetIt {
  // Business services
  AuthService get authService => get<AuthService>();
  LanguageService get languageService => get<LanguageService>();
}
