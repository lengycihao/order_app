import 'package:lib_base/lib_base.dart';

/// 网络错误处理测试工具
class ErrorHandlingTest {
  /// 测试401错误处理
  static Future<void> test401Error() async {
    print('🧪 测试401错误处理...');
    
    try {
      // 模拟一个会返回401的请求
      final result = await HttpManagerN.instance.executeGet('/api/waiter/menus');
      
      if (result.isSuccess) {
        print('❌ 401错误没有被正确处理，请求显示为成功');
        print('响应数据: ${result.dataJson}');
      } else {
        print('✅ 401错误被正确处理');
        print('错误码: ${result.code}');
        print('错误消息: ${result.msg}');
      }
    } catch (e) {
      print('❌ 请求抛出异常: $e');
    }
  }

  /// 测试网络错误处理
  static Future<void> testNetworkError() async {
    print('🧪 测试网络错误处理...');
    
    try {
      // 模拟一个网络错误的请求
      final result = await HttpManagerN.instance.executeGet('https://invalid-url-test.com/api/test');
      
      if (result.isSuccess) {
        print('❌ 网络错误没有被正确处理，请求显示为成功');
      } else {
        print('✅ 网络错误被正确处理');
        print('错误码: ${result.code}');
        print('错误消息: ${result.msg}');
      }
    } catch (e) {
      print('❌ 请求抛出异常: $e');
    }
  }

  /// 测试超时错误处理
  static Future<void> testTimeoutError() async {
    print('🧪 测试超时错误处理...');
    
    try {
      // 模拟一个会超时的请求
      final result = await HttpManagerN.instance.executeGet(
        'https://httpbin.org/delay/35', // 35秒延迟，会超时
      );
      
      if (result.isSuccess) {
        print('❌ 超时错误没有被正确处理，请求显示为成功');
      } else {
        print('✅ 超时错误被正确处理');
        print('错误码: ${result.code}');
        print('错误消息: ${result.msg}');
      }
    } catch (e) {
      print('❌ 请求抛出异常: $e');
    }
  }

  /// 运行所有测试
  static Future<void> runAllTests() async {
    print('🚀 开始网络错误处理测试...\n');
    
    await test401Error();
    print('');
    
    await testNetworkError();
    print('');
    
    await testTimeoutError();
    print('');
    
    print('✅ 所有测试完成');
  }
}
