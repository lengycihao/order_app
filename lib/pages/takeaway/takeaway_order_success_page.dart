import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/takeaway/takeaway_order_success_controller.dart';
import 'package:order_app/utils/l10n_utils.dart';
import '../../constants/global_colors.dart';

/// 外卖下单成功页面
class TakeawayOrderSuccessPage extends StatelessWidget {
  const TakeawayOrderSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TakeawayOrderSuccessController>(
      init: TakeawayOrderSuccessController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: GlobalColors.primaryBackground,
          appBar: AppBar(
            title: Text(
              context.l10n.takeaway,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 其他信息卡片
                      _buildOtherInfoCard(context, controller),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // 底部确认按钮
              _buildConfirmButton(context, controller),
            ],
          ),
        );
      },
    );
  }

  /// 构建其他信息卡片
  Widget _buildOtherInfoCard(BuildContext context, TakeawayOrderSuccessController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题 - 居中显示
          Center(
            child: Text(
              "其他信息",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 分割线
          Container(
            height: 1,
            color: const Color(0xFF999999),
          ),
          const SizedBox(height: 20),
          // 取单时间
          _buildPickupTimeSection(context, controller),
          const SizedBox(height: 20),
          // 备注
          _buildRemarkSection(context, controller),
        ],
      ),
    );
  }

  /// 构建取单时间部分
  Widget _buildPickupTimeSection(BuildContext context, TakeawayOrderSuccessController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 取单时间标题和时间显示 - 两边排列
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.pickupTime,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            Obx(() => Text(
              controller.selectedTimeText.value,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFFFF9027),
                fontWeight: FontWeight.w500,
              ),
            )),
          ],
        ),
        const SizedBox(height: 16),
        // 时间标签
        _buildTimeTags(context, controller),
      ],
    );
  }

  /// 构建时间标签
  Widget _buildTimeTags(BuildContext context, TakeawayOrderSuccessController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        );
      }

      // 创建选项列表，包含API返回的选项和"${l10n.otherTime}"选项
      final List<Map<String, dynamic>> timeOptions = [];
      
      // 添加API返回的选项
      for (final option in controller.timeOptions) {
        timeOptions.add({
          'minutes': option.value,
          'label': option.label,
        });
      }
      
      // 添加"${l10n.otherTime}"选项作为最后一个
      timeOptions.add({
        'minutes': -1,
        'label': context.l10n.otherTime,
      });

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.start,
        children: timeOptions.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = controller.selectedTimeIndex.value == index;
          final isOtherTime = option['minutes'] == -1;
          
          return GestureDetector(
            onTap: () {
              if (isOtherTime) {
                controller.showTimePicker();
              } else {
                controller.selectTimeOption(index);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF9027).withOpacity(0.1) : Colors.white,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF9027) : const Color(0xFFE0E0E0),
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? const Color(0xFFFF9027) : const Color(0xFF666666),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                child: Text(option['label'] as String),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  /// 构建备注部分
  Widget _buildRemarkSection(BuildContext context, TakeawayOrderSuccessController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.remarks,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 78,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Obx(() => TextField( 
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: "请输入",
              hintStyle: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          )),
        ),
      ],
    );
  }

  /// 构建确认按钮
  Widget _buildConfirmButton(BuildContext context, TakeawayOrderSuccessController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 250,
          height: 40,
          child: Obx(() => ElevatedButton(
            onPressed: controller.isLoading.value ? null : () => controller.confirmOrder(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9027),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: controller.isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    context.l10n.confirm,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          )),
        ),
      ),
    );
  }
}
