import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/mine/sub_page/change_psw_controller.dart';

class ChangePasswordPage extends StatelessWidget {
  final ChangePasswordController controller = Get.put(
    ChangePasswordController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修改密码')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 新密码输入区域
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 固定提示文字
                const Text(
                  '新密码',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
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
                      // 获得焦点时的下边框样式（可选）
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xff666666), // 聚焦时颜色
                          width: 1.5, // 聚焦时宽度
                        ),
                      ),
                      // 右侧密码显示/隐藏按钮
                      suffixIcon: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Image.asset(
                          controller.showNewPassword.value
                              ? 'assets/order_mine_eyeopen.webp'
                              : 'assets/order_mine_eyeclose.webp',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                        onPressed: () => controller.showNewPassword.value =
                            !controller.showNewPassword.value,
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
                const Text(
                  '确认新密码',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
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
                          color: Color(0xff999999), // 聚焦时颜色
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
                      // 右侧密码显示/隐藏按钮
                      suffixIcon: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Image.asset(
                          controller.showConfirmPassword.value
                              ? 'assets/order_mine_eyeopen.webp'
                              : 'assets/order_mine_eyeclose.webp',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                        onPressed: () => controller.showConfirmPassword.value =
                            !controller.showConfirmPassword.value,
                      ),
                    ),
                    onChanged: (value) =>
                        controller.confirmPassword.value = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),

            // 渐变背景的提交按钮
            Obx(
              () => Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                width: double.infinity,
                height: 50,
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
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        )
                      : const Text(
                          '提交',
                          style: TextStyle(fontSize: 15, color: Colors.white),
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
