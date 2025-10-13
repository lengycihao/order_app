import 'package:flutter/material.dart';
import 'package:order_app/utils/l10n_utils.dart';

/// 备注输入弹窗组件
class RemarkDialogWidget extends StatefulWidget {
  final String initialRemark;
  final Function(String) onConfirm;

  const RemarkDialogWidget({
    Key? key,
    this.initialRemark = '',
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<RemarkDialogWidget> createState() => _RemarkDialogWidgetState();
}

class _RemarkDialogWidgetState extends State<RemarkDialogWidget> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialRemark);
    _focusNode = FocusNode();
    
    // 检查初始值是否为空
    _canConfirm = widget.initialRemark.trim().isNotEmpty;
    
    // 监听输入变化
    _textController.addListener(_onTextChanged);
    
    // 延迟聚焦，确保弹窗动画完成后再弹出键盘
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _onTextChanged() {
    setState(() {
      _canConfirm = _textController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Text(
                context.l10n.remark,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Spacer(),IconButton(onPressed: (){
                Navigator.of(context).pop();
              }, icon: Icon(Icons.close,color: Color(0xFF333333),))
                ],
              ),
            ),
            
            // 输入框
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                constraints: BoxConstraints(
                  minHeight: 78,
                  maxHeight: 100,
                ),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: null,
                  // maxLength: 200,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF333333),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: context.l10n.pleaseEnter,
                    hintStyle: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF999999),
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    counterStyle: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  autocorrect: true,
                  enableSuggestions: true,
                  keyboardType: TextInputType.text,
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // 确认按钮
            Center(
              child: GestureDetector(
                onTap: _canConfirm ? () {
                  final remark = _textController.text.trim();
                  Navigator.of(context).pop();
                  widget.onConfirm(remark);
                } : null,
                child: Container(
                  width: 180,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _canConfirm ? Color(0xFFFF9027) : Color(0xFFCCCCCC),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Text(
                      context.l10n.confirm,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
            ),
            
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

