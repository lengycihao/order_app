import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lib_base/lib_base.dart';
import 'package:order_app/utils/websocket_lifecycle_manager.dart';

/// WebSocket生命周期测试页面
class WebSocketLifecycleTestPage extends StatelessWidget {
  const WebSocketLifecycleTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket生命周期测试'),
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
              'WebSocket连接管理测试',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            // 当前状态显示
            _buildStatusCard(),
            const SizedBox(height: 20),
            
            // 页面类型切换按钮
            _buildPageTypeButtons(),
            const SizedBox(height: 20),
            
            // 连接管理按钮
            _buildConnectionButtons(),
            const SizedBox(height: 20),
            
            // 状态信息显示
            _buildStatusInfo(),
          ],
        ),
      ),
    );
  }

  /// 构建状态卡片
  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '当前状态',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Obx(() {
              final status = wsLifecycleManager.getConnectionStatus();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusRow('页面类型', status['current_page_type'] ?? '未设置'),
                  _buildStatusRow('需要WebSocket', status['needs_websocket'] ? '是' : '否'),
                  _buildStatusRow('连接数', '${status['websocket_stats']['total_connections']}'),
                  _buildStatusRow('活跃桌台', status['websocket_stats']['active_table_id'] ?? '无'),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 构建状态行
  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建页面类型切换按钮
  Widget _buildPageTypeButtons() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '页面类型切换',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      wsLifecycleManager.setCurrentPageType(WebSocketLifecycleManager.PAGE_TAKEAWAY);
                      _showSnackBar('已切换到桌台页面（外卖）');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('桌台页面'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      wsLifecycleManager.setCurrentPageType(WebSocketLifecycleManager.PAGE_ORDER);
                      _showSnackBar('已切换到点餐页面');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('点餐页面'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      wsLifecycleManager.setCurrentPageType(WebSocketLifecycleManager.PAGE_TABLE);
                      _showSnackBar('已切换到桌台管理页面');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('桌台管理'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      wsLifecycleManager.setCurrentPageType(WebSocketLifecycleManager.PAGE_OTHER);
                      _showSnackBar('已切换到其他页面');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('其他页面'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建连接管理按钮
  Widget _buildConnectionButtons() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '连接管理',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      wsLifecycleManager.cleanupAllConnections();
                      _showSnackBar('已清理所有WebSocket连接');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('清理所有连接'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final status = wsLifecycleManager.getConnectionStatus();
                      _showSnackBar('连接状态已刷新');
                      logDebug('WebSocket连接状态: $status', tag: 'WebSocketLifecycleTest');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('刷新状态'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建状态信息显示
  Widget _buildStatusInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '使用说明',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '• 桌台页面（外卖）：清理所有WebSocket连接\n'
              '• 点餐页面：保持WebSocket连接，用于实时通信\n'
              '• 桌台管理页面：清理所有WebSocket连接\n'
              '• 其他页面：根据具体需求管理连接\n\n'
              '测试步骤：\n'
              '1. 点击"点餐页面"按钮，观察连接状态\n'
              '2. 点击"桌台页面"按钮，观察连接是否被清理\n'
              '3. 查看控制台日志，确认WebSocket消息不再出现',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示提示信息
  void _showSnackBar(String message) {
    Get.snackbar(
      '操作完成',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
}
