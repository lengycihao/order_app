import 'package:flutter/material.dart';
import 'package:order_app/pages/login/login_controller.dart';
import 'package:get/get.dart';

class LoginPage extends StatelessWidget {
  LoginPage({Key? key}) : super(key: key);

  final LoginController controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图
          Image.asset('assets/order_login_bg.webp', fit: BoxFit.cover),
          Positioned(
            top: 50,
            right: 30,
            child: Obx(
              () => AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: 105,
                height: controller.isExpanded.value ? 130 : 30,
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(15), // 圆角
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          controller.isExpanded.value =
                              !controller.isExpanded.value;
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset(
                              'assets/order_login_earth.webp',
                              width: 16,
                              height: 16,
                            ),
                            Text(
                              "中文(简体)",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xff333333),
                              ),
                            ),
                            Image.asset(
                              'assets/order_login_arrowD.webp',
                              width: 16,
                            ),
                          ],
                        ),
                      ),

                      Obx(() {
                        // 根据状态决定是否构建
                        if (controller.isExpanded.value) {
                          return Container(
                            margin: EdgeInsets.only(top: 10),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Image.asset(
                                      'assets/order_login_china.webp',
                                      width: 20,
                                      height: 13,
                                    ),
                                    Text('中文(简体)'),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Image.asset(
                                      'assets/order_login_english.webp',
                                      width: 20,
                                      height: 13,
                                    ),
                                    Text('English'),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Image.asset(
                                      'assets/order_login_italiano.webp',
                                      width: 20,
                                      height: 13,
                                    ),
                                    Text('Italiano'),
                                  ],
                                ),
                              ],
                            ),
                          );
                        } else {
                          // 不显示时返回空
                          return SizedBox.shrink();
                        }
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 70),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "欢迎使用",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 36,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 50),
                  // 账号输入框
                  SizedBox(
                    height: 45,
                    child: TextField(
                      controller: controller.usernameController,
                      cursorHeight: 16,
                      cursorColor: Colors.black54,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            top: 12,
                            bottom: 12,
                          ),
                          child: Image.asset(
                            'assets/order_login_login.webp',
                            width: 16,
                            height: 16,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),
                        hintText: '请输入账号',
                        hintStyle: TextStyle(
                          color: Color(0xff666666),
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFEAF6FF), // 设置背景色
                        border: InputBorder.none, // 去掉边框
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50), // 圆角
                          borderSide: BorderSide.none, // 去掉边框
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50), // 圆角
                          borderSide: BorderSide.none, // 去掉边框
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 密码输入框（带可见切换）
                  Obx(
                    () => SizedBox(
                      height: 45,
                      child: TextField(
                        controller: controller.passwordController,
                        obscureText: controller.obscurePassword.value,
                        cursorHeight: 16,
                        cursorColor: Colors.black54,
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              top: 12,
                              bottom: 12,
                            ),
                            child: Image.asset(
                              'assets/order_login_psw.webp',
                              width: 16,
                              height: 16,
                            ),
                          ),
                          suffixIcon: GestureDetector(
                            onTap: controller.togglePasswordVisibility,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 16,
                                top: 12,
                                bottom: 12,
                              ),
                              child: Image.asset(
                                'assets/order_login_eye.webp',
                                width: 16,
                                height: 16,
                              ),
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                          hintText: '请输入密码',
                          hintStyle: TextStyle(
                            color: Color(0xff666666),
                            fontSize: 12,
                          ),

                          filled: true,
                          fillColor: const Color(0xFFEAF6FF), // 设置背景色
                          border: InputBorder.none, // 去掉边框
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50), // 圆角
                            borderSide: BorderSide.none, // 去掉边框
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50), // 圆角
                            borderSide: BorderSide.none, // 去掉边框
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 登录按钮
                  GestureDetector(
                    onTap: controller.login,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7FA1F6), Color(0xFF9C90FB)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '登录',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
