import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/mine/sub_page/change_psw_controller.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';
import 'package:order_app/utils/l10n_utils.dart';

class ChangePasswordPage extends StatelessWidget {
  final ChangePasswordController controller = Get.put(
    ChangePasswordController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // 防止页面跟随键盘调整大小
      appBar: AppBar(
        title: Text(context.l10n.changePassword, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 主要内容区域 - 可滚动
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 新密码输入区域
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 固定提示文字
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.newPassword,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xff666666),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '*',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xffFF0000),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            context.l10n.anyCharactersOf8OrMore,
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xff999999),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 新密码输入框（仅下边框）
                      Obx(
                        () => TextField(
                          obscureText: !controller.tempShowNewPassword.value,
                          decoration: InputDecoration(
                            hintText: context.l10n.pleaseEnterNewPassword,
                            hintStyle: const TextStyle(color: Colors.grey),
                            // 移除默认内边距，避免下划线过长
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            // 仅显示下边框
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xff999999), // 边框颜色
                                width: 1.0, // 边框宽度
                              ),
                            ),
                            // 未聚焦时的下边框
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xff999999), // 边框颜色
                                width: 1.0, // 边框宽度
                              ),
                            ),
                            // 获得焦点时的下边框样式（可选）
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xff666666), // 聚焦时颜色
                                width: 1.5, // 聚焦时宽度
                              ),
                            ),
                            // 右侧密码显示按钮（固定显示明文）
                            suffixIcon: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Image.asset(
                                'assets/order_login_eye.webp',
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                              ),
                              onPressed: () {
                                // 点击时临时显示明文1秒钟
                                controller.showNewPasswordTemporarily();
                              },
                            ),
                          ),
                          onChanged: (value) => controller.newPassword.value = value,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 确认密码输入区域
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 固定提示文字
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.confirmPassword,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xff666666),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '*',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xffFF0000),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 确认密码输入框（仅下边框）
                      Obx(
                        () => TextField(
                          obscureText: !controller.tempShowConfirmPassword.value,
                          decoration: InputDecoration(
                            hintText: context.l10n.pleaseReenterNewPassword,
                            hintStyle: const TextStyle(color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            // 仅显示下边框
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xff999999), // 边框颜色
                                width: 1.0,
                              ),
                            ),
                            // 未聚焦时的下边框
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xff999999), // 边框颜色
                                width: 1.0,
                              ),
                            ),
                            // 获得焦点时的下边框样式（可选）
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xff666666), // 聚焦时颜色
                                width: 1.5,
                              ),
                            ),
                            // 右侧密码显示按钮（固定显示明文）
                            suffixIcon: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Image.asset(
                                'assets/order_login_eye.webp',
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                              ),
                              onPressed: () {
                                // 点击时临时显示明文1秒钟
                                controller.showConfirmPasswordTemporarily();
                              },
                            ),
                          ),
                          onChanged: (value) =>
                              controller.confirmPassword.value = value,
                        ),
                      ),
                    ],
                  ),
                  // 添加底部间距，确保内容不会被按钮遮挡
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // 固定在底部的提交按钮 - 参考外卖订单成功页面的实现
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(61, 0, 61, 203),
            child: SafeArea(
              child: Obx(
                () => Container(
                  width: double.infinity,
                    height: 40,
                  decoration: BoxDecoration(
                    // 从#7FA1F6到#9C90FB的渐变
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7FA1F6), Color(0xFF9C90FB)],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                    borderRadius: BorderRadius.circular(25), // 按钮圆角
                  ),
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.submit,
                    // 关键：去除按钮默认背景，使用容器的渐变背景
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0, // 去除阴影
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25), // 与容器圆角一致
                      ),
                    ),
                    child: controller.isLoading.value
                        ? RestaurantLoadingWidget(
                            size: 20,
                            color: Colors.white,
                          )
                        :   Text(
                            context.l10n.submit,
                            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
