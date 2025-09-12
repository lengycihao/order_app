import '../model/dish.dart';

/// 敏感物模型
class Allergen {
  final int id;
  final String label;
  final String? icon;

  Allergen({
    required this.id,
    required this.label,
    this.icon,
  });

  factory Allergen.fromJson(Map<String, dynamic> json) {
    return Allergen(
      id: json['id'] ?? 0,
      label: json['label'] ?? '',
      icon: json['icon'],
    );
  }
}

/// 购物车项目，包含菜品和选择的规格
class CartItem {
  final Dish dish;
  final Map<String, List<String>> selectedOptions; // 选择的规格选项
  final String? cartSpecificationId; // WebSocket操作需要的规格ID
  final int? cartItemId; // 购物车项的ID
  final int? cartId; // 购物车的外层ID（用于update和delete操作）

  CartItem({
    required this.dish,
    this.selectedOptions = const {},
    this.cartSpecificationId,
    this.cartItemId,
    this.cartId,
  });

  // 用于区分不同规格的相同菜品
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is CartItem &&
    runtimeType == other.runtimeType &&
    dish.id == other.dish.id &&
    _mapEquals(selectedOptions, other.selectedOptions) &&
    cartSpecificationId == other.cartSpecificationId;

  @override
  int get hashCode => dish.id.hashCode ^ selectedOptions.hashCode ^ (cartSpecificationId?.hashCode ?? 0);

  bool _mapEquals(Map<String, List<String>> map1, Map<String, List<String>> map2) {
    if (map1.length != map2.length) return false;
    for (var key in map1.keys) {
      if (!map2.containsKey(key)) return false;
      var list1 = map1[key]!;
      var list2 = map2[key]!;
      if (list1.length != list2.length) return false;
      for (int i = 0; i < list1.length; i++) {
        if (list1[i] != list2[i]) return false;
      }
    }
    return true;
  }

  /// 获取规格描述文本
  String get specificationText {
    if (selectedOptions.isEmpty) return '';
    List<String> specs = [];
    selectedOptions.forEach((key, values) {
      if (values.isNotEmpty) {
        specs.addAll(values);
      }
    });
    return specs.join('、');
  }
}

