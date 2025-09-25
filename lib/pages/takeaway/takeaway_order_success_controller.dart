import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:lib_base/lib_base.dart';
import 'package:lib_domain/entrity/takeout/takeout_time_option_model.dart';
import 'package:order_app/utils/toast_utils.dart';

class TakeawayOrderSuccessController extends GetxController {
  // 桌台ID
  final RxInt tableId = 0.obs;
  
  // 备注输入控制器
  final TextEditingController remarkController = TextEditingController();
  
  // 时间选项列表（从API获取 + 其他时间选项）
  final RxList<TakeoutTimeOptionItem> timeOptions = <TakeoutTimeOptionItem>[].obs;
  
  // 选中的时间索引
  final RxInt selectedTimeIndex = 0.obs;
  
  // 选中的时间文本
  final RxString selectedTimeText = ''.obs;
  
  // 选中的时间（DateTime）
  final Rx<DateTime?> selectedDateTime = Rx<DateTime?>(null);
  
  // 自定义时间（当选择其他时间时）
  final Rx<DateTime?> customDateTime = Rx<DateTime?>(null);
  
  // 加载状态
  final RxBool isLoading = false.obs;
  
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
    // 加载时间选项
    _loadTimeOptions();
  }
  
  @override
  void onClose() {
    remarkController.dispose();
    super.onClose();
  }

  // 加载时间选项
  Future<void> _loadTimeOptions() async {
    try {
      isLoading.value = true;
      
      final result = await HttpManagerN.instance.executeGet('/api/waiter/setting/takeout_time_option');
      
      if (result.isSuccess) {
        final model = TakeoutTimeOptionModel.fromJson(result.getDataJson());
        timeOptions.clear();
        timeOptions.addAll(model.options);
        
        // 添加"其他时间"选项
        timeOptions.add(TakeoutTimeOptionItem(
          value: -1,
          label: '其他时间',
        ));
        
        // 默认选择第一个选项
        if (timeOptions.isNotEmpty) {
          selectedTimeIndex.value = 0;
          _updateSelectedTime(0);
        }
      } else {
        ToastUtils.showError(Get.context!, '加载时间选项失败');
      }
    } catch (e) {
      ToastUtils.showError(Get.context!, '加载时间选项失败');
    } finally {
      isLoading.value = false;
    }
  }

  // 选择时间选项
  void selectTimeOption(int index) {
    if (index < 0 || index >= timeOptions.length) return;
    
    selectedTimeIndex.value = index;
    
    // 如果选择的是"其他时间"
    if (timeOptions[index].value == -1) {
      showTimePicker();
    } else {
      _updateSelectedTime(index);
    }
  }

  // 更新选中的时间
  void _updateSelectedTime(int index) {
    if (index < 0 || index >= timeOptions.length) return;
    
    final option = timeOptions[index];
    if (option.value == -1) {
      // 其他时间选项
      if (customDateTime.value != null) {
        selectedTimeText.value = _formatTime(customDateTime.value!);
        selectedDateTime.value = customDateTime.value;
      }
    } else {
      // 预设时间选项
      selectedTimeText.value = option.label;
      // 使用时间戳创建DateTime
      selectedDateTime.value = DateTime.fromMillisecondsSinceEpoch(option.value * 1000);
    }
  }

  // 显示时间选择器
  void showTimePicker() async {
    final now = DateTime.now();
    final initialTime = TimeOfDay.fromDateTime(customDateTime.value ?? now);
    
    final selectedTime = await Get.dialog<TimeOfDay>(
      TimePickerDialog(
        initialTime: initialTime,
        helpText: '选择取餐时间',
        cancelText: '取消',
        confirmText: '确认',
      ),
    );
    
    if (selectedTime != null) {
      // 创建今天的指定时间
      final today = DateTime.now();
      final selectedDateTime = DateTime(
        today.year,
        today.month,
        today.day,
        selectedTime.hour,
        selectedTime.minute,
        0, // 秒数设为00
      );
      
      // 如果选择的时间已经过去，则设为明天
      final finalDateTime = selectedDateTime.isBefore(DateTime.now()) 
          ? selectedDateTime.add(const Duration(days: 1))
          : selectedDateTime;
      
      customDateTime.value = finalDateTime;
      // 更新显示的时间文本
      selectedTimeText.value = _formatTime(finalDateTime);
      this.selectedDateTime.value = finalDateTime;
    } else {
      // 如果用户取消了时间选择，重置为第一个选项
      if (timeOptions.isNotEmpty) {
        selectedTimeIndex.value = 0;
        _updateSelectedTime(0);
      }
    }
  }


  // 格式化时间显示
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    if (dateOnly == today) {
      return '今天 $timeStr';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return '明天 $timeStr';
    } else {
      return '${dateTime.month}月${dateTime.day}日 $timeStr';
    }
  }

  // 设置桌台ID
  void setTableId(int id) {
    tableId.value = id;
  }
  
  // 获取当前选中的时间文本（供页面显示）
  String get currentSelectedTimeText => selectedTimeText.value;
  
  // 是否选择了其他时间选项
  bool get isOtherTimeSelected => selectedTimeIndex.value < timeOptions.length && 
      timeOptions[selectedTimeIndex.value].value == -1;

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
    
    if (selectedDateTime.value == null) {
      ToastUtils.showError(Get.context!, '请选择取餐时间');
      return;
    }
    
    try {
      isSubmitting.value = true;
      
      // 格式化时间为 yyyy-MM-dd HH:mm:ss
      final formattedTime = '${selectedDateTime.value!.year.toString().padLeft(4, '0')}-'
          '${selectedDateTime.value!.month.toString().padLeft(2, '0')}-'
          '${selectedDateTime.value!.day.toString().padLeft(2, '0')} '
          '${selectedDateTime.value!.hour.toString().padLeft(2, '0')}:'
          '${selectedDateTime.value!.minute.toString().padLeft(2, '0')}:00';
      
      final params = {
        'table_id': tableId.value,
        'remark': remarkController.text.trim(),
        'estimate_pickup_time': formattedTime,
      };
      
      final result = await HttpManagerN.instance.executePost(
        '/api/waiter/cart/submit_takeout_order',
        jsonParam: params,
      );
      
      if (result.isSuccess) {
        ToastUtils.showSuccess(Get.context!, '订单提交成功');
        // 跳转到订单成功页面或返回上一页
        Get.back();
      } else {
        ToastUtils.showError(Get.context!, '订单提交失败');
      }
    } catch (e) {
      ToastUtils.showError(Get.context!, '订单提交失败');
    } finally {
      isSubmitting.value = false;
    }
  }
}
