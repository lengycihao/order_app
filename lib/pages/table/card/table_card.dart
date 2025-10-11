import 'package:flutter/material.dart';
import 'package:order_app/cons/table_status.dart';
import 'package:order_app/pages/table/card/animate_hour.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:marquee/marquee.dart';
import 'package:order_app/pages/table/sub_page/select_menu_page.dart';
import 'package:order_app/pages/table/tools/change_table_status_dialog.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/table/table_controller.dart';
import 'package:order_app/pages/order/order_main_page.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:lib_domain/api/base_api.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:lib_base/logging/logging.dart';

class TableCard extends StatelessWidget {
  final TableListModel table;
  final bool isMergeMode;
  final List<TableMenuListModel> tableModelList;

  // 防抖处理 - 静态变量存储最后点击时间
  static int _lastClickTime = 0;
  static const int _debounceDelay = 2000; // 2秒防抖
  final bool isSelected;
  final VoidCallback? onSelect;

  const TableCard({
    Key? key,
    required this.table,
    required this.tableModelList,
    this.isMergeMode = false,
    this.isSelected = false,
    this.onSelect,
  }) : super(key: key);

  Color _getStatusColor(TableStatus status) {
    switch (status) {
      case TableStatus.Unavailable:
        return Color(0xff999999);
      case TableStatus.PendingBill:
        return Color(0xffF47E97);
      case TableStatus.PreBilled:
        return Color(0xff77DD77);
      case TableStatus.WaitingOrder:
        return Color(0xffFFD700);
      case TableStatus.Empty:
        return Colors.white;
      case TableStatus.Occupied:
        return Color(0xff999999);
      case TableStatus.Maintenance:
        return Color(0xff999999);
      case TableStatus.Reserved:
        return Color(0xff999999);
    }
  }

  Color _getStatusBottomColor(TableStatus status) {
    switch (status) {
      case TableStatus.Unavailable:
        return Color(0xff666666);
      case TableStatus.PendingBill:
        return Color(0xffFF6B8B);
      case TableStatus.PreBilled:
        return Color(0xff55CB55);
      case TableStatus.WaitingOrder:
        return Color(0xffEAC500);
      case TableStatus.Empty:
        return Color(0xffE4E4E4);
      case TableStatus.Occupied:
        return Color(0xff666666);
      case TableStatus.Maintenance:
        return Color(0xff666666);
      case TableStatus.Reserved:
        return Color(0xff666666);
    }
  }

  TableStatus _getStatus(int status) {
    switch (status) {
      case 0:
        return TableStatus.Empty;
      case 1:
        return TableStatus.Occupied;
      case 2:
        return TableStatus.WaitingOrder;
      case 3:
        return TableStatus.PendingBill;
      case 4:
        return TableStatus.PreBilled;
      case 5:
        return TableStatus.Unavailable; // 修复：5应该是不可用状态
      case 6:
        return TableStatus.Maintenance;
      case 7:
        return TableStatus.Reserved;
    }
    return TableStatus.Empty;
  }

