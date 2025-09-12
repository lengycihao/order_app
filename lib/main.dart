import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lib_base/lib_base.dart';
import 'package:order_app/pages/login/login_page.dart';
import 'package:order_app/pages/nav/screen_nav_page.dart';
import 'package:lib_base/network/interceptor/auth_service.dart';
import 'package:lib_base/config/app_configN.dart';
import 'package:lib_base/network/interceptor/api_business_interceptor.dart';
import 'package:lib_base/network/interceptor/network_loading_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:order_app/service/service_locator.dart';

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

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // 使用 GetMaterialApp 替换 MaterialApp
      title: 'Flutter Demo',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: isLoggedIn ? '/home' : '/login', // 动态控制初始页面
      getPages: [
        GetPage(name: '/login', page: () => LoginPage()), // 登录页面路由
        // 在这里可以添加其他页面路由
        GetPage(name: '/home', page: () => ScreenNavPage()), // 示例其他页面路由
      ],
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
    defaultTitle: '认证失败',
    defaultMessage: '登录已过期，请重新登录',
    cooldownDuration: const Duration(seconds: 3),
    snackbarDuration: const Duration(seconds: 2),
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

  // // 是不是同意了隐私协议
  // bool isAgreePrivacy = YYCacheUtils().getBool(YYCacheKey.agreementFlag, false);
  // if (isAgreePrivacy) {
  //   //初始化全局管理器
  //   await MMAppGlobalManager.instance.initApp();
  // }
}

