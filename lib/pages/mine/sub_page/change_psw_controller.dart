//  import 'package:get/get.dart';

// class ChangePasswordController extends GetxController {
//   var newPassword = ''.obs;
//   var confirmPassword = ''.obs;
//   var isLoading = false.obs;

//   void submit() {
//     if (newPassword.value.isEmpty || confirmPassword.value.isEmpty) {
//       Get.snackbar('提示', '请输入完整信息');
//       return;
//     }
//     if (newPassword.value != confirmPassword.value) {
//       Get.snackbar('提示', '两次输入的密码不一致');
//       return;
//     }
//     isLoading.value = true;
//     // 模拟网络请求
//     Future.delayed(Duration(seconds: 2), () {
//       isLoading.value = false;
//       Get.snackbar('成功', '密码修改成功');
//       // 可以在这里添加跳转逻辑
//     });
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// 控制器代码保持不变
class ChangePasswordController extends GetxController {
  final RxString newPassword = ''.obs;
  final RxString confirmPassword = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool showNewPassword = false.obs;
  final RxBool showConfirmPassword = false.obs;

  void submit() {
    // 提交逻辑...
    isLoading.value = true;
    Future.delayed(const Duration(seconds: 2), () {
      isLoading.value = false;
      // 验证逻辑示例
      if (newPassword.value.isEmpty) {
        Get.showSnackbar(
          const GetSnackBar(message: '请输入新密码', duration: Duration(seconds: 2)),
        );
        return;
      }
      if (newPassword.value != confirmPassword.value) {
        Get.showSnackbar(
          const GetSnackBar(
            message: '两次输入的密码不一致',
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      Get.back(result: true);
    });
  }
}
