import 'package:flutter/material.dart';
import 'toast_utils.dart';

/// Toast集成示例
/// 展示如何在现有代码中集成Toast提示
class ToastIntegrationExample {
  
  /// 示例1：在API请求中使用Toast
  static Future<void> apiRequestExample(BuildContext context) async {
    try {
      // 模拟API请求
      await Future.delayed(Duration(seconds: 1));
      
      // 请求成功
      Toast.success(context, '数据加载成功');
    } catch (e) {
      // 请求失败
      Toast.error(context, '网络请求失败，请重试');
    }
  }

  /// 示例2：在表单验证中使用Toast
  static bool validateForm(BuildContext context, String email, String password) {
    if (email.isEmpty) {
      Toast.error(context, '请输入邮箱地址');
      return false;
    }
    
    if (password.isEmpty) {
      Toast.error(context, '请输入密码');
      return false;
    }
    
    if (!email.contains('@')) {
      Toast.error(context, '请输入正确的邮箱格式');
      return false;
    }
    
    if (password.length < 6) {
      Toast.error(context, '密码长度不能少于6位');
      return false;
    }
    
    Toast.success(context, '表单验证通过');
    return true;
  }

  /// 示例3：在用户操作中使用Toast
  static void userActionExample(BuildContext context) {
    // 保存设置
    Toast.success(context, '设置已保存');
    
    // 删除操作
    Toast.success(context, '删除成功');
    
    // 复制操作
    Toast.success(context, '已复制到剪贴板');
  }

  /// 示例4：在错误处理中使用Toast
  static void errorHandlingExample(BuildContext context, dynamic error) {
    if (error.toString().contains('network')) {
      Toast.error(context, '网络连接失败，请检查网络设置');
    } else if (error.toString().contains('timeout')) {
      Toast.error(context, '请求超时，请重试');
    } else if (error.toString().contains('unauthorized')) {
      Toast.error(context, '登录已过期，请重新登录');
    } else {
      Toast.error(context, '操作失败，请稍后重试');
    }
  }

  /// 示例5：在状态更新中使用Toast
  static void statusUpdateExample(BuildContext context, String status) {
    switch (status) {
      case 'pending':
        Toast.success(context, '订单已提交，等待处理');
        break;
      case 'processing':
        Toast.success(context, '订单处理中，请稍候');
        break;
      case 'completed':
        Toast.success(context, '订单已完成');
        break;
      case 'cancelled':
        Toast.error(context, '订单已取消');
        break;
      default:
        Toast.error(context, '未知状态');
    }
  }
}

/// 示例Widget：展示如何在Widget中使用Toast
class ExampleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Toast示例')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => Toast.success(context, '按钮点击成功'),
            child: Text('成功提示'),
          ),
          ElevatedButton(
            onPressed: () => Toast.error(context, '按钮点击失败'),
            child: Text('错误提示'),
          ),
          ElevatedButton(
            onPressed: () => Toast.hide(),
            child: Text('隐藏Toast'),
          ),
        ],
      ),
    );
  }
}
