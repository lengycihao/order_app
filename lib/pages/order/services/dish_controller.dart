import 'package:get/get.dart';
import 'package:lib_domain/api/base_api.dart';
import 'package:lib_domain/entrity/order/dish_list_model/dish_list_model.dart';
import 'package:lib_base/logging/logging.dart';
import '../model/dish.dart';
import '../order_element/data_converter.dart';

/// 菜品数据控制器
/// 负责管理菜品数据的加载和筛选
class DishController extends GetxController {
  final String _logTag = 'DishController';
  final BaseApi _api = BaseApi();
  
  // 菜品数据
  final categories = <String>[].obs;
  final dishes = <Dish>[].obs;
  final isLoadingDishes = false.obs;
  
  // 筛选条件
  final searchKeyword = "".obs;
  final sortType = SortType.none.obs;

  /// 从API获取菜品数据
  Future<void> loadDishesFromApi({
    required String? tableId,
    required int menuId,
  }) async {
    if (menuId == 0) {
      logDebug('❌ 菜单ID无效，无法获取菜品数据', tag: _logTag);
      return;
    }

    try {
      isLoadingDishes.value = true;
      logDebug('🔄 开始从API获取菜品数据...', tag: _logTag);
      
      final result = await _api.getMenudDishList(
        tableID: tableId,
        menuId: menuId.toString(),
      );
      
      if (result.isSuccess && result.data != null) {
        logDebug('✅ 成功获取菜品数据，类目数量: ${result.data!.length}', tag: _logTag);
        _loadDishesFromData(result.data!);
      } else {
        logError('❌ 获取菜品数据失败: ${result.msg}', tag: _logTag);
      }
    } catch (e) {
      logError('❌ 获取菜品数据异常: $e', tag: _logTag);
    } finally {
      isLoadingDishes.value = false;
    }
  }

  /// 从数据加载菜品
  void _loadDishesFromData(List<DishListModel> dishListModels) {
    logDebug('🔄 开始加载菜品数据...', tag: _logTag);
    
    DataConverter.loadDishesFromData(
      dishListModels: dishListModels,
      categories: categories,
      dishes: dishes,
    );
    
    // 强制刷新UI
    categories.refresh();
    dishes.refresh();
    
    logDebug('✅ 菜品数据加载完成: ${categories.length} 个类目, ${dishes.length} 个菜品', tag: _logTag);
  }

  /// 设置搜索关键词
  void setSearchKeyword(String keyword) {
    searchKeyword.value = keyword;
    logDebug('🔍 搜索关键词已设置: $keyword', tag: _logTag);
  }

  /// 清空搜索关键词
  void clearSearchKeyword() {
    searchKeyword.value = '';
    logDebug('🧹 搜索关键词已清空', tag: _logTag);
  }

  /// 设置排序类型
  void setSortType(SortType type) {
    sortType.value = type;
    logDebug('🔄 排序类型已设置: $type', tag: _logTag);
  }

  /// 获取筛选后的菜品列表
  List<Dish> getFilteredDishes({
    required List<int> selectedAllergens,
  }) {
    var list = dishes.where((d) {
      // 搜索关键词筛选
      if (searchKeyword.value.isNotEmpty) {
        final keyword = searchKeyword.value.toLowerCase();
        final dishName = d.name.toLowerCase();
        final pinyin = DataConverter.getPinyinInitials(d.name);
        
        if (!dishName.contains(keyword) && !pinyin.contains(keyword)) {
          return false;
        }
      }
      
      // 敏感物筛选
      if (selectedAllergens.isNotEmpty && d.allergens != null) {
        for (var allergen in d.allergens!) {
          if (selectedAllergens.contains(allergen.id)) {
            return false;
          }
        }
      }
      
      return true;
    }).toList();

    // 排序
    switch (sortType.value) {
      case SortType.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortType.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      default:
        break;
    }
    
    return list;
  }

  /// 清空菜品数据
  void clearDishData() {
    categories.clear();
    dishes.clear();
    searchKeyword.value = '';
    sortType.value = SortType.none;
    categories.refresh();
    dishes.refresh();
    logDebug('🧹 菜品数据已清空', tag: _logTag);
  }

  /// 获取菜品统计信息
  Map<String, dynamic> getDishStats() {
    return {
      'totalCategories': categories.length,
      'totalDishes': dishes.length,
      'isLoading': isLoadingDishes.value,
      'searchKeyword': searchKeyword.value,
      'sortType': sortType.value.toString(),
    };
  }
}

/// 排序类型枚举
enum SortType { none, priceAsc, priceDesc }
