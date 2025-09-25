import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/mine/sub_page/change_psw_controller.dart';
import 'package:order_app/pages/order/components/restaurant_loading_widget.dart';
import 'package:order_app/utils/keyboard_utils.dart';

class ChangePasswordPage extends StatelessWidget {
  final ChangePasswordController controller = Get.put(
    ChangePasswordController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('修改密码', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: KeyboardUtils.buildDismissiblePage(
        child: Stack(
          children: [
            // 主要内容区域
            Padding(
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
                      '新密码',
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
                      '任意8位字符',
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
                    obscureText: !controller.showNewPassword.value,
                    decoration: InputDecoration(
                      hintText: '请输入新密码',
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
                          // 点击时直接显示明文，不改变状态
                          controller.showNewPassword.value = true;
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
                      '确认新密码',
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
                    obscureText: !controller.showConfirmPassword.value,
                    decoration: InputDecoration(
                      hintText: '请再次输入密码',
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
                          // 点击时直接显示明文，不改变状态
                          controller.showConfirmPassword.value = true;
                        },
                      ),
                    ),
                    onChanged: (value) =>
                        controller.confirmPassword.value = value,
                  ),
                ),
              ],
            ),
            ],
            ),
            ),
            // 固定在底部的提交按钮
            Positioned(
              bottom: 190,
              left: 0,
              right: 0,
              child: Center(
                child: Obx(
                  () => Container(
                    width: 253,
                    height: 40,
                decoration: BoxDecoration(
                  // 从#7FA1F6到#9C90FB的渐变
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7FA1F6), Color(0xFF9C90FB)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(40), // 按钮圆角
                ),
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.submit,
                  // 关键：去除按钮默认背景，使用容器的渐变背景
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0, // 去除阴影
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // 与容器圆角一致
                    ),
                  ),
                  child: controller.isLoading.value
                      ? RestaurantLoadingWidget(
                          size: 20,
                          color: Colors.white,
                        )
                      : const Text(
                          '提交',
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
