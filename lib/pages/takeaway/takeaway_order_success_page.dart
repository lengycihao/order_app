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
          resizeToAvoidBottomInset: false, // 防止页面跟随键盘调整大小
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
          body: GestureDetector(
            onTap: () {
              // 点击页面收回键盘
              FocusScope.of(context).unfocus();
            },
            child: Column(
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
                // 底部确认按钮 - 固定在底部
                _buildConfirmButton(context, controller),
              ],
            ),
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
          // 备注
          _buildRemarkSection(context, controller),
        ],
      ),
    );
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
            fontWeight: FontWeight.bold,
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
          child: TextField( 
            controller: controller.remarkController,
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
          ),
        ),
      ],
    );
  }

  /// 构建确认按钮
  Widget _buildConfirmButton(BuildContext context, TakeawayOrderSuccessController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: SafeArea(
        child: Center(
          child: SizedBox(
            width: 250,
            height: 40,
            child: Obx(() => ElevatedButton(
              onPressed: controller.isSubmitting.value ? null : () => controller.confirmOrder(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9027),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: controller.isSubmitting.value
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
      ),
    );
  }
}
