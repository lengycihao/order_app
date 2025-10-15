import 'package:flutter/material.dart';
import '../../../utils/time_formatter.dart';
import '../utils/table_time_manager.dart';

class StaticHourglass extends StatefulWidget {
  final num initialDuration; // 初始时间戳（秒）
  final String? tableId; // 桌台ID，用于性能优化
  
  const StaticHourglass({
    super.key, 
    required this.initialDuration,
    this.tableId,
  });

  @override
  State<StaticHourglass> createState() => _StaticHourglassState();
}

class _StaticHourglassState extends State<StaticHourglass> {
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

    _registerToTimeManager();
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
  void didUpdateWidget(StaticHourglass oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果初始时间发生变化，更新时间管理器
    if (oldWidget.initialDuration != widget.initialDuration) {
      _timeManager.updateTableInitialTime(_tableKey, widget.initialDuration.toInt());
      _currentDuration = widget.initialDuration.toInt();
    }
  }

  @override
  void dispose() {
    _timeManager.unregisterTable(_tableKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 静态沙漏图标，无动画
        Image.asset(
          'assets/order_table_time_icon.webp',
          width: 10,
          height: 10,
        ),
        SizedBox(width: 4),
        Text(
          TimeFormatter.formatTableTimeFromNum(_currentDuration), 
          style: TextStyle(fontSize: 12)
        ),
      ],
    );
  }
}
