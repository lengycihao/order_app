import 'package:flutter/material.dart';
import 'error_notification_manager.dart';

/// 错误提示防重复功能测试
class ErrorNotificationTest {
  static void runTest() {
    final manager = ErrorNotificationManager();
    
    debugPrint('🧪 开始测试错误提示防重复功能...');
    
    // 测试1: 相同错误消息不重复显示
    debugPrint('📝 测试1: 相同错误消息防重复');
    manager.showErrorNotification(
      title: '测试错误',
      message: '这是一个测试错误消息',
      errorCode: 'test_error_1',
    );
    
    // 立即再次显示相同错误（应该被阻止）
    manager.showErrorNotification(
      title: '测试错误',
      message: '这是一个测试错误消息',
      errorCode: 'test_error_1',
    );
    
    // 测试2: 不同错误代码可以显示
    debugPrint('📝 测试2: 不同错误代码可以显示');
    manager.showErrorNotification(
      title: '测试错误',
      message: '这是一个测试错误消息',
      errorCode: 'test_error_2',
    );
    
    // 测试3: 成功消息防重复
    debugPrint('📝 测试3: 成功消息防重复');
    manager.showSuccessNotification(
      title: '测试成功',
      message: '这是一个测试成功消息',
      successCode: 'test_success_1',
    );
    
    // 立即再次显示相同成功消息（应该被阻止）
    manager.showSuccessNotification(
      title: '测试成功',
      message: '这是一个测试成功消息',
      successCode: 'test_success_1',
    );
    
    // 测试4: 警告消息防重复
    debugPrint('📝 测试4: 警告消息防重复');
    manager.showWarningNotification(
      title: '测试警告',
      message: '这是一个测试警告消息',
      warningCode: 'test_warning_1',
    );
    
    // 立即再次显示相同警告消息（应该被阻止）
    manager.showWarningNotification(
      title: '测试警告',
      message: '这是一个测试警告消息',
      warningCode: 'test_warning_1',
    );
    
    // 测试5: 强制显示（忽略防重复）
    debugPrint('📝 测试5: 强制显示功能');
    manager.forceShowNotification(
      title: '强制显示',
      message: '这是强制显示的消息',
    );
    
    // 再次强制显示相同消息（应该显示）
    manager.forceShowNotification(
      title: '强制显示',
      message: '这是强制显示的消息',
    );
    
    debugPrint('✅ 错误提示防重复功能测试完成');
    debugPrint('📊 预期结果: 只有6条消息应该显示，重复的消息被阻止');
  }
  
  /// 清理测试数据
  static void cleanup() {
    final manager = ErrorNotificationManager();
    manager.clearAllRecords();
    debugPrint('🧹 测试数据已清理');
  }
}
