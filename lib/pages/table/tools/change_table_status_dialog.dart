import 'package:flutter/material.dart';
import 'package:order_app/cons/table_status.dart';

class ChangeTableStatusDialog extends StatelessWidget {
  final String tableNo;
  final TableStatus status;
  final VoidCallback onClose;
  final Function(TableStatus) onChangeStatus;

  const ChangeTableStatusDialog({
    Key? key,
    required this.tableNo,
    required this.status,
    required this.onClose,
    required this.onChangeStatus,
  }) : super(key: key);

  // 根据业务场景返回可切换的目标状态
  List<TableStatus> getAvailableStatus(TableStatus current) {
    switch (current) {
      case TableStatus.Empty:
        return [TableStatus.Unavailable];
      case TableStatus.Unavailable:
        return [TableStatus.Empty];
      case TableStatus.WaitingOrder:
        return [TableStatus.Empty];
      case TableStatus.PreBilled:
        return [TableStatus.Empty];
      default:
        return [];
    }
  }

  String statusText(TableStatus status) {
    switch (status) {
      case TableStatus.Empty:
        return '空桌台';
      case TableStatus.Occupied:
        return '占用';
      case TableStatus.WaitingOrder:
        return '待下单';
      case TableStatus.PendingBill:
        return '待结账';
      case TableStatus.PreBilled:
        return '已预结';
      case TableStatus.Unavailable:
        return '不可用';
      case TableStatus.Maintenance:
        return '维修';
      case TableStatus.Reserved:
        return '已预定';
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableStatus = getAvailableStatus(status);

    return Dialog(
      insetPadding: EdgeInsets.all(30),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题和关闭按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '更换状态',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(icon: Icon(Icons.close), onPressed: onClose),
              ],
            ),
            Divider(height: 24, thickness: 1),
            // 桌号和状态
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    text: '桌号：',
                    style: TextStyle(fontSize: 14, color: Colors.black),
                    children: [
                      TextSpan(
                        text: tableNo,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    text: '状态：',
                    style: TextStyle(fontSize: 14, color: Colors.black),
                    children: [
                      TextSpan(
                        text: statusText(status),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            // 可切换状态按钮
            ...availableStatus.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF9027),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // 圆角更大，两侧半圆
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => onChangeStatus(s),
                    child: Text(
                      '更换状态：${statusText(s)}',
                      style: TextStyle(
                        color: Colors.white, // 文字白色
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (availableStatus.isEmpty)
              Text('当前状态不可切换', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
