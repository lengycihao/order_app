import 'package:flutter/material.dart';
import '../utils/toast_utils.dart';

/// Toast测试页面
class TestToastPage extends StatelessWidget {
  const TestToastPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toast测试页面'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Toast提示组件测试',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // 错误提示测试
            ElevatedButton(
              onPressed: () {
                Toast.error(context, '这是一个错误提示信息');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('显示错误提示'),
            ),
            const SizedBox(height: 16),
            
            // 成功提示测试
            ElevatedButton(
              onPressed: () {
                Toast.success(context, '操作成功完成！');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('显示成功提示'),
            ),
            const SizedBox(height: 16),
            
            // 长文本测试
            ElevatedButton(
              onPressed: () {
                Toast.error(context, '这是一个很长的错误提示信息，用来测试Toast组件的文本换行和最大宽度限制功能');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('显示长文本错误提示'),
            ),
            const SizedBox(height: 16),
            
            // 成功长文本测试
            ElevatedButton(
              onPressed: () {
                Toast.success(context, '恭喜您！订单提交成功，我们将在30分钟内为您准备美味的餐点，感谢您的耐心等待！');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('显示长文本成功提示'),
            ),
            const SizedBox(height: 16),
            
            // 隐藏Toast测试
            ElevatedButton(
              onPressed: () {
                Toast.hide();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('隐藏当前Toast'),
            ),
            const SizedBox(height: 40),
            
            // 使用说明
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '使用说明：',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• 错误提示：红色背景，显示错误图标\n'
                    '• 成功提示：绿色背景，显示成功图标\n'
                    '• 提示框高度：36px，最大宽度：270px\n'
                    '• 文字大小：12pt，颜色：#333333\n'
                    '• 自动隐藏：2秒后自动消失\n'
                    '• 点击隐藏：点击Toast或背景可手动隐藏',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
