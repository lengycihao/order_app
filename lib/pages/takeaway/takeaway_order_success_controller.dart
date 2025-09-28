import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:lib_base/lib_base.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:order_app/pages/nav/screen_nav_page.dart';

class TakeawayOrderSuccessController extends GetxController {
  // 桌台ID
  final RxInt tableId = 0.obs;
  
  // 备注输入控制器
  final TextEditingController remarkController = TextEditingController();
  
  // 提交状态
  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 获取传递的桌台ID
    if (Get.arguments != null && Get.arguments is Map) {
      final args = Get.arguments as Map;
      if (args['tableId'] != null) {
        tableId.value = args['tableId'] as int;
      }
    }
  }
  
  @override
  void onClose() {
    remarkController.dispose();
    super.onClose();
  }

  // 设置桌台ID
  void setTableId(int id) {
    tableId.value = id;
  }

  // 确认订单（供页面底部确认按钮调用）
  Future<void> confirmOrder() async {
    await submitTakeoutOrder();
  }

  // 提交外卖订单
  Future<void> submitTakeoutOrder() async {
    if (isSubmitting.value) return;
    
    // 验证必填项
    if (tableId.value <= 0) {
      ToastUtils.showError(Get.context!, '桌台ID不能为空');
      return;
    }
    
    try {
      isSubmitting.value = true;
      
      final params = {
        'table_id': tableId.value,
        'remark': remarkController.text.trim(),
      };
      
      final result = await HttpManagerN.instance.executePost(
        '/api/waiter/cart/submit_takeout_order',
        jsonParam: params,
      );
      
      if (result.isSuccess) {
        ToastUtils.showSuccess(Get.context!, '订单提交成功');
        // 跳转到主页面并切换到外卖标签页
        Get.offAll(() => ScreenNavPage(initialIndex: 1));
      } else {
        // 显示服务器返回的真实错误信息
        final errorMessage = result.msg ?? '订单提交失败';
        ToastUtils.showError(Get.context!, errorMessage);
      }
    } catch (e) {
      // 显示具体的异常信息
      ToastUtils.showError(Get.context!, '网络错误: ${e.toString()}');
    } finally {
      isSubmitting.value = false;
    }
  }
}
