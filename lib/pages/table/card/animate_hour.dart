import 'package:flutter/material.dart';
import 'dart:math';
import '../../../utils/time_formatter.dart';
import '../utils/table_time_manager.dart';

class AnimatedHourglass extends StatefulWidget {
  final num initialDuration; // 初始时间戳（秒）
  final String? tableId; // 桌台ID，用于性能优化
  
  const AnimatedHourglass({
    super.key, 
    required this.initialDuration,
    this.tableId,
  });

  @override
  State<AnimatedHourglass> createState() => _AnimatedHourglassState();
}

class _AnimatedHourglassState extends State<AnimatedHourglass>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  double _currentAngle = 0.0;
  
  // 实时时间相关
  late int _currentDuration;
  final _timeManager = TableTimeManager();
  late String _tableKey;

  @override
  void initState() {
    super.initState();
    
    // 初始化时间
    _currentDuration = widget.initialDuration.toInt();
    _tableKey = widget.tableId ?? 'table_${widget.hashCode}';

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800), // 半圈旋转时间
    );

    _rotation = Tween<double>(
      begin: 0,
      end: pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _startAnimation();
    _registerToTimeManager();
  }

  void _startAnimation() async {
    while (mounted) {
      await _controller.forward();
      _currentAngle += pi; // 累加角度，保证一直顺时针
      _controller.value = 0; // 重置动画
      setState(() {}); // 更新旋转角度
      await Future.delayed(Duration(milliseconds: 1600)); // 半圈停顿
    }
  }

  void _registerToTimeManager() {
    _timeManager.registerTable(
      _tableKey,
      widget.initialDuration.toInt(),
      _onTimeUpdate,
    );
  }

  void _onTimeUpdate() {
    if (mounted) {
      final newDuration = _timeManager.getCurrentDuration(_tableKey);
      if (_currentDuration != newDuration) {
        setState(() {
          _currentDuration = newDuration;
        });
      }
    }
  }

  @override
  void didUpdateWidget(AnimatedHourglass oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果初始时间发生变化，更新时间管理器
    if (oldWidget.initialDuration != widget.initialDuration) {
      _timeManager.updateTableInitialTime(_tableKey, widget.initialDuration.toInt());
      _currentDuration = widget.initialDuration.toInt();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timeManager.unregisterTable(_tableKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _rotation,
          builder: (_, child) {
            return Transform.rotate(
              angle: _currentAngle + _rotation.value,
              child: Image.asset(
                'assets/order_table_time_icon.webp', // 你的图片路径
                width: 10,
                height: 10,
              ),
            );
          },
        ),
        SizedBox(width: 4),
        Text(TimeFormatter.formatTableTimeFromNum(_currentDuration), style: TextStyle(fontSize: 12)),
      ],
    );
  }
}
