import 'package:lib_domain/entrity/order/dish_list_model/dish_list_model.dart';
import '../model/dish.dart';
import 'order_constants.dart';
import 'models.dart';

/// 数据转换工具类
class DataConverter {
  /// 从API数据加载菜品数据
  static void loadDishesFromData({
    required List<DishListModel> dishListModels,
    required List<String> categories,
    required List<Dish> dishes,
    bool clearExisting = true, // 新增参数，控制是否清空现有数据
  }) {
    // 只有在明确要求清空时才清空数据，避免刷新时丢失状态
    if (clearExisting) {
      categories.clear();
      dishes.clear();
    }
    
    for (int i = 0; i < dishListModels.length; i++) {
      var dishListModel = dishListModels[i];
      
      if (dishListModel.name != null) {
        categories.add(dishListModel.name!);
        final categoryIndex = categories.length - 1;
        
        if (dishListModel.items != null) {
          for (int j = 0; j < dishListModel.items!.length; j++) {
            var item = dishListModel.items![j];
            
            final dish = Dish(
              id: item.id?.toString() ?? '',
              name: item.name ?? '',
              image: item.image ?? '', // 空字段不显示假数据
              price: double.tryParse(item.unitPrice ?? item.price ?? '0') ?? 0.0, // 优先使用unit_price，如果没有则使用price
              categoryId: categoryIndex,
              hasOptions: item.hasOptions ?? false,
              options: item.options,
              allergens: item.allergens,
              tags: item.tags,
            );
            dishes.add(dish);
          }
        }
      }
    }
  }

  /// 获取首字母拼音
  static String getPinyinInitials(String text) {
    String initials = '';
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (OrderConstants.pinyinMap.containsKey(char)) {
        initials += OrderConstants.pinyinMap[char]!;
      } else if (RegExp(r'[a-zA-Z]').hasMatch(char)) {
        initials += char.toLowerCase();
      }
    }
    return initials;
  }

  /// 构建桌号显示文本
  static String buildTableDisplayText({
    required String? tableName,
    required int adultCount,
    required int childCount,
  }) {
    final displayTableName = tableName ?? '--';
    final totalPeople = adultCount + childCount;
    return '桌号$displayTableName | 人数$totalPeople';
  }

  /// 构建已选敏感物名称列表
  static List<String> buildSelectedAllergenNames({
    required List<int> selectedAllergens,
    required List<Allergen> allAllergens,
  }) {
    return selectedAllergens.map((id) {
      final allergen = allAllergens.where((a) => a.id == id).firstOrNull;
      return allergen?.label ?? '';
    }).where((name) => name.isNotEmpty).toList();
  }

  /// 构建规格描述文本
  static String buildSpecificationText(Map<String, List<String>> selectedOptions) {
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
