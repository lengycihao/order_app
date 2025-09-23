import 'package:flutter/material.dart';

/// 桌台列表数据加载失败占位图
/// 符合餐饮点餐类型的UI设计
class TableErrorPlaceholder extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? errorMessage;

  const TableErrorPlaceholder({
    Key? key,
    this.onRetry,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 简化的错误图标
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          
          SizedBox(height: 16),
          
          // 错误标题
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 8),
          
          // 错误描述
          Text(
            errorMessage ?? '网络连接异常，请重试',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 24),
          
          // 重试按钮
          if (onRetry != null)
            ElevatedButton(
              onPressed: onRetry,
              child: Text('重新加载'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xffFF9027),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
        ],
      ),
    );
  }

}

/// 空数据占位图
/// 当没有桌台数据时显示
class TableEmptyPlaceholder extends StatelessWidget {
  final VoidCallback? onRefresh;

  const TableEmptyPlaceholder({
    Key? key,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          
          // 空数据标题
          Text(
            '暂无桌台',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 8),
          
          // 空数据描述
          Text(
            '当前区域暂无桌台信息',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 24),
          
          // 刷新按钮
          if (onRefresh != null)
            OutlinedButton(
              onPressed: onRefresh,
              child: Text('刷新'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xffFF9027),
                side: BorderSide(
                  color: Color(0xffFF9027),
                  width: 1,
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
