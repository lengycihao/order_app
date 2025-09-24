import 'package:flutter/material.dart';
import '../utils/toast_utils.dart';

/// Toast功能测试页面
class TestToastPage extends StatefulWidget {
  const TestToastPage({Key? key}) : super(key: key);

  @override
  State<TestToastPage> createState() => _TestToastPageState();
}

class _TestToastPageState extends State<TestToastPage> {
  int _successCount = 0;
  int _errorCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toast功能测试'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 统计信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Toast统计',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '$_successCount',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Text('成功提示'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '$_errorCount',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const Text('错误提示'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // 基本功能测试
            Text(
              '基本功能测试',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _successCount++;
                });
                Toast.success(context, '操作成功！这是第$_successCount个成功提示');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('显示成功提示'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorCount++;
                });
                Toast.error(context, '操作失败！这是第$_errorCount个错误提示');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('显示错误提示'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () {
                Toast.info(context, '这是一个信息提示');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('显示信息提示'),
            ),
            
            const SizedBox(height: 20),
            
            // 队列功能测试
            Text(
              '队列功能测试',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () {
                // 快速连续显示多个Toast，测试队列功能
                for (int i = 1; i <= 5; i++) {
                  Future.delayed(Duration(milliseconds: i * 100), () {
                    Toast.success(context, '队列测试 $i/5');
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('测试Toast队列（5个）'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () {
                // 混合显示成功和错误Toast
                Toast.success(context, '第一个成功提示');
                Future.delayed(const Duration(milliseconds: 200), () {
                  Toast.error(context, '第二个错误提示');
                });
                Future.delayed(const Duration(milliseconds: 400), () {
                  Toast.success(context, '第三个成功提示');
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('测试混合队列'),
            ),
            
            const SizedBox(height: 20),
            
            // 控制功能测试
            Text(
              '控制功能测试',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Toast.hide();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('隐藏Toast'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Toast.clearQueue();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('清除队列'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 自定义持续时间测试
            Text(
              '自定义持续时间测试',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () {
                Toast.success(
                  context, 
                  '这个Toast会显示5秒',
                  duration: const Duration(seconds: 5),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('显示5秒Toast'),
            ),
            
            const SizedBox(height: 20),
            
            // 全局Toast测试
            Text(
              '全局Toast测试',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () {
                // 设置全局Context
                GlobalToast.setContext(context);
                GlobalToast.success('这是全局成功提示');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('全局成功提示'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () {
                GlobalToast.error('这是全局错误提示');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('全局错误提示'),
            ),
          ],
        ),
      ),
    );
  }
}