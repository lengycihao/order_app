import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lib_base/network/interceptor/auth_service.dart';
import 'package:order_app/service/service_locator.dart';

class AuthTestPage extends StatefulWidget {
  const AuthTestPage({Key? key}) : super(key: key);

  @override
  State<AuthTestPage> createState() => _AuthTestPageState();
}

class _AuthTestPageState extends State<AuthTestPage> {
  final authService = getIt<AuthService>();
  String? currentToken;
  String? currentUser;

  @override
  void initState() {
    super.initState();
    _refreshUserInfo();
  }

  void _refreshUserInfo() {
    setState(() {
      currentToken = authService.getCurrentToken();
      currentUser = authService.currentUser?.waiterName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('认证测试页面'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前用户信息',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('用户名: ${currentUser ?? "未登录"}'),
                    Text('Token: ${currentToken != null ? "${currentToken!.substring(0, 20)}..." : "无"}'),
                    Text('登录状态: ${authService.isLoggedIn ? "已登录" : "未登录"}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _refreshUserInfo,
                  child: const Text('刷新用户信息'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await authService.refreshUserInfo();
                    _refreshUserInfo();
                  },
                  child: const Text('强制刷新'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await authService.logout();
                _refreshUserInfo();
                Get.snackbar('提示', '已登出');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('登出'),
            ),
            const SizedBox(height: 16),
            const Text(
              '调试信息:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('GetIt注册状态: ${getIt.isRegistered<AuthService>()}'),
            Text('GetX注册状态: ${Get.isRegistered<AuthService>()}'),
          ],
        ),
      ),
    );
  }
}
