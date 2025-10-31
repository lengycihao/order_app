import 'package:flutter/material.dart';
import 'package:order_app/utils/l10n_utils.dart';
import 'package:order_app/utils/modal_utils.dart';

/// 首页更多选项弹窗组件
class TableMoreOptionsModalWidget {
  /// 操作类型枚举
  static const String typeMerge = 'merge'; // 并桌
  static const String typeClose = 'close'; // 关桌
  static const String typeRemove = 'remove'; // 撤桌

  /// 显示更多选项弹窗
  static void showMoreModal(
    BuildContext context,
    Function(String type) onOptionSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: _TableMoreOptionsModalContent(
            onOptionSelected: onOptionSelected,
          ),
        ),
      ),
    );
  }
}

/// 首页更多选项弹窗内容
class _TableMoreOptionsModalContent extends StatelessWidget {
  final Function(String type) onOptionSelected;

  const _TableMoreOptionsModalContent({
    Key? key,
    required this.onOptionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModalContainerWithMargin(
      title: context.l10n.more,
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 并桌选项
                  _MoreOptionItem(
                    title: context.l10n.mergeTables,
                    onTap: () {
                      Navigator.of(context).pop(); // 关闭更多选项弹窗
                      Future.delayed(Duration(milliseconds: 100), () {
                        onOptionSelected(TableMoreOptionsModalWidget.typeMerge);
                      });
                    },
                  ),
                  SizedBox(height: 30),
                  // 关桌选项
                  _MoreOptionItem(
                    title: context.l10n.closeTable,
                    onTap: () {
                      Navigator.of(context).pop(); // 关闭更多选项弹窗
                      Future.delayed(Duration(milliseconds: 100), () {
                        onOptionSelected(TableMoreOptionsModalWidget.typeClose);
                      });
                    },
                  ),
                  SizedBox(height: 30),
                  // 撤桌选项
                  _MoreOptionItem(
                    title: context.l10n.clearTable,
                    onTap: () {
                      Navigator.of(context).pop(); // 关闭更多选项弹窗
                      Future.delayed(Duration(milliseconds: 100), () {
                        onOptionSelected(TableMoreOptionsModalWidget.typeRemove);
                      });
                    },
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 更多选项项
class _MoreOptionItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _MoreOptionItem({
    Key? key,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: 12),
        margin: EdgeInsets.symmetric(horizontal: 25),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontSize: 20,
              color: Color(0xff666666),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

