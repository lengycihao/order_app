import 'package:flutter/material.dart';
import 'package:order_app/utils/toast_utils.dart';

/// 外卖时间选择弹窗
class TakeawayTimePickerDialog extends StatefulWidget {
  final DateTime initialTime;
  final Function(DateTime) onTimeSelected;

  const TakeawayTimePickerDialog({
    super.key,
    required this.initialTime,
    required this.onTimeSelected,
  });

  @override
  State<TakeawayTimePickerDialog> createState() => _TakeawayTimePickerDialogState();
}

class _TakeawayTimePickerDialogState extends State<TakeawayTimePickerDialog> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  
  late int _selectedHour;
  late int _selectedMinute;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
    
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            const Text(
              '请选择时间',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            // 时间选择器
            _buildTimePicker(),
            const SizedBox(height: 24),
            // 按钮
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  /// 构建时间选择器
  Widget _buildTimePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 小时选择器
        Expanded(
          child: Column(
            children: [
              const Text(
                '时',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildWheelScrollView(
                  controller: _hourController,
                  itemCount: 24,
                  onSelectedItemChanged: (index) {
                    _selectedHour = index;
                  },
                  itemBuilder: (index) => '${index.toString().padLeft(2, '0')}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // 分钟选择器
        Expanded(
          child: Column(
            children: [
              const Text(
                '分',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildWheelScrollView(
                  controller: _minuteController,
                  itemCount: 60,
                  onSelectedItemChanged: (index) {
                    _selectedMinute = index;
                  },
                  itemBuilder: (index) => '${index.toString().padLeft(2, '0')}',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建优化的滚轮选择器
  Widget _buildWheelScrollView({
    required FixedExtentScrollController controller,
    required int itemCount,
    required Function(int) onSelectedItemChanged,
    required String Function(int) itemBuilder,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 40,
      perspective: 0.003, // 3D透视效果
      magnification: 1.1, // 中间项放大效果
      useMagnifier: true,
      physics: const FixedExtentScrollPhysics(), // 确保只能停在数字上
      onSelectedItemChanged: onSelectedItemChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        builder: (context, index) {
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              // 计算当前项与中心项的距离
              double distance = 0.0;
              if (controller.hasClients) {
                distance = (controller.selectedItem - index).abs().toDouble();
              }
              
              // 根据距离计算透明度和字体大小
              double opacity = 1.0;
              double fontSize = 18.0;
              Color color = Colors.black;
              
              if (distance > 0) {
                opacity = (1.0 - (distance * 0.3)).clamp(0.3, 1.0);
                fontSize = (18.0 - (distance * 3)).clamp(12.0, 18.0);
                color = Colors.black.withOpacity(opacity);
              }
              
              return Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: TextStyle(
                    fontSize: fontSize,
                    color: color,
                    fontWeight: distance == 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                  child: Text(itemBuilder(index)),
                ),
              );
            },
          );
        },
        childCount: itemCount,
      ),
    );
  }

  /// 构建按钮
  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              '取消',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _confirmTime,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9027),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              '确认',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 确认时间选择
  void _confirmTime() {
    final now = DateTime.now();
    final selectedTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedHour,
      _selectedMinute,
    );

    // 检查选择的时间是否大于当前时间
    if (selectedTime.isBefore(now)) {
      ToastUtils.showError(context, '选择的时间不能早于当前时间');
      return;
    }

    // 返回选择的时间
    widget.onTimeSelected(selectedTime);
    Navigator.of(context).pop();
  }
}
