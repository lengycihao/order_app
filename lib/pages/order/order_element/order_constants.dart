/// 订单控制器相关常量
class OrderConstants {
  // 防抖时间配置
  static const int debounceTimeMs = 500;
  static const int cartDebounceTimeMs = 300;
  static const int addDebounceTimeMs = 300;
  static const int websocketBatchDebounceMs = 300;
  
  // 超时配置
  static const int dishLoadingTimeoutSeconds = 5;
  static const int cartRefreshDelayMs = 1000;
  static const int uiRefreshDelayMs = 200;
  static const int retryDelaySeconds = 1;
  
  // 消息ID长度
  static const int messageIdLength = 20;
  
  // 消息去重集合最大大小
  static const int maxProcessedMessageIds = 1000;
  static const int messageIdsCleanupSize = 200;
  
  // 错误代码
  static const int errorCode409 = 409;
  static const int errorCode501 = 501;
  
  // API路径
  static const String allergensApiPath = '/api/waiter/dish/allergens';
  static const String cartInfoApiPath = '/api/waiter/cart/info';
  
  // 日志标签
  static const String logTag = 'OrderController';
  
  // 默认图片
  static const String defaultDishImage = 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=400&h=300&fit=crop&crop=center';
  
  // 拼音映射（简化版）
  static const Map<String, String> pinyinMap = {
    '阿': 'a', '八': 'b', '擦': 'c', '大': 'd', '额': 'e', '发': 'f', '嘎': 'g', '哈': 'h',
    '鸡': 'j', '卡': 'k', '拉': 'l', '马': 'm', '那': 'n', '哦': 'o', '趴': 'p', '七': 'q',
    '日': 'r', '撒': 's', '他': 't', '乌': 'w', '西': 'x', '压': 'y', '杂': 'z',
    '白': 'b', '菜': 'c', '蛋': 'd', '饭': 'f', '锅': 'g', '红': 'h', '烤': 'k',
    '辣': 'l', '面': 'm', '牛': 'n', '排': 'p', '肉': 'r', '汤': 't', '鱼': 'y', '粥': 'z',
  };
}

/// 操作类型枚举
enum OperationType {
  add('add'),
  update('update'),
  delete('delete'),
  decrease('decrease'),
  clear('clear');
  
  const OperationType(this.value);
  final String value;
}

/// 消息类型枚举
enum MessageType {
  cart('cart'),
  table('table'),
  cartResponse('cart_response'),
  heartbeat('heartbeat');
  
  const MessageType(this.value);
  final String value;
}

/// 购物车操作类型枚举
enum CartAction {
  refresh('refresh'),
  add('add'),
  update('update'),
  delete('delete'),
  clear('clear');
  
  const CartAction(this.value);
  final String value;
}

/// 桌台操作类型枚举
enum TableAction {
  changeMenu('change_menu'),
  changePeopleCount('change_people_count'),
  changeTable('change_table');
  
  const TableAction(this.value);
  final String value;
}
