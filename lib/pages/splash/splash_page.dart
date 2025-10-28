import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/login/login_page.dart';
import 'package:order_app/pages/nav/screen_nav_page.dart';
import 'package:order_app/service/service_locator.dart';
import 'package:lib_base/network/interceptor/auth_service.dart';
import 'package:order_app/l10n/app_localizations.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 并行执行初始化任务和最小显示时间
    final initFuture = _performInitialization();
    final delayFuture = Future.delayed(const Duration(milliseconds: 800));
    
    // 等待两个任务都完成
    await Future.wait([initFuture, delayFuture]);
    
    // 检查登录状态
    final authService = getIt<AuthService>();
    final bool isLoggedIn = authService.isLoggedIn;
    
    // 导航到相应页面
    if (mounted) {
      if (isLoggedIn) {
        Get.offAll(() => ScreenNavPage());
      } else {
        Get.offAll(() => LoginPage());
      }
    }
  }
  
  Future<void> _performInitialization() async {
    // 这里可以添加其他初始化任务
    // 比如预加载数据、检查更新等
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Container(
        width: screenSize.width,
        height: screenSize.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/spash.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // 中间的标题图片
            Center(
              child: Image.asset(
                'assets/spash_title.webp',
                width: 159,
                height: 33,
                fit: BoxFit.contain,
              ),
            ),
            
            // 底部版权信息
            Positioned(
              left: 0,
              right: 0,
              bottom: 66,
              child: Text(
                localizations.copyright,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF000000),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
