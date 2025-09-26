import 'package:lib_domain/entrity/order/dish_list_model/option.dart';
import 'package:lib_domain/entrity/order/dish_list_model/allergen.dart';

class Dish {
  final String id;
  final String name;
  final String image;
  final double price;
  final int categoryId; // 对应 categories 的索引
  final bool hasOptions;
  final List<Option>? options;
  final List<Allergen>? allergens;
  final List<String>? tags; // 规格属性
  final int dishType; // 菜品类型：1-正常菜品，3-特殊项目（桌号、人数等）

  Dish({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.categoryId,
    this.hasOptions = false,
    this.options,
    this.allergens,
    this.tags,
    this.dishType = 1, // 默认为正常菜品
  });
}
