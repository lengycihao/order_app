import 'package:flutter/material.dart';
import 'package:order_app/components/skeleton_widget.dart';

/// 骨架图测试页面
class SkeletonTestPage extends StatefulWidget {
  const SkeletonTestPage({Key? key}) : super(key: key);

  @override
  State<SkeletonTestPage> createState() => _SkeletonTestPageState();
}

class _SkeletonTestPageState extends State<SkeletonTestPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 3秒后停止加载
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('骨架图测试'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // 测试按钮
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = !_isLoading;
                });
              },
              child: Text(_isLoading ? '停止加载' : '开始加载'),
            ),
          ),
          
          // 骨架图测试
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 点餐页面骨架图
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('点餐页面骨架图', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        SkeletonWidget(
                          isLoading: _isLoading,
                          child: const OrderPageSkeleton(),
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(),
                  
                  // 外卖页面骨架图
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('外卖页面骨架图', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        SkeletonWidget(
                          isLoading: _isLoading,
                          child: const TakeawayPageSkeleton(),
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(),
                  
                  // 桌台页面骨架图
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('桌台页面骨架图', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        SkeletonWidget(
                          isLoading: _isLoading,
                          child: const TablePageSkeleton(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
