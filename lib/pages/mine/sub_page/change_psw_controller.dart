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

import 'package:get/get.dart';
import 'package:order_app/service/service_locator.dart';
import 'package:order_app/pages/login/login_page.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:lib_base/network/interceptor/auth_service.dart';

class ChangePasswordController extends GetxController {
  final RxString newPassword = ''.obs;
  final RxString confirmPassword = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool showNewPassword = false.obs;
  final RxBool showConfirmPassword = false.obs;

  final AuthService _authService = getIt<AuthService>();

  void submit() async {
    // 验证输入
    if (newPassword.value.isEmpty) {
      GlobalToast.error('请输入新密码');
      return;
    }
    
    if (confirmPassword.value.isEmpty) {
      GlobalToast.error('请确认新密码');
      return;
    }
    
    if (newPassword.value != confirmPassword.value) {
      GlobalToast.error('两次输入的密码不一致');
      return;
    }
    
    if (newPassword.value.length < 6) {
      GlobalToast.error('密码长度不能少于6位');
      return;
    }

    isLoading.value = true;
    
    try {
      // 调用修改密码接口
      final result = await _authService.changePassword(
        newPassword: newPassword.value,
      );
      
      if (result.isSuccess) {
        GlobalToast.success('密码修改成功');
        
        // 清除登录信息缓存并跳转到登录页面
        await _authService.logout();
        
        // 跳转到登录页面
        Get.offAll(() => LoginPage());
      } else {
        GlobalToast.error(result.msg ?? '密码修改失败');
      }
    } catch (e) {
      GlobalToast.error('密码修改失败: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
