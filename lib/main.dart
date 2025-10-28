import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lib_base/lib_base.dart';
import 'package:order_app/pages/login/login_page.dart';
import 'package:order_app/pages/nav/screen_nav_page.dart';
import 'package:order_app/pages/dish/dish_detail_route_page.dart';
import 'package:order_app/pages/splash/splash_page.dart';
import 'package:lib_base/network/interceptor/auth_service.dart';
import 'package:lib_base/config/app_configN.dart';
import 'package:lib_base/network/interceptor/api_business_interceptor.dart';
import 'package:lib_base/network/interceptor/network_loading_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:order_app/service/service_locator.dart';
import 'package:order_app/l10n/app_localizations.dart';
import 'package:order_app/services/language_service.dart';
import 'package:toast/toast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _syncInit();

  // 先初始化服务定位器
  await setupServiceLocator();
  
  // 从服务定位器获取AuthService实例
  final authService = getIt<AuthService>();
  final bool isLoggedIn = authService.isLoggedIn;
  // 获取AuthService实例
  // final authService = getIt<AuthService>();

  // // 初始化lib_base组件，传入authService
  // await LibBaseInitializer.initialize(
  //   appId: 'gumiao_voice_app',
  //   httpUrl: 'http://192.168.110.220',
  //   wsUrl: 'wss://ws.tjwuming.com',
  //   responseConfig: const ResponseConfig(
  //     dataKey: 'retData',
  //     codeKey: 'retCode',
  //     errorCodeKey: 'retErrorCode',
  //     messageKey: 'retMessage',
  //     errorMessageKey: 'retErrorMessage',
  //   ),
  //   ossBucketName: 'ppl-files',
  //   // apiAesKey1:'mMXhJ7',
  //   // apiAesKey2:'j1DUbKHPYQWQJwA',
  //   // authService: authService, // 传入authService
  // );
  // List<Interceptor> httpInterceptors = [ApiInterceptor()];
  // HttpManagerN.instance.init(
  //   AppConfigN.baseApiUrl,
  //   interceptors: httpInterceptors,
  // );
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  // 全局Navigator key
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // 获取LanguageService实例
    final languageService = getIt<LanguageService>();
    
    return AnimatedBuilder(
      animation: languageService,
      builder: (context, child) {
        return GetMaterialApp(
      navigatorKey: navigatorKey, // 添加Navigator key
      // 使用 GetMaterialApp 替换 MaterialApp
      title: 'Flutter Demo',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        // 完全移除输入框的水滴效果
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.black54,
          selectionColor: Colors.transparent,
          selectionHandleColor: Colors.transparent,
        ),
        // 移除Material Design的所有水滴和波纹效果
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        // 移除输入框的焦点效果
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          border: InputBorder.none,
        ),
      ),
      
      // 添加国际化配置
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: languageService.currentLocale, // 使用LanguageService中的语言设置
      
      getPages: [
        GetPage(name: '/splash', page: () => const SplashPage()), // 启动页路由
        GetPage(name: '/login', page: () => LoginPage()), // 登录页面路由
        // 在这里可以添加其他页面路由
        GetPage(name: '/home', page: () => ScreenNavPage()), // 示例其他页面路由
        GetPage(name: '/dish-detail-route', page: () => DishDetailRoutePage()), // 菜品详情路由页面
      ],
      home: const SplashPage(), // 启动时显示启动页
      builder: (context, child) {
        // 初始化 Toast Context
        ToastContext().init(context);
        
        // 在应用启动时立即设置全局Context
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            // 导入Toast工具类并设置context
            // 这里不直接导入避免循环依赖，在实际使用时会自动设置
          }
        });
        return child ?? const SizedBox.shrink();
      },
        );
      },
    );
  }
}

Future _syncInit() async {
  await AppConfigN.configuration();
  
  // 初始化新的日志系统
  await LogManager.instance.initialize(
    const LogConfig(
      enableConsoleLog: true,
      enableFileLog: false,
      enableUpload: false,
      minLevel: LogLevel.debug,
    ),
  );
  
  // 保持旧的日志系统兼容性
  await LogUtil.instance.init();

  // 配置401错误处理器
  UnauthorizedHandler.instance.configure(
    loginRoute: '/login',
    defaultMessage: '登录已过期，请重新登录',
    cooldownDuration: const Duration(seconds: 3),
    fallbackRoutes: ['/login', '/auth'],
  );

  List<Interceptor> httpInterceptors = [
    NetworkLoadingInterceptor(), // 负责统一管理loading显示
    ApiResponseInterceptor(), // 负责添加认证头
    ApiBusinessInterceptor(), // 负责业务逻辑处理
  ];
  HttpManagerN.instance.init(
    AppConfigN.baseApiUrl,
    interceptors: httpInterceptors,
  );

}

