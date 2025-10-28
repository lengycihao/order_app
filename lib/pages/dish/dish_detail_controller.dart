import 'package:get/get.dart';
import 'package:lib_domain/entrity/order/dish_list_model/item.dart';
import 'package:lib_domain/entrity/order/dish_list_model/option.dart' as DomainOption;
import 'package:lib_domain/entrity/order/dish_list_model/allergen.dart' as DomainAllergen;
import 'package:lib_base/lib_base.dart';
import 'package:order_app/pages/order/model/dish.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:lib_base/logging/logging.dart';

class DishDetailController extends GetxController {
  final int? dishId;
  final int? menuId;
  final int? initialCartCount;
  final Dish? dishData; // 直接传入的菜品数据

  DishDetailController({
    this.dishId,
    this.menuId,
    this.initialCartCount,
    this.dishData,
  });

  // 响应式数据
  final Rx<Item?> dish = Rx<Item?>(null);
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxInt cartCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    if (dishData != null) {
      // 如果直接传入了菜品数据，直接使用
      _loadDishFromData();
    } else {
      // 否则通过API加载
      _loadDishDetail();
    }
    _initCartCountListener();
  }

  /// 从传入的菜品数据加载
  void _loadDishFromData() {
    if (dishData == null) return;
    
    try {
      // 将Dish模型转换为Item模型
      final item = Item(
        id: dishData!.id,
        name: dishData!.name,
        price: dishData!.price.toString(),
        image: dishData!.image,
        description: '', // Dish模型没有description字段
        allergens: dishData!.allergens, // 直接使用传入的过敏原数据
        options: dishData!.options, // 直接使用传入的选项数据
        tags: dishData!.tags ?? [],
        hasOptions: dishData!.hasOptions,
      );
      
      dish.value = item;
      isLoading.value = false;
      errorMessage.value = '';
    } catch (e) {
      logDebug('❌ 加载菜品数据失败: $e', tag: 'DishDetailController');
      errorMessage.value = '加载菜品数据失败';
      isLoading.value = false;
    }
  }

  /// 初始化购物车数量监听
  void _initCartCountListener() {
    try {
      final orderController = Get.find<OrderController>();
      // 监听购物车数据变化
      ever(orderController.cart, (_) {
        updateCartCount();
      });
      // 初始更新一次
      updateCartCount();
    } catch (e) {
      logError('❌ 初始化购物车监听失败: $e', tag: 'DishDetailController');
    }
  }

  /// 更新购物车数量
  void updateCartCount() {
    try {
      final orderController = Get.find<OrderController>();
      final dishModel = convertToDishModel();
      
      int totalCount = 0;
      
      // 计算该菜品在购物车中的所有数量（包括无规格和有规格的）
      for (var entry in orderController.cart.entries) {
        if (entry.key.dish.id == dishModel.id) {
          totalCount += entry.value;
        }
      }
      
      // 如果有初始数量且大于计算出的数量，使用初始数量
      if (initialCartCount != null && initialCartCount! > totalCount) {
        cartCount.value = initialCartCount!;
      } else {
        cartCount.value = totalCount;
      }
    } catch (e) {
      logError('❌ 更新购物车数量失败: $e', tag: 'DishDetailController');
      cartCount.value = initialCartCount ?? 0;
    }
  }

  /// 加载菜品详情
  Future<void> _loadDishDetail() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await HttpManagerN.instance.executeGet(
        '/api/waiter/dish/detail',
        queryParam: {
          'dish_id': dishId,
          'menu_id': menuId,
        },
      );

      if (result.isSuccess && result.dataJson != null) {
        dish.value = Item.fromJson(result.dataJson as Map<String, dynamic>);
        logDebug('✅ 菜品详情加载成功: ${dish.value?.name}', tag: 'DishDetailController');
      } else {
        errorMessage.value = '加载菜品详情失败';
        logError('❌ 菜品详情加载失败: ${result.msg}', tag: 'DishDetailController');
      }
    } catch (e) {
      errorMessage.value = '网络错误: $e';
      logError('❌ 菜品详情加载异常: $e', tag: 'DishDetailController');
    } finally {
      isLoading.value = false;
    }
  }

  /// 转换为Dish模型
  Dish convertToDishModel() {
    final item = dish.value;
    if (item == null) {
      throw Exception('菜品数据为空');
    }

    // 转换敏感物 - 直接使用domain包中的Allergen
    List<DomainAllergen.Allergen>? allergens = item.allergens;

    // 转换规格选项
    List<DomainOption.Option>? options;
    if (item.options != null && item.options!.isNotEmpty) {
      options = item.options!;
    }

    return Dish(
      id: item.id.toString(),
      name: item.name ?? '',
      image: item.image ?? '',
      price: double.tryParse(item.price ?? '0') ?? 0.0,
      categoryId: int.tryParse(item.categoryId ?? '0') ?? 0,
      hasOptions: item.hasOptions ?? false,
      options: options,
      allergens: allergens,
      tags: item.tags,
    );
  }

  /// 获取购物车中该菜品的数量
  int getCartCount() {
    return cartCount.value;
  }

  /// 刷新数据
  Future<void> refresh() async {
    await _loadDishDetail();
  }
}
