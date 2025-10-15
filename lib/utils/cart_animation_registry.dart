import 'dart:async';
import 'package:flutter/material.dart';
import 'package:order_app/pages/order/components/parabolic_animation_widget.dart';

class _PendingAnimationOffsets {
  final Offset start;
  final Offset target;
  _PendingAnimationOffsets({required this.start, required this.target});
}

/// 简单的全局动画注册器：
/// - 点击时登记起点/终点坐标；
/// - 发送WS后拿到messageId，将队列中的第一个登记与messageId绑定；
/// - 收到成功回执后按messageId播放动画。
class CartAnimationRegistry {
  static final List<_PendingAnimationOffsets> _queue = <_PendingAnimationOffsets>[];
  static final Map<String, List<_PendingAnimationOffsets>> _byMessageId = <String, List<_PendingAnimationOffsets>>{};

  /// 登记一次待播放的动画（起点/终点为屏幕全局坐标）
  static void enqueue(Offset start, Offset target) {
     _queue.add(_PendingAnimationOffsets(start: start, target: target));
  }

  /// 绑定接下来 count 条待播放动画到指定messageId（若不足则绑定可用的全部）
  static void bindNextToMessageId(String messageId, {int count = 1}) {
    print('🔗 绑定动画: messageId=$messageId, count=$count, 队列长度=${_queue.length}');
    if (_queue.isEmpty) {
      debugPrint('❌ 动画队列为空，无法绑定');
      return;
    }
    final int take = count.clamp(1, _queue.length);
    final items = <_PendingAnimationOffsets>[];
    for (int i = 0; i < take; i++) {
      items.add(_queue.removeAt(0));
    }
    _byMessageId[messageId] = items;
    print('✅ 绑定完成: messageId=$messageId, 绑定数量=${items.length}');
  }

  /// 播放并移除指定messageId的动画（若不存在则忽略）
  static void playForMessageId(String messageId, BuildContext? context) {
     if (context == null) {
      debugPrint('❌ context为空，跳过动画播放');
      return;
    }
    final pendingList = _byMessageId.remove(messageId);
    if (pendingList == null || pendingList.isEmpty) {
      debugPrint('❌ 未找到绑定的动画: messageId=$messageId');
      return;
    }

     // 逐个触发动画，增加极短的错峰，避免完全重叠
    for (int i = 0; i < pendingList.length; i++) {
      final item = pendingList[i];
      Future.delayed(Duration(milliseconds: 60 * i), () {
         ParabolicAnimationManager.triggerAddToCartAnimationWithOffsets(
          context: context,
          startOffset: item.start,
          targetOffset: item.target,
        );
      });
    }
  }

  /// 清空全部登记（用于异常/页面切换时的清理）
  static void clearAll() {
    _queue.clear();
    _byMessageId.clear();
  }
}


