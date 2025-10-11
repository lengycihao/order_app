
import 'package:get/get.dart';
import 'package:order_app/service/service_locator.dart';
import 'package:order_app/pages/login/login_page.dart';
import 'package:order_app/utils/l10n_utils.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:lib_base/network/interceptor/auth_service.dart';

class ChangePasswordController extends GetxController {
  final RxString newPassword = ''.obs;
  final RxString confirmPassword = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool showNewPassword = false.obs;
  final RxBool showConfirmPassword = false.obs;
  
  // 临时显示明文的状态
  final RxBool tempShowNewPassword = false.obs;
  final RxBool tempShowConfirmPassword = false.obs;

  final AuthService _authService = getIt<AuthService>();

  // 临时显示新密码明文1秒钟
  void showNewPasswordTemporarily() {
    tempShowNewPassword.value = true;
    Future.delayed(Duration(seconds: 1), () {
      tempShowNewPassword.value = false;
    });
  }

  // 临时显示确认密码明文1秒钟
  void showConfirmPasswordTemporarily() {
    tempShowConfirmPassword.value = true;
    Future.delayed(Duration(seconds: 1), () {
      tempShowConfirmPassword.value = false;
    });
  }

  void submit() async {
    // 验证输入
    if (newPassword.value.isEmpty) {
      GlobalToast.error(Get.context!.l10n.pleaseEnterNewPassword);
      return;
    }
    
    if (confirmPassword.value.isEmpty) {
      GlobalToast.error(Get.context!.l10n.pleaseReenterNewPassword);
      return;
    }
    
    if (newPassword.value != confirmPassword.value) {
      GlobalToast.error(Get.context!.l10n.twoPasswordsDoNotMatch);
      return;
    }
    
    if (newPassword.value.length < 8) {
      GlobalToast.error(Get.context!.l10n.passwordLengthCannotBeLessThan8);
      return;
    }

    isLoading.value = true;
    
    try {
      // 调用修改密码接口
      final result = await _authService.changePassword(
        newPassword: newPassword.value,
      );
      
      if (result.isSuccess) {
        GlobalToast.success(Get.context!.l10n.passwordUpdatedSuccessfully);
        
        // 清除登录信息缓存并跳转到登录页面
        await _authService.logout();
        
        // 跳转到登录页面
        Get.offAll(() => LoginPage());
      } else {
        GlobalToast.error(result.msg ?? Get.context!.l10n.passwordChangeFailedPleaseRetry);
      }
    } catch (e) {
      GlobalToast.error(Get.context!.l10n.passwordChangeFailedPleaseRetry);
    } finally {
      isLoading.value = false;
    }
  }
}
