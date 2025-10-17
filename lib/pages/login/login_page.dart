import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:order_app/pages/login/login_controller.dart';
import 'package:get/get.dart';
import 'package:order_app/utils/l10n_utils.dart';
import 'package:order_app/utils/screen_adaptation.dart';
import 'package:order_app/utils/keyboard_utils.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginController controller = Get.put(LoginController());
  double keyboardHeight = 0.0;
  bool isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
  }

  // 计算需要抬起的距离
  double _calculateLiftDistance(double componentBottom) {
    if (!isKeyboardVisible) return 0;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardTop = screenHeight - keyboardHeight;
    final overlap = componentBottom - keyboardTop;
    // 减少额外间距，只添加10px，并且限制最大抬起距离
    final liftDistance = overlap > 0 ? overlap + 10 : 0;
    // 限制最大抬起距离为键盘高度的60%，避免抬得太高
    final maxLift = keyboardHeight * 0.25;
    return (liftDistance > maxLift ? maxLift : liftDistance).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    // 获取键盘高度
    keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    isKeyboardVisible = keyboardHeight > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false, // 禁用系统的键盘避让
      body: KeyboardUtils.buildDismissiblePage(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 背景图
            Image.asset('assets/order_login_bg.webp', fit: BoxFit.cover),
          Positioned(
            top: 50,
            right: 30,
            child: Obx(() {
              // 访问可观察变量以确保Obx能正确响应变化
              controller.selectedLanguageIndex.value;
              return Container(
                width: 105,
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4), // 圆角
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                            controller.currentLanguageName,
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
                          margin: EdgeInsets.only(top: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              controller.languages.length,
                              (index) {
                                final language = controller.languages[index];
                                return GestureDetector(
                                  onTap: () => controller.selectLanguage(index),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Image.asset(
                                          language['flag']!,
                                          width: 20,
                                          height: 13,
                                        ),
                                        Expanded(
                                          child: Text(
                                            language['name']!,
                                            style: TextStyle(fontSize: 10),
                                            textAlign: TextAlign.right,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      } else {
                        // 不显示时返回空
                        return SizedBox.shrink();
                      }
                    }),
                  ],
                ),
              );
            }),
          ),
          Builder(
            builder: (context) {
              // 计算主要内容区域的位置
              double baseBottom = context.adaptSpacing(190);
              double contentBottom =
                  MediaQuery.of(context).size.height - baseBottom;
              // 更准确的内容高度估算：标题(36+16) + 间距(40) + 账号框(40) + 间距(30) + 密码框(40) + 间距(30) + 按钮(40) = 272px
              double estimatedContentHeight = context.adaptSpacing(220);
              double liftDistance = _calculateLiftDistance(
                contentBottom + estimatedContentHeight,
              );

              return AnimatedPositioned(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                bottom: baseBottom + liftDistance,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    // 点击其他地方时关闭账号下拉列表
                    if (controller.isAccountDropdownExpanded.value) {
                      controller.isAccountDropdownExpanded.value = false;
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.adaptSpacing(70),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.welcome,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: context.adaptFontSize(36),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          context.l10n.serviceApp,
                          style: TextStyle(
                            color: Color(0xFF3D3D3D),
                            fontSize: context.adaptFontSize(16),
                          ),
                        ),
                        SizedBox(height: context.adaptSpacing(40)),
                        // 账号输入框
                        SizedBox(
                          width: context.adaptWidth(253),
                          height: context.adaptHeight(40),
                          child: TextField(
                            controller: controller.usernameController,
                            keyboardType: TextInputType.emailAddress, // 账号键盘
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')), // 只允许英文数字和常用符号
                            ],
                            cursorHeight: 16,
                            cursorColor: Colors.black54,
                            showCursor: true,
                            enableInteractiveSelection: false,
                            decoration: InputDecoration(
                              prefixIcon: Container(
                                width: 48,
                                height: 40,
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Image.asset(
                                    'assets/order_login_login.webp',
                                    width: 16,
                                    height: 16,
                                  ),
                                ),
                              ),
                              suffixIcon: Obx(
                                () => GestureDetector(
                                  onTap: controller.toggleAccountDropdown,
                                  child: Container(
                                    width: 48,
                                    height: 40,
                                    alignment: Alignment.center,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: AnimatedRotation(
                                        turns:
                                            controller
                                                .isAccountDropdownExpanded
                                                .value
                                            ? 0.5
                                            : 0,
                                        duration: Duration(milliseconds: 200),
                                        child: Image.asset(
                                          'assets/order_login_arrowD.webp',
                                          width: 16,
                                          height: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 16,
                              ),
                              hintText: context.l10n.account,
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
                        // 账号下拉列表占位（不显示内容，只占位）
                        SizedBox.shrink(),
                        SizedBox(height: context.adaptSpacing(30)),
                        // 密码输入框（带临时可见功能）
                        Obx(
                          () => SizedBox(
                            width: context.adaptWidth(253),
                            height: context.adaptHeight(40),
                            child: TextField(
                              controller: controller.passwordController,
                              keyboardType: TextInputType.emailAddress, // 邮箱键盘布局
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')), // 只允许英文数字和常用符号
                              ],
                              obscureText: !controller.tempShowPassword.value,
                              cursorHeight: 16,
                              cursorColor: Colors.black54,
                              showCursor: true,
                              enableInteractiveSelection: false,
                              decoration: InputDecoration(
                                prefixIcon: Container(
                                  width: 48,
                                  height: 40,
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Image.asset(
                                      'assets/order_login_psw.webp',
                                      width: 16,
                                      height: 16,
                                    ),
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Image.asset(
                                    'assets/order_login_eye.webp',
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.contain,
                                  ),
                                  onPressed: controller.showPasswordTemporarily,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 16,
                                ),
                                hintText: context.l10n.password,
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
                        SizedBox(height: context.adaptSpacing(30)),
                        // 登录按钮
                        Obx(() => GestureDetector(
                          onTap: controller.isLoggingIn.value ? null : controller.login,
                          child: Container(
                            width: context.adaptWidth(253),
                            height: context.adaptHeight(40),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: controller.isLoggingIn.value 
                                  ? const Color(0xFF7FA1F6).withOpacity(0.6)
                                  : const Color(0xFF7FA1F6),
                            ),
                            alignment: Alignment.center,
                            child: controller.isLoggingIn.value
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: context.adaptWidth(16),
                                        height: context.adaptWidth(16),
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: context.adaptSpacing(8)),
                                      Text(
                                        context.l10n.logining,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: context.adaptFontSize(16),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    context.l10n.login,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: context.adaptFontSize(16),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // 账号下拉列表覆盖层
          Obx(() {
            if (controller.isAccountDropdownExpanded.value &&
                controller.recentAccounts.isNotEmpty) {
              // 计算下拉列表位置
              double baseBottom = context.adaptSpacing(190);
              double contentBottom =
                  MediaQuery.of(context).size.height - baseBottom;
              double estimatedContentHeight = context.adaptSpacing(272);
              double liftDistance = _calculateLiftDistance(
                contentBottom + estimatedContentHeight,
              );

              // 计算账号输入框的位置
              // 从底部开始计算：baseBottom + liftDistance + 按钮高度(40) + 间距(30) + 密码框高度(40) + 间距(30) + 账号框高度(40) + 间距(40) + 标题高度(36+16)
              double accountInputTop =
                  MediaQuery.of(context).size.height -
                  baseBottom -
                  liftDistance -
                  context.adaptSpacing(40) -
                  context.adaptSpacing(40) -
                   context.adaptSpacing(40) -
                  context.adaptSpacing(52);
              double dropdownTop =
                  accountInputTop + context.adaptSpacing(45); // 输入框下方5px

              return Positioned(
                top: dropdownTop,
                left:
                    (MediaQuery.of(context).size.width -
                        context.adaptWidth(240)) /
                    2,
                child: Container(
                  width: context.adaptWidth(240),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: controller.recentAccounts.map((account) {
                      return GestureDetector(
                        onTap: () => controller.selectAccount(account),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFE5E5E5),
                                width: controller.recentAccounts.last == account
                                    ? 0
                                    : 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/order_login_login.webp',
                                width: 16,
                                height: 16,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  account,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }
            return SizedBox.shrink();
          }),
        ],
        ),
      ),
    );
  }
}