  @override
  Widget build(BuildContext context) {
    final status = _getStatus(table.businessStatus.toInt());
    // final canMerge = status != TableStatus.Unavailable && status != TableStatus.Maintenance;
    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (_) => ChangeTableStatusDialog(
            tableNo: table.tableName ?? "",
            status: status,
            onClose: () => Navigator.of(context).pop(),
            onChangeStatus: (newStatus) async {
              Navigator.of(context).pop();

              // 获取TableController实例
              final controller = Get.find<TableControllerRefactored>();

              // 调用API切换桌台状态
              await controller.changeTableStatus(
                context: context,
                tableId: table.tableId.toInt(),
                newStatus: newStatus,
              );
            },
          ),
        );
      },
      onTap: isMergeMode
          ? null
          : () async {
              // 如果是并桌模式，不处理点击事件
              if (isMergeMode) {
                return;
              }

              // 防抖处理
              final currentTime = DateTime.now().millisecondsSinceEpoch;
              if (currentTime - _lastClickTime < _debounceDelay) {
                logDebug('点击过于频繁，忽略此次点击', tag: 'TableCard');
                return;
              }
              _lastClickTime = currentTime;

              try {
                // 获取桌台最新详情
                logDebug(
                  '🔍 准备获取桌台详情，原始tableId: ${table.tableId} (类型: ${table.tableId.runtimeType})',
                  tag: 'TableCard',
                );
                final baseApi = BaseApi();
                final result = await baseApi.getTableDetail(
                  tableId: table.tableId.toInt(),
                );

                if (!result.isSuccess || result.data == null) {
                  logDebug('❌ 获取桌台详情失败: ${result.msg}', tag: 'TableCard');
                  ToastUtils.showError(Get.context!, '获取桌台信息失败');
                  return;
                }

                // 使用最新的桌台数据
                final latestTable = result.data!;
                logDebug(
                  '✅ 获取桌台详情成功: tableId=${latestTable.tableId}, tableName=${latestTable.tableName}, hallId=${latestTable.hallId}',
                  tag: 'TableCard',
                );

                // 检查桌台ID是否有效
                if (latestTable.tableId == 0) {
                  logDebug('⚠️ 警告：API返回的桌台ID为0', tag: 'TableCard');
                }

                final status = _getStatus(latestTable.businessStatus.toInt());

                // 如果是不可用或维修状态的桌台，显示提示信息
                if (status == TableStatus.Unavailable ||
                    status == TableStatus.Maintenance) {
                  String message = status == TableStatus.Unavailable
                      ? '该桌台当前不可用'
                      : '该桌台正在维修中';
                  ToastUtils.showError(Get.context!, message);
                  return;
                }

                // 根据状态决定跳转页面
                if (latestTable.businessStatus == 0) {
                  // 状态0：进入菜单选择页面
                  // 直接跳转到选择菜单页面，让选择菜单页面自己请求数据
                  Get.to(
                    () => const SelectMenuPage(),
                    arguments: {
                      'table': latestTable,
                      'table_id': latestTable.tableId,
                    },
                  );
                } else {
                  // 其他状态（除了5,6）：直接进入点餐页面
                  // 先清理可能存在的OrderController实例
                  if (Get.isRegistered<OrderController>()) {
                    Get.delete<OrderController>();
                    logDebug('🧹 清理旧的OrderController实例', tag: 'TableCard');
                  }
                  if (Get.isRegistered<OrderMainPageController>()) {
                    Get.delete<OrderMainPageController>();
                    logDebug(
                      '🧹 清理旧的OrderMainPageController实例',
                      tag: 'TableCard',
                    );
                  }

                  // 等待清理完成
                  await Future.delayed(Duration(milliseconds: 100));

                  // 直接跳转到点餐页面，让OrderController自己处理菜单数据
                  Get.to(
                    () => OrderMainPage(),
                    arguments: {
                      'table': latestTable,
                      'menu_id': latestTable
                          .menuId, // 只传递menu_id，让OrderController自己获取菜单数据
                      'table_id': latestTable.tableId,
                      'adult_count': latestTable.currentAdult > 0
                          ? latestTable.currentAdult
                          : latestTable.standardAdult,
                      'child_count': latestTable.currentChild,
                      'source': 'table', // 明确标识来源
                    },
                  );
                }
              } catch (e) {
                // 关闭加载指示器
                if (Get.isDialogOpen == true) {
                  Get.back();
                }

                ToastUtils.showError(Get.context!, '获取桌台信息失败: ${e.toString()}');
              }
            },
      child: Stack(
        children: [
          // 主要内容容器
          Container(
            // padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, 1),
                  blurRadius: 3,
                  color: Color(0x33000000), // #000000 20%
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 桌号 & 人数
                Container(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 桌名 - 限制为2行显示
                      Expanded(
                        flex: 2,
                        child: Text(
                          table.tableName ?? "",
                          style: TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8), // 添加间距
                      // 人数信息 - 固定在右侧
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/order_table_person_icon.webp',
                                width: 8,
                                height: 8,
                              ),
                              SizedBox(width: 3),
                              // 当桌台非空和不可用时，显示0/10格式
                              (status != TableStatus.Empty &&
                                      status != TableStatus.Unavailable)
                                  ? Text(
                                      '${table.currentAdult}/${table.standardAdult}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  : Text(
                                      table.standardAdult.toString(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ],
                          ),
                          if (table.standardChild > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/order_table_child_icon.webp',
                                  width: 8,
                                  height: 8,
                                ),
                                SizedBox(width: 3),
                                // 当桌台非空和不可用时，显示0/10格式
                                (status != TableStatus.Empty &&
                                        status != TableStatus.Unavailable)
                                    ? Text(
                                        '${table.currentChild}/${table.standardChild}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )
                                    : Text(
                                        table.standardChild.toString(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 金额显示在正中间
                // Expanded(
                //   child: Center(
                //     child: table.businessStatus == 3
                //         ? Text(
                //             '€ ${table.orderAmount}',
                //             style: TextStyle(
                //               color: Colors.black,
                //               fontSize: 16,
                //               fontWeight: FontWeight.bold,
                //             ),
                //           )
                //         : SizedBox(),
                //   ),
                // ),
                Spacer(),
                // 状态 & 时间
                _getStatusLabel(context, status),
              ],
            ),
          ),
          // 选中边框 - 覆盖在上面，不占用空间
          if (isMergeMode && isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xffFF9027), width: 2),
                ),
              ),
            ),
          // 选中状态图标 - 右下角
          if (isMergeMode && isSelected)
            Positioned(
              right: 0,
              bottom: 0,
              child: Image.asset(
                'assets/order_select.webp',
                width: 30,
                height: 30,
              ),
            ),
        ],
      ),
    );
  }

  Widget _getStatusLabel(BuildContext context, TableStatus status) {
    return // 状态 & 时间
    Container(
      height: 23,
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _getStatusBottomColor(status),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 桌台状态（带走马灯效果）
          Expanded(
            child: _buildStatusText(
              context,
              table.businessStatusName.toString(),
              // "文字过长文字过长文字过长文字过长",
            ),
          ),
          SizedBox(width: 20),
          if (table.businessStatus == 1 ||
              table.businessStatus == 2 ||
              table.businessStatus == 3)
            AnimatedHourglass(
              initialDuration: table.openDuration,
              tableId: table.tableId.toString(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusText(BuildContext context, String text) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 限制最大宽度为父容器的 3/4
        final maxWidth = constraints.maxWidth * 0.75;

        // 用 TextPainter 计算文字宽度
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: const TextStyle(fontSize: 12, color: Colors.black),
          ),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(minWidth: 0, maxWidth: double.infinity);

        final textWidth = textPainter.size.width;

        if (textWidth <= maxWidth) {
          // 没超出，直接显示普通文字
          return Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          );
        } else {
          // 超出，走马灯
          return SizedBox(
            width: maxWidth,
            height: 20, // 固定高度，避免跳动
            child: Marquee(
              text: text,
              style: const TextStyle(fontSize: 12, color: Colors.black),
              scrollAxis: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              blankSpace: 30.0,
              velocity: 30.0,
              startPadding: 5.0,
              pauseAfterRound: const Duration(seconds: 1),
              showFadingOnlyWhenScrolling: true,
              fadingEdgeStartFraction: 0.1,
              fadingEdgeEndFraction: 0.1,
            ),
          );
        }
      },
    );
  }
}
