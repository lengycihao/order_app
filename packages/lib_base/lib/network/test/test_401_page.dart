import 'package:flutter/material.dart';
import 'package:lib_base/lib_base.dart';

/// 401错误测试页面
/// 用于测试401错误的处理逻辑
class Test401Page extends StatefulWidget {
  const Test401Page({Key? key}) : super(key: key);

  @override
  State<Test401Page> createState() => _Test401PageState();
}

class _Test401PageState extends State<Test401Page> {
  String _testResult = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('401错误处理测试'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '401错误处理测试',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '测试功能：\n'
                      '1. 防重复跳转（3秒冷却时间）\n'
                      '2. 自动显示提示消息\n'
                      '3. 自动跳转到登录页',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // 测试按钮
            ElevatedButton(
              onPressed: _isLoading ? null : _test401Error,
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('测试中...'),
                      ],
                    )
                  : const Text('测试401错误处理'),
            ),
            
            const SizedBox(height: 16),
            
            // 快速连续测试按钮
            ElevatedButton(
              onPressed: _isLoading ? null : _testMultiple401,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('测试防重复机制（连续5次请求）'),
            ),
            
            const SizedBox(height: 16),
            
            // 重置状态按钮
            ElevatedButton(
              onPressed: _resetState,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
              child: const Text('重置401处理状态'),
            ),
            
            const SizedBox(height: 16),
            
            // 查看状态按钮
            ElevatedButton(
              onPressed: _checkStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('查看当前状态'),
            ),
            
            const SizedBox(height: 20),
            
            // 测试结果显示
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '测试结果：',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _testResult.isEmpty ? '尚未开始测试' : _testResult,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 测试单个401错误
  Future<void> _test401Error() async {
    setState(() {
      _isLoading = true;
      _testResult = '开始测试401错误处理...\n';
    });

    try {
      // 模拟一个会返回401的请求
      final result = await HttpManagerN.instance.executeGet('/api/waiter/menus');
      
      setState(() {
        _testResult += '请求完成\n';
        _testResult += '是否成功: ${result.isSuccess}\n';
        _testResult += '状态码: ${result.code}\n';
        _testResult += '消息: ${result.msg}\n';
        _testResult += '时间: ${DateTime.now()}\n\n';
      });
      
    } catch (e) {
      setState(() {
        _testResult += '请求异常: $e\n';
        _testResult += '时间: ${DateTime.now()}\n\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 测试多个401错误（防重复机制）
  Future<void> _testMultiple401() async {
    setState(() {
      _isLoading = true;
      _testResult = '开始测试防重复机制（连续5次401请求）...\n';
    });

    for (int i = 1; i <= 5; i++) {
      setState(() {
        _testResult += '\n--- 第${i}次请求 ---\n';
      });
      
      try {
        final result = await HttpManagerN.instance.executeGet('/api/waiter/menus');
        
        setState(() {
          _testResult += '请求${i}完成: ${result.isSuccess ? "成功" : "失败"}\n';
          _testResult += '状态码: ${result.code}\n';
          if (!result.isSuccess) {
            _testResult += '错误消息: ${result.msg}\n';
          }
        });
        
      } catch (e) {
        setState(() {
          _testResult += '请求${i}异常: $e\n';
        });
      }
      
      // 短暂延迟
      await Future.delayed(const Duration(milliseconds: 200));
    }

    setState(() {
      _testResult += '\n✅ 防重复测试完成\n';
      _testResult += '预期结果：只有第一次请求会触发401处理逻辑\n';
      _testResult += '时间: ${DateTime.now()}\n\n';
      _isLoading = false;
    });
  }

  /// 重置401处理状态
  void _resetState() {
    UnauthorizedHandler.instance.resetState();
    setState(() {
      _testResult += '🔄 已重置401处理状态\n';
      _testResult += '时间: ${DateTime.now()}\n\n';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('401处理状态已重置')),
    );
  }

  /// 查看当前状态
  void _checkStatus() {
    final status = UnauthorizedHandler.instance.getStatus();
    setState(() {
      _testResult += '📊 当前状态信息：\n';
      _testResult += '正在处理: ${status['isHandling']}\n';
      _testResult += '最后处理时间: ${status['lastHandleTime'] ?? "无"}\n';
      _testResult += '冷却时间: ${status['cooldownDuration']}秒\n';
      _testResult += '登录路由: ${status['loginRoute']}\n';
      _testResult += '查询时间: ${DateTime.now()}\n\n';
    });
  }
}
