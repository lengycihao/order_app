import 'package:flutter/material.dart';
import 'package:lib_base/utils/websocket_util.dart';
import 'package:order_app/service/service_locator.dart';
import 'package:lib_base/network/interceptor/auth_service.dart';
import 'package:dio/dio.dart';

/// WebSocket连接调试页面
class WebSocketDebugPage extends StatefulWidget {
  const WebSocketDebugPage({Key? key}) : super(key: key);

  @override
  State<WebSocketDebugPage> createState() => _WebSocketDebugPageState();
}

class _WebSocketDebugPageState extends State<WebSocketDebugPage> {
  final TextEditingController _serverUrlController = TextEditingController(
    text: 'ws://129.204.154.113:8050/api/waiter/ws',
  );
  final TextEditingController _tableIdController = TextEditingController(
    text: 'test_table_001',
  );
  
  String _connectionStatus = '未连接';
  String _lastError = '';
  List<String> _logs = [];
  
  WebSocketUtil? _webSocketUtil;

  @override
  void initState() {
    super.initState();
    _addLog('🔧 WebSocket调试工具已初始化');
  }

  @override
  void dispose() {
    _webSocketUtil?.disconnect();
    _serverUrlController.dispose();
    _tableIdController.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} $message');
      if (_logs.length > 50) {
        _logs.removeAt(0);
      }
    });
  }

  Future<void> _testConnection() async {
    _addLog('🔌 开始测试WebSocket连接...');
    setState(() {
      _connectionStatus = '连接中...';
      _lastError = '';
    });

    try {
      // 获取用户token
      String? token;
      try {
        final authService = getIt<AuthService>();
        token = authService.getCurrentToken();
        _addLog('🔑 获取到用户token: ${token?.substring(0, 20) ?? 'null'}...');
      } catch (e) {
        _addLog('⚠️ 获取用户token失败: $e');
        token = null;
      }

      // 创建WebSocket配置
      final config = WebSocketConfig(
        serverUrl: _serverUrlController.text,
        tableId: _tableIdController.text,
        token: token,
      );

      _addLog('📋 WebSocket配置: ${config.toString()}');
      _addLog('🌐 连接URL: ${config.buildFullUrl()}');

      // 创建WebSocket工具实例
      _webSocketUtil = WebSocketUtil();
      
      // 添加连接状态监听
      _webSocketUtil!.addConnectionStateListener((state) {
        _addLog('🔌 连接状态变化: $state');
        setState(() {
          _connectionStatus = state.toString().split('.').last;
        });
      });

      // 添加消息监听
      _webSocketUtil!.addRawMessageListener((message) {
        _addLog('📨 收到消息: $message');
      });

      // 尝试连接
      final success = await _webSocketUtil!.initialize(config);
      
      if (success) {
        _addLog('✅ WebSocket连接成功！');
        setState(() {
          _connectionStatus = '已连接';
        });
      } else {
        _addLog('❌ WebSocket连接失败');
        setState(() {
          _connectionStatus = '连接失败';
        });
      }

    } catch (e) {
      _addLog('❌ 连接异常: $e');
      setState(() {
        _connectionStatus = '连接异常';
        _lastError = e.toString();
      });
    }
  }

  Future<void> _testNetworkConnectivity() async {
    _addLog('🌐 开始测试网络连接...');
    
    try {
      // 测试HTTP连接
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 5);
      dio.options.receiveTimeout = const Duration(seconds: 5);
      
      final response = await dio.get('http://129.204.154.113:8050/api/health');
      
      _addLog('✅ HTTP连接成功: ${response.statusCode}');
    } catch (e) {
      _addLog('❌ HTTP连接失败: $e');
    }
  }

  Future<void> _sendTestMessage() async {
    if (_webSocketUtil?.isConnected != true) {
      _addLog('⚠️ WebSocket未连接，无法发送消息');
      return;
    }

    final testMessage = {
      'id': 'test_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'test',
      'data': {'message': 'Hello WebSocket Server!'},
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };

    _addLog('📤 发送测试消息: $testMessage');
    final success = await _webSocketUtil!.sendRawMessage(testMessage);
    
    if (success) {
      _addLog('✅ 消息发送成功');
    } else {
      _addLog('❌ 消息发送失败');
    }
  }

  void _disconnect() {
    _webSocketUtil?.disconnect();
    _addLog('🔌 主动断开连接');
    setState(() {
      _connectionStatus = '已断开';
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket连接调试'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 配置区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WebSocket配置',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _serverUrlController,
                      decoration: const InputDecoration(
                        labelText: '服务器地址',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tableIdController,
                      decoration: const InputDecoration(
                        labelText: '桌台ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 状态区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '连接状态',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('状态: $_connectionStatus'),
                    if (_lastError.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('错误: $_lastError', style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 操作按钮
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _testConnection,
                  child: const Text('测试连接'),
                ),
                ElevatedButton(
                  onPressed: _testNetworkConnectivity,
                  child: const Text('测试网络'),
                ),
                ElevatedButton(
                  onPressed: _sendTestMessage,
                  child: const Text('发送消息'),
                ),
                ElevatedButton(
                  onPressed: _disconnect,
                  child: const Text('断开连接'),
                ),
                ElevatedButton(
                  onPressed: _clearLogs,
                  child: const Text('清空日志'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 日志区域
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '调试日志',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListView.builder(
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  _logs[index],
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
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
}
