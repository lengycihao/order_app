import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/dish.dart';
import 'package:lib_domain/entrity/order/dish_list_model/dish_list_model.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:lib_base/lib_base.dart';
import 'package:lib_domain/api/base_api.dart';
import 'package:lib_domain/api/cart_api.dart';
import 'package:lib_domain/entrity/cart/cart_info_model.dart';
import 'package:lib_base/utils/websocket_manager.dart';
import 'package:lib_base/logging/logging.dart';
import 'package:lib_base/network/interceptor/auth_service.dart';
import 'package:order_app/service/service_locator.dart';
import '../components/error_notification_manager.dart';

enum SortType { none, priceAsc, priceDesc }

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

/// 待确认的操作信息
class PendingOperation {
  final String type; // 操作类型：add, update, delete, clear
  final Dish? dish; // 菜品信息
  final Map<String, List<String>>? selectedOptions; // 规格选项
  final int? quantity; // 数量
  final CartItem? cartItem; // 购物车项目
  
  PendingOperation({
    required this.type,
    this.dish,
    this.selectedOptions,
    this.quantity,
    this.cartItem,
  });
}

class OrderController extends GetxController {
  final categories = <String>[].obs;
  final selectedCategory = 0.obs;
  final searchKeyword = "".obs;
  final sortType = SortType.none.obs;
  final dishes = <Dish>[].obs;
  final cart = <CartItem, int>{}.obs;
  final selectedAllergens = <int>[].obs; // 选中的敏感物ID列表
  final tempSelectedAllergens = <int>[].obs; // 临时选中的敏感物ID列表（弹窗内选择）
  final allAllergens = <Allergen>[].obs; // 所有敏感物列表
  final isLoadingAllergens = false.obs; // 敏感物加载状态
  final isSearchVisible = false.obs; // 搜索框显示状态
  final isLoadingDishes = false.obs; // 菜品加载状态
  final isLoadingCart = false.obs; // 购物车加载状态

  // 从路由传递的数据
  var table = Rx<TableListModel?>(null);
  var menu = Rx<TableMenuListModel?>(null);
  var adultCount = 0.obs;
  var childCount = 0.obs;
  
  // 购物车数据
  var cartInfo = Rx<CartInfoModel?>(null);
  
  // WebSocket相关
  final WebSocketManager _wsManager = wsManager;
  final isWebSocketConnected = false.obs;
  
  // 购物车刷新防抖器
  Timer? _cartRefreshTimer;
  
  // API服务
  final CartApi _cartApi = CartApi();
  final BaseApi _api = BaseApi();
  
  // 待确认的操作（key: messageId, value: 操作信息）
  final Map<String, PendingOperation> _pendingOperations = {};
  
  // 已处理的消息ID集合（去重用）
  final Set<String> _processedMessageIds = {};
  
  
  // 加载状态管理（按菜品ID跟踪）
  final RxMap<String, bool> _dishLoadingStates = <String, bool>{}.obs;
  
  // 防抖处理 - 存储操作的Timer  
  final Map<String, Timer> _debounceTimers = {};
  
  /// 获取菜品是否正在加载
  bool isDishLoading(String dishId) => _dishLoadingStates[dishId] ?? false;
  
  /// 设置菜品加载状态
  void _setDishLoading(String dishId, bool loading) {
    _dishLoadingStates[dishId] = loading;
  }
  
  /// 防抖操作 - 防止用户快速连续点击
  void _debounceOperation(String key, VoidCallback operation, {int milliseconds = 500}) {
    // 取消之前的定时器
    _debounceTimers[key]?.cancel();
    
    // 设置新的定时器
    _debounceTimers[key] = Timer(Duration(milliseconds: milliseconds), () {
      operation();
      _debounceTimers.remove(key);
    });
  }

  @override
  void onInit() {
    super.onInit();
    logDebug('🔍 OrderController onInit 开始', tag: 'OrderController');
    final args = Get.arguments as Map<String, dynamic>?;
    logDebug('📦 接收到的参数: $args', tag: 'OrderController');
    
    // 处理传递的基本参数（桌台、菜单、人数等）
    if (args != null) {
      if (args['table'] != null) {
        table.value = args['table'] as TableListModel;
        logDebug('✅ 桌台信息已设置', tag: 'OrderController');
      }
      if (args['menu'] != null) {
        // 安全地处理menu参数，可能是单个对象或数组
        final menuData = args['menu'];
        if (menuData is TableMenuListModel) {
          // 从SelectMenuPage传递过来的单个菜单
          menu.value = menuData;
          logDebug('✅ 菜单信息已设置: ${menuData.menuName}', tag: 'OrderController');
        } else if (menuData is List<TableMenuListModel>) {
          // 从桌台卡片直接传递过来的菜单列表
          if (menuData.isNotEmpty) {
            // 检查是否有menu_id参数，如果有则根据menu_id选择对应的菜单
            if (args['menu_id'] != null) {
              final targetMenuId = args['menu_id'] as int;
              final targetMenu = menuData.firstWhere(
                (menu) => menu.menuId == targetMenuId,
                orElse: () => menuData[0], // 如果找不到，使用第一个菜单
              );
              menu.value = targetMenu;
              logDebug('✅ 菜单信息已设置(根据menu_id): ${targetMenu.menuName} (ID: ${targetMenu.menuId})', tag: 'OrderController');
            } else {
              // 没有menu_id参数，使用第一个菜单
              menu.value = menuData[0];
              logDebug('✅ 菜单信息已设置(从列表): ${menuData[0].menuName}', tag: 'OrderController');
            }
          }
        }
      }
      // 处理成人数量 - 支持两种参数名格式
      if (args['adultCount'] != null) {
        adultCount.value = args['adultCount'] as int;
        logDebug('✅ 成人数量: ${adultCount.value}', tag: 'OrderController');
      } else if (args['adult_count'] != null) {
        adultCount.value = args['adult_count'] as int;
        logDebug('✅ 成人数量: ${adultCount.value}', tag: 'OrderController');
      }
      
      // 处理儿童数量 - 支持两种参数名格式
      if (args['childCount'] != null) {
        childCount.value = args['childCount'] as int;
        logDebug('✅ 儿童数量: ${childCount.value}', tag: 'OrderController');
      } else if (args['child_count'] != null) {
        childCount.value = args['child_count'] as int;
        logDebug('✅ 儿童数量: ${childCount.value}', tag: 'OrderController');
      }
    }
    
    // 初始化WebSocket连接
    _initializeWebSocket();
    
    // 先加载菜品数据，完成后再加载购物车数据
    _loadDishesAndCart();
  }

  List<Dish> get filteredDishes {
    var list = dishes.where((d) {
      // 搜索关键词筛选 - 支持菜品名称和首字母搜索
      if (searchKeyword.value.isNotEmpty) {
        final keyword = searchKeyword.value.toLowerCase();
        final dishName = d.name.toLowerCase();
        final pinyin = _getPinyinInitials(d.name);
        
        if (!dishName.contains(keyword) && !pinyin.contains(keyword)) {
          return false;
        }
      }
      
      // 敏感物筛选 - 排除包含选中敏感物的菜品
      if (selectedAllergens.isNotEmpty && d.allergens != null) {
        for (var allergen in d.allergens!) {
          if (selectedAllergens.contains(allergen.id)) {
            return false; // 如果菜品包含选中的敏感物，则排除
          }
        }
      }
      
      return true;
    }).toList();

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

  void clearCart() {
    _debounceOperation('clear_cart', () {
      cart.clear();
      update(); // 触发GetBuilder重建
      
      // 同步到WebSocket
      _syncClearCartToWebSocket();
      
      logDebug('🧹 购物车已清空', tag: 'OrderController');
    }, milliseconds: 300);
  }

  void addToCart(Dish dish, {Map<String, List<String>>? selectedOptions}) {
    // 检查是否已在加载中
    if (isDishLoading(dish.id)) {
      logDebug('⏳ 菜品 ${dish.name} 正在添加中，跳过重复操作', tag: 'OrderController');
      return;
    }
    
    // 设置加载状态
    _setDishLoading(dish.id, true);
    
    // 设置超时清除加载状态（10秒后）
    Timer(Duration(seconds: 10), () {
      if (isDishLoading(dish.id)) {
        _setDishLoading(dish.id, false);
        logDebug('⏰ 菜品 ${dish.name} 添加超时，清除加载状态', tag: 'OrderController');
      }
    });
    
    logDebug('📤 发送添加菜品请求: ${dish.name}', tag: 'OrderController');
    
    // 直接发送到服务器，不做本地处理
    _syncAddDishToWebSocket(dish, 1, selectedOptions);
  }

  void removeFromCart(dynamic item) {
    if (item is CartItem) {
      _removeCartItem(item);
    } else if (item is Dish) {
      _removeDishFromCart(item);
    }
  }

  void _removeCartItem(CartItem cartItem) {
    final key = '${cartItem.dish.id}_${cartItem.cartSpecificationId ?? 'default'}';
    _debounceOperation(key, () {
      if (!cart.containsKey(cartItem)) return;
      
      final oldQuantity = cart[cartItem]!;
      if (oldQuantity > 1) {
        cart[cartItem] = oldQuantity - 1;
        // 同步数量更新到WebSocket
        _syncUpdateDishQuantityToWebSocket(cartItem, cart[cartItem]!);
      } else {
        // 当数量为1时，使用incr_quantity字段减少数量
        cart[cartItem] = 0; // 设置为0表示删除
        // 同步减少数量到WebSocket（使用incr_quantity字段）
        _syncDecreaseDishQuantityToWebSocket(cartItem, -1);
        // 从购物车中移除
        cart.remove(cartItem);
      }
      // 强制更新UI
      cart.refresh();
      update(); // 触发GetBuilder重建
    });
  }

  /// 删除整个购物车项（左滑删除时使用）
  void deleteCartItem(CartItem cartItem) {
    if (!cart.containsKey(cartItem)) return;
    
    cart.remove(cartItem);
    // 同步删除到WebSocket
    _syncDeleteDishToWebSocket(cartItem);
    // 强制更新UI
    cart.refresh();
    update(); // 触发GetBuilder重建
    
    logDebug('🗑️ 完全删除购物车项: ${cartItem.dish.name}', tag: 'OrderController');
  }

  /// 增加购物车项数量（购物车页面内使用）
  void addCartItemQuantity(CartItem cartItem) {
    final key = '${cartItem.dish.id}_${cartItem.cartSpecificationId ?? 'default'}_add';
    _debounceOperation(key, () {
      if (!cart.containsKey(cartItem)) return;
      
      final oldQuantity = cart[cartItem]!;
      cart[cartItem] = oldQuantity + 1;
      
      // 同步数量更新到WebSocket
      _syncUpdateDishQuantityToWebSocket(cartItem, cart[cartItem]!);
      
      // 强制更新UI
      cart.refresh();
      update(); // 触发GetBuilder重建
      
      logDebug('➕ 增加购物车项数量: ${cartItem.dish.name} -> ${cart[cartItem]}', tag: 'OrderController');
    }, milliseconds: 300); // 加号操作使用更短的防抖时间
  }

  void _removeDishFromCart(Dish dish) {
    // 查找该菜品的第一个购物车项目（优先选择无规格的）
    CartItem? targetCartItem;
    
    // 首先查找无规格的版本
    for (var entry in cart.entries) {
      if (entry.key.dish.id == dish.id && entry.key.selectedOptions.isEmpty) {
        targetCartItem = entry.key;
        break;
      }
    }
    
    // 如果没有找到无规格的，就选择第一个匹配的
    if (targetCartItem == null) {
      for (var entry in cart.entries) {
        if (entry.key.dish.id == dish.id) {
          targetCartItem = entry.key;
          break;
        }
      }
    }
    
    if (targetCartItem != null) {
      _removeCartItem(targetCartItem);
    }
  }

  int get totalCount {
    return cart.values.fold(0, (sum, e) => sum + e);
  }
  double get totalPrice =>
      cart.entries.fold(0.0, (sum, e) => sum + e.key.dish.price * e.value);

  /// 根据类目ID获取该类目的购物车数量
  int getCategoryCount(int categoryIndex) {
    // 确保访问响应式Map以触发更新
    int count = 0;
    cart.forEach((cartItem, quantity) {
      if (cartItem.dish.categoryId == categoryIndex) {
        count += quantity;
      }
    });
    return count;
  }

  /// 切换敏感物选择状态
  void toggleAllergen(int allergenId) {
    if (selectedAllergens.contains(allergenId)) {
      selectedAllergens.remove(allergenId);
    } else {
      selectedAllergens.add(allergenId);
    }
    selectedAllergens.refresh();
  }

  /// 清除敏感物选择
  void clearAllergenSelection() {
    selectedAllergens.clear();
    selectedAllergens.refresh();
  }

  /// 测试敏感物API调用
  Future<void> testAllergenApi() async {
    logDebug('🧪 开始测试敏感物API调用...', tag: 'OrderController');
    try {
      final result = await HttpManagerN.instance.executeGet('/api/waiter/dish/allergens');
      logDebug('🔍 API调用结果: isSuccess=${result.isSuccess}, code=${result.code}, msg=${result.msg}', tag: 'OrderController');
      logDebug('🔍 原始数据: ${result.dataJson}', tag: 'OrderController');
      logDebug('🔍 数据类型: ${result.dataJson.runtimeType}', tag: 'OrderController');
      
      if (result.isSuccess) {
        // 根据JSON结构解析
        dynamic data = result.dataJson;
        if (data is Map<String, dynamic>) {
          data = data['data'];
          logDebug('🔍 从Map中获取data字段: ${data}', tag: 'OrderController');
          
          if (data is Map<String, dynamic> && data['allergens'] != null) {
            data = data['allergens'];
            logDebug('🔍 从data中获取allergens字段: ${data}', tag: 'OrderController');
            
            if (data is List) {
              logDebug('✅ 找到敏感物数组，包含 ${data.length} 个敏感物', tag: 'OrderController');
              for (var item in data) {
                logDebug('  - ${item['label']} (id: ${item['id']})', tag: 'OrderController');
              }
            }
          }
        }
      }
      
      // 尝试不同的数据获取方式
      logDebug('🔍 getDataDynamic: ${result.getDataDynamic()}', tag: 'OrderController');
      logDebug('🔍 getDataJson: ${result.getDataJson()}', tag: 'OrderController');
      logDebug('🔍 getListJson: ${result.getListJson()}', tag: 'OrderController');
      
    } catch (e) {
      logDebug('❌ 测试API调用异常: $e', tag: 'OrderController');
    }
  }

  /// 获取敏感物列表
  Future<void> loadAllergens() async {
    if (isLoadingAllergens.value) return;
    
    isLoadingAllergens.value = true;
    try {
      final result = await HttpManagerN.instance.executeGet('/api/waiter/dish/allergens');
      logDebug('🔍 API调用结果: isSuccess=${result.isSuccess}, code=${result.code}, msg=${result.msg}', tag: 'OrderController');
      logDebug('🔍 原始数据: ${result.dataJson}', tag: 'OrderController');
      
      if (result.isSuccess) {
        // 根据JSON结构，数据在 data.allergens 中
        dynamic data = result.dataJson;
        logDebug('🔍 dataJson类型: ${data.runtimeType}', tag: 'OrderController');
        logDebug('🔍 dataJson内容: $data', tag: 'OrderController');
        
        // 如果dataJson是Map，尝试获取其中的data字段
        if (data is Map<String, dynamic>) {
          data = data['data'];
          logDebug('🔍 从Map中获取data字段: ${data}', tag: 'OrderController');
          
          // 再从data中获取allergens字段
          if (data is Map<String, dynamic> && data['allergens'] != null) {
            data = data['allergens'];
            logDebug('🔍 从data中获取allergens字段: ${data}', tag: 'OrderController');
          }
        }
        
        // 如果data是List，直接解析
        if (data is List) {
          allAllergens.value = data.map<Allergen>((item) => Allergen.fromJson(item as Map<String, dynamic>)).toList();
          logDebug('✅ 敏感物数据加载成功: ${allAllergens.length} 个', tag: 'OrderController');
          for (var allergen in allAllergens) {
            logDebug('  - ${allergen.label} (id: ${allergen.id})', tag: 'OrderController');
          }
        } else {
          logDebug('❌ 敏感物数据格式错误: 期望List，实际${data.runtimeType}', tag: 'OrderController');
          // 尝试使用getDataDynamic方法
          final dynamicData = result.getDataDynamic();
          logDebug('🔍 尝试getDataDynamic: ${dynamicData}', tag: 'OrderController');
          if (dynamicData is List) {
            allAllergens.value = dynamicData.map<Allergen>((item) => Allergen.fromJson(item as Map<String, dynamic>)).toList();
            logDebug('✅ 通过getDataDynamic加载敏感物数据成功: ${allAllergens.length} 个', tag: 'OrderController');
          }
        }
      } else {
        logDebug('❌ 敏感物数据加载失败: ${result.msg}', tag: 'OrderController');
      }
    } catch (e) {
      logDebug('❌ 敏感物数据加载异常: $e', tag: 'OrderController');
    } finally {
      isLoadingAllergens.value = false;
    }
  }

  /// 按顺序加载菜品数据和购物车数据
  Future<void> _loadDishesAndCart() async {
    logDebug('🔄 开始按顺序加载菜品和购物车数据', tag: 'OrderController');
    
    // 先加载菜品数据
    await _loadDishesFromApi();
    
    // 菜品数据加载完成后，再加载购物车数据
    await _loadCartFromApi();
    
    // 强制刷新UI以确保显示更新
    Future.delayed(Duration(milliseconds: 200), () {
      cart.refresh();
      update();
      logDebug('🔄 初始化后延迟刷新UI，确保购物车显示更新', tag: 'OrderController');
    });
    
    logDebug('✅ 菜品和购物车数据加载完成', tag: 'OrderController');
  }

  @override
  void onReady() {
    super.onReady();
    // 页面完全显示后，再次检查购物车数据
    logDebug('📱 页面已完全显示，检查购物车数据', tag: 'OrderController');
    Future.delayed(Duration(milliseconds: 500), () {
      if (table.value?.tableId != null) {
        forceRefreshCart().then((_) {
          // 强制刷新UI
          cart.refresh();
          update();
          logDebug('🔄 onReady后强制刷新购物车UI', tag: 'OrderController');
        });
      }
    });
  }

  /// 强制刷新购物车数据（公开方法，用于调试）
  Future<void> forceRefreshCart() async {
    logDebug('🔄 强制刷新购物车数据', tag: 'OrderController');
    await _loadCartFromApi();
  }
  
  /// 强制刷新购物车UI（公开方法，用于调试）
  void forceRefreshCartUI() {
    logDebug('🔄 强制刷新购物车UI', tag: 'OrderController');
    cart.refresh();
    update();
    // 再次延迟刷新确保UI更新
    Future.delayed(Duration(milliseconds: 100), () {
      cart.refresh();
      update();
      logDebug('🔄 二次延迟刷新购物车UI', tag: 'OrderController');
    });
  }

  /// 从API加载购物车数据
  Future<void> _loadCartFromApi() async {
    if (table.value?.tableId == null) {
      logDebug('❌ 桌台ID为空，无法加载购物车数据', tag: 'OrderController');
      return;
    }
    
    if (isLoadingCart.value) {
      logDebug('⏳ 购物车数据正在加载中，跳过重复请求', tag: 'OrderController');
      return;
    }
    
    isLoadingCart.value = true;
    try {
      final tableId = table.value!.tableId.toString();
      logDebug('🛒 开始加载购物车数据，桌台ID: $tableId', tag: 'OrderController');
      logDebug('🛒 购物车API请求URL: /api/waiter/cart/info?table_id=$tableId', tag: 'OrderController');
      
      final result = await _cartApi.getCartInfo(tableId: tableId);
      logDebug('🛒 购物车API调用结果: isSuccess=${result.isSuccess}, code=${result.code}, msg=${result.msg}', tag: 'OrderController');
      logDebug('🛒 购物车API原始响应数据 result.data: ${result.data}', tag: 'OrderController');
      logDebug('🛒 购物车API原始响应数据 result.dataJson: ${result.dataJson}', tag: 'OrderController');
      logDebug('🛒 购物车API hasData: ${result.hasData}', tag: 'OrderController');
      
      if (result.isSuccess) {
        if (result.data != null) {
          cartInfo.value = result.data;
          logDebug('✅ 购物车数据加载成功: ${cartInfo.value?.items?.length ?? 0} 个商品', tag: 'OrderController');
          logDebug('🛒 购物车对象类型: ${cartInfo.value.runtimeType}', tag: 'OrderController');
          logDebug('🛒 购物车items字段: ${cartInfo.value?.items}', tag: 'OrderController');
          
          // 打印购物车数据详情
          if (cartInfo.value?.items != null && cartInfo.value!.items!.isNotEmpty) {
            for (int i = 0; i < cartInfo.value!.items!.length; i++) {
              final item = cartInfo.value!.items![i];
              logDebug('🛒 商品${i + 1}: ${item.dishName} x${item.quantity} ￥${item.price}', tag: 'OrderController');
            }
          } else {
            logDebug('🛒 购物车items为空或null: items=${cartInfo.value?.items}', tag: 'OrderController');
          }
          
          // 将API数据转换为本地购物车格式
          _convertApiCartToLocalCart();
        } else {
          logDebug('🛒 购物车API返回空数据，保留本地购物车', tag: 'OrderController');
        }
      } else {
        logDebug('❌ 购物车数据加载失败: ${result.msg}', tag: 'OrderController');
        // 只有在真正的API错误时才记录，不清空本地购物车
      }
    } catch (e) {
      logDebug('❌ 购物车数据加载异常: $e', tag: 'OrderController');
    } finally {
      isLoadingCart.value = false;
    }
  }

  /// 将API购物车数据转换为本地购物车格式
  void _convertApiCartToLocalCart() {
    if (cartInfo.value?.items == null || cartInfo.value!.items!.isEmpty) {
      // 服务器购物车为空，清空本地购物车以保持同步
      logDebug('🛒 服务器购物车为空，清空本地购物车', tag: 'OrderController');
      cart.clear();
      cart.refresh();
      update();
      return;
    }
    
    logDebug('🔄 开始转换购物车数据，共${cartInfo.value!.items!.length}个商品，当前菜品列表有${dishes.length}个菜品', tag: 'OrderController');
    
    // 创建新的购物车映射
    final newCart = <CartItem, int>{};
    int validItemCount = 0;
    int invalidItemCount = 0;
    
    for (var apiCartItem in cartInfo.value!.items!) {
      logDebug('🔄 转换购物车商品: ${apiCartItem.dishName} (ID: ${apiCartItem.dishId}) x${apiCartItem.quantity}', tag: 'OrderController');
      
      // 从现有菜品列表中查找对应的菜品
      Dish? existingDish;
      try {
        existingDish = dishes.firstWhere(
          (dish) => dish.id == (apiCartItem.dishId ?? 0).toString(),
        );
        logDebug('✅ 找到对应菜品: ${existingDish.name}', tag: 'OrderController');
      } catch (e) {
        logDebug('⚠️ 未找到对应菜品ID: ${apiCartItem.dishId}，使用API数据创建临时菜品', tag: 'OrderController');
        
        // 计算正确的categoryId
        int correctCategoryId = 0;
        if (apiCartItem.tempDishInfo?.categoryId != null) {
          // 尝试在现有分类中找到匹配的分类
          final tempCategoryName = apiCartItem.tempDishInfo!.categoryName;
          if (tempCategoryName != null && tempCategoryName.isNotEmpty) {
            try {
              correctCategoryId = categories.indexWhere((cat) => cat == tempCategoryName);
              if (correctCategoryId == -1) {
                // 如果找不到匹配的分类，使用第一个分类
                correctCategoryId = 0;
                logDebug('⚠️ 未找到匹配的分类名称: $tempCategoryName，使用第一个分类', tag: 'OrderController');
              } else {
                logDebug('✅ 找到匹配的分类: $tempCategoryName (索引: $correctCategoryId)', tag: 'OrderController');
              }
            } catch (e) {
              logDebug('⚠️ 分类匹配异常: $e，使用第一个分类', tag: 'OrderController');
              correctCategoryId = 0;
            }
          } else {
            logDebug('⚠️ 临时菜品信息中没有分类名称，使用第一个分类', tag: 'OrderController');
            correctCategoryId = 0;
          }
        } else {
          logDebug('⚠️ 临时菜品信息中没有分类ID，使用第一个分类', tag: 'OrderController');
          correctCategoryId = 0;
        }
        
        // 如果找不到对应的菜品，创建一个临时的菜品对象
        existingDish = Dish(
          id: (apiCartItem.dishId ?? 0).toString(),
          name: apiCartItem.dishName ?? '',
          price: apiCartItem.price ?? 0.0,
          image: apiCartItem.image ?? '',
          categoryId: correctCategoryId,
          allergens: [],
          options: [],
        );
        logDebug('🆕 创建临时菜品: ${existingDish.name} (分类ID: $correctCategoryId)', tag: 'OrderController');
      }
      
      // 创建规格选项映射
      Map<String, List<String>> selectedOptions = {};
      if (apiCartItem.specifications != null && apiCartItem.specifications!.isNotEmpty) {
        for (var spec in apiCartItem.specifications!) {
          if (spec.specificationName != null && spec.optionName != null) {
            if (!selectedOptions.containsKey(spec.specificationName!)) {
              selectedOptions[spec.specificationName!] = [];
            }
            selectedOptions[spec.specificationName!]!.add(spec.optionName!);
          }
        }
        logDebug('🏷️ 规格选项: $selectedOptions', tag: 'OrderController');
      }
      
      // 创建CartItem
      final localCartItem = CartItem(
        dish: existingDish,
        selectedOptions: selectedOptions,
        cartSpecificationId: apiCartItem.specificationId,
        cartItemId: apiCartItem.cartId, // 购物车项的ID
        cartId: cartInfo.value?.cartId, // 购物车的外层ID
      );
      
      // 添加到新购物车
      final quantity = apiCartItem.quantity ?? 1;
      newCart[localCartItem] = quantity;
      validItemCount++;
      logDebug('✅ 添加到新购物车: ${existingDish.name} x$quantity', tag: 'OrderController');
    }
    
    // 计算总数量进行对比
    final oldTotalCount = totalCount;
    final newTotalCount = newCart.values.fold(0, (sum, quantity) => sum + quantity);
    
    logDebug('🔢 购物车数据统计 - 有效商品: $validItemCount, 无效商品: $invalidItemCount', tag: 'OrderController');
    logDebug('🔢 购物车数据对比 - 旧数量: $oldTotalCount, 新数量: $newTotalCount', tag: 'OrderController');
    
    // 只有当新数据不为空，或者新数据数量大于等于旧数据时才更新
    if (newTotalCount > 0 || (newTotalCount == 0 && oldTotalCount > 0 && cartInfo.value!.items!.isNotEmpty)) {
      // 更新购物车
      cart.clear();
      cart.addAll(newCart);
      cart.refresh();
      update();
      logDebug('✅ 购物车数据已更新: ${cart.length} 种商品，总数量: $newTotalCount', tag: 'OrderController');
      
      // 强制刷新UI以确保显示更新
      Future.delayed(Duration(milliseconds: 100), () {
        cart.refresh();
        update();
        logDebug('🔄 延迟刷新UI，确保购物车显示更新', tag: 'OrderController');
      });
    } else {
      logDebug('🔒 保留本地购物车数据，API数据为空可能是时序问题', tag: 'OrderController');
    }
  }

  /// 切换临时敏感物选择状态（弹窗内使用）
  void toggleTempAllergen(int allergenId) {
    if (tempSelectedAllergens.contains(allergenId)) {
      tempSelectedAllergens.remove(allergenId);
    } else {
      tempSelectedAllergens.add(allergenId);
    }
    tempSelectedAllergens.refresh();
  }

  /// 确认敏感物选择
  void confirmAllergenSelection() {
    selectedAllergens.value = List.from(tempSelectedAllergens);
    selectedAllergens.refresh();
  }

  /// 取消敏感物选择（关闭弹窗时调用）
  void cancelAllergenSelection() {
    tempSelectedAllergens.value = List.from(selectedAllergens);
    tempSelectedAllergens.refresh();
  }

  /// 清空所有敏感物筛选和缓存（关闭弹窗时调用）
  void clearAllAllergenData() {
    selectedAllergens.clear();
    tempSelectedAllergens.clear();
    allAllergens.clear();
    selectedAllergens.refresh();
    tempSelectedAllergens.refresh();
    allAllergens.refresh();
    logDebug('🧹 已清空所有敏感物筛选和缓存', tag: 'OrderController');
  }

  /// 显示搜索框
  void showSearchBox() {
    isSearchVisible.value = true;
  }

  /// 隐藏搜索框
  void hideSearchBox() {
    isSearchVisible.value = false;
    searchKeyword.value = ''; // 清空搜索关键词
  }

  /// 获取桌号显示文本
  String getTableDisplayText() {
    if (table.value == null) return '桌号-- | 人数0';
    final tableNumber = table.value!.tableName ?? '--';
    final totalPeople = adultCount.value + childCount.value;
    return '桌号$tableNumber | 人数$totalPeople';
  }

  /// 获取已选敏感物名称列表
  List<String> get selectedAllergenNames {
    return selectedAllergens.map((id) {
      final allergen = allAllergens.firstWhereOrNull((a) => a.id == id);
      return allergen?.label ?? '';
    }).where((name) => name.isNotEmpty).toList();
  }

  /// 获取首字母拼音
  String _getPinyinInitials(String text) {
    // 简单的首字母映射，实际项目中可以使用pinyin包
    final pinyinMap = {
      '阿': 'a', '八': 'b', '擦': 'c', '大': 'd', '额': 'e', '发': 'f', '嘎': 'g', '哈': 'h',
      '鸡': 'j', '卡': 'k', '拉': 'l', '马': 'm', '那': 'n', '哦': 'o', '趴': 'p', '七': 'q',
      '日': 'r', '撒': 's', '他': 't', '乌': 'w', '西': 'x', '压': 'y', '杂': 'z',
      '白': 'b', '菜': 'c', '蛋': 'd', '饭': 'f', '锅': 'g', '红': 'h', '烤': 'k',
      '辣': 'l', '面': 'm', '牛': 'n', '排': 'p', '肉': 'r', '汤': 't', '鱼': 'y', '粥': 'z',
    };
    
    String initials = '';
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (pinyinMap.containsKey(char)) {
        initials += pinyinMap[char]!;
      } else if (RegExp(r'[a-zA-Z]').hasMatch(char)) {
        initials += char.toLowerCase();
      }
    }
    return initials;
  }

  /// 通过API获取菜品数据
  Future<void> _loadDishesFromApi() async {
    if (menu.value == null) {
      logDebug('❌ 没有菜单信息，无法获取菜品数据', tag: 'OrderController');
      return;
    }

    try {
      isLoadingDishes.value = true;
      logDebug('🔄 开始从API获取菜品数据...', tag: 'OrderController');
      logDebug('📋 菜单ID: ${menu.value!.menuId}', tag: 'OrderController');
      logDebug('📋 桌台ID: ${table.value?.tableId} 📋 桌台名字: ${table.value?.tableName}', tag: 'OrderController');
      
      final api = BaseApi();
      final result = await api.getMenudDishList(
        tableID: table.value?.tableId.toString(),
        menuId: menu.value!.menuId.toString(),
      );
      
      if (result.isSuccess && result.data != null) {
        logDebug('✅ 成功获取菜品数据，类目数量: ${result.data!.length}', tag: 'OrderController');
        _loadDishesFromData(result.data!);
      } else {
        logDebug('❌ 获取菜品数据失败: ${result.msg}', tag: 'OrderController');
        // 可以在这里显示错误提示
        Get.snackbar('错误', result.msg ?? '获取菜品数据失败');
      }
    } catch (e) {
      logDebug('❌ 获取菜品数据异常: $e', tag: 'OrderController');
      Get.snackbar('错误', '获取菜品数据异常');
    } finally {
      isLoadingDishes.value = false;
    }
  }

  void _loadDishesFromData(List<DishListModel> dishListModels) {
    logDebug('🔄 开始加载菜品数据...', tag: 'OrderController');
    categories.clear();
    dishes.clear();
    
    for (int i = 0; i < dishListModels.length; i++) {
      var dishListModel = dishListModels[i];
      // logDebug('处理类目 $i: ${dishListModel.name}', tag: 'OrderController');
      
      if (dishListModel.name != null) {
        categories.add(dishListModel.name!);
        final categoryIndex = categories.length - 1;
        // logDebug('  添加类目: ${dishListModel.name} (索引: $categoryIndex)', tag: 'OrderController');
        
        if (dishListModel.items != null) {
          // logDebug('  该类目有 ${dishListModel.items!.length} 个菜品', tag: 'OrderController');
          for (int j = 0; j < dishListModel.items!.length; j++) {
            var item = dishListModel.items![j];
            // logDebug('    菜品 $j: ${item.name}, 价格: ${item.price}', tag: 'OrderController');
            
            final dish = Dish(
              id: item.id?.toString() ?? '',
              name: item.name ?? '',
              image: item.image ?? 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=400&h=300&fit=crop&crop=center',
              price: double.tryParse(item.price ?? '0') ?? 0.0,
              categoryId: categoryIndex,
              hasOptions: item.hasOptions ?? false,
              options: item.options,
              allergens: item.allergens,
            );
            dishes.add(dish);
          }
        } else {
          logDebug('  ❌ 该类目没有菜品数据', tag: 'OrderController');
        }
      } else {
        logDebug('  ❌ 该类目名称为空', tag: 'OrderController');
      }
    }
    
    // logDebug('📊 加载数据完成:', tag: 'OrderController');
    // logDebug('  类目数量: ${categories.length}', tag: 'OrderController');
    // logDebug('  菜品数量: ${dishes.length}', tag: 'OrderController');
    // logDebug('  类目列表: ${categories.toList()}', tag: 'OrderController');
    
    // 强制刷新UI
    categories.refresh();
    dishes.refresh();
  }

  /// 刷新点餐页面数据
  Future<void> refreshOrderData() async {
    logDebug('🔄 开始刷新点餐页面数据...', tag: 'OrderController');
    await _loadDishesFromApi();
    logDebug('✅ 点餐页面数据刷新完成', tag: 'OrderController');
  }

  /// 初始化WebSocket连接
  Future<void> _initializeWebSocket() async {
    if (table.value?.tableId == null) {
      logDebug('❌ 桌台ID为空，无法初始化WebSocket', tag: 'OrderController');
      return;
    }

    try {
      final tableId = table.value!.tableId.toString();
      final tableName = table.value!.tableName.toString();
      logDebug('🔌 开始初始化桌台ID: ${table.value?.tableId} 桌台名字 $tableName 的WebSocket连接...', tag: 'OrderController');

      // 获取真实的用户token
      String? token;
      try {
        final authService = getIt<AuthService>();
        token = authService.getCurrentToken();
        if (token != null) {
          logDebug('🔑 获取到用户token: ${token.substring(0, 20)}...', tag: 'OrderController');
        } else {
          logDebug('⚠️ 用户token为空，将使用默认token', tag: 'OrderController');
        }
      } catch (e) {
        logDebug('❌ 获取用户token失败: $e', tag: 'OrderController');
      }

      // 初始化WebSocket连接
      final success = await _wsManager.initializeTableConnection(
        tableId: tableId,
        token: token, // 使用真实的用户token
      );

      if (success) {
        isWebSocketConnected.value = true;
        
        // 设置消息监听器
        _setupWebSocketListeners();
        
        logDebug('📋 桌台ID: $tableId ✅ 桌台 $tableName WebSocket连接初始化成功', tag: 'OrderController');
      } else {
        logDebug('📋 桌台ID: $tableId ❌ 桌台 $tableName WebSocket连接初始化失败', tag: 'OrderController');
        isWebSocketConnected.value = false;
      }
    } catch (e) {
      logDebug('❌ WebSocket初始化异常: $e', tag: 'OrderController');
      isWebSocketConnected.value = false;
    }
  }

  /// WebSocket消息监听器
  Function(String, Map<String, dynamic>)? _webSocketMessageListener;

  /// 设置WebSocket消息监听器
  void _setupWebSocketListeners() {
    if (table.value?.tableId == null) return;

    // 移除旧的监听器（如果存在）
    if (_webSocketMessageListener != null) {
      _wsManager.removeServerMessageListener(_webSocketMessageListener!);
    }

    // 创建新的监听器
    _webSocketMessageListener = (tableId, message) {
      if (tableId == table.value!.tableId.toString()) {
        _handleWebSocketMessage(message);
      }
    };

    // 添加服务器消息监听器
    _wsManager.addServerMessageListener(_webSocketMessageListener!);

    logDebug('✅ WebSocket消息监听器设置完成', tag: 'OrderController');
  }

  /// 处理WebSocket消息
  void _handleWebSocketMessage(Map<String, dynamic> message) {
    try {
      // 解析消息
      final messageType = message['type'] as String?;
      final data = message['data'] as Map<String, dynamic>?;
      final messageId = message['id'] as String?;
      
      // 消息去重检查（除了心跳消息）
      if (messageType != 'heartbeat' && messageId != null) {
        if (_processedMessageIds.contains(messageId)) {
          // 跳过已处理的消息
          return;
        }
        // 记录已处理的消息ID
        _processedMessageIds.add(messageId);
        
        // 限制集合大小，避免内存泄漏
        if (_processedMessageIds.length > 1000) {
          final oldestIds = _processedMessageIds.take(200).toList();
          _processedMessageIds.removeAll(oldestIds);
        }
      }
      
      // 过滤心跳消息的日志输出
      if (messageType != 'heartbeat') {
        logDebug('📦 收到WebSocket消息: $message', tag: 'OrderController');
        logDebug('📦 消息类型: $messageType, 数据: $data', tag: 'OrderController');
      }
      
      switch (messageType) {
        case 'cart':
          logDebug('🛒 处理购物车消息', tag: 'OrderController');
          if (data != null) _handleCartMessage(data);
          break;
        case 'table':
          logDebug('🪑 处理桌台消息', tag: 'OrderController');
          if (data != null) _handleTableMessage(data);
          break;
        case 'cart_response':
          logDebug('📨 处理购物车响应消息', tag: 'OrderController');
          if (data != null) _handleCartResponseMessage(data);
          break;
        case 'heartbeat':
          // 心跳消息不处理，也不输出日志
          break;
        default:
          logDebug('⚠️ 未知的消息类型: $messageType', tag: 'OrderController');
      }
    } catch (e) {
      logDebug('❌ 处理WebSocket消息失败: $e', tag: 'OrderController');
    }
  }

  /// 处理购物车相关消息
  void _handleCartMessage(Map<String, dynamic> data) {
    final action = data['action'] as String?;
    
    switch (action) {
      case 'refresh':
        _handleServerCartRefresh(data);
        break;
      case 'add':
        _handleServerCartAdd(data);
        break;
      case 'update':
        _handleServerCartUpdate(data);
        break;
      case 'delete':
        _handleServerCartDelete(data);
        break;
      case 'clear':
        _handleServerCartClear(data);
        break;
      default:
        logDebug('⚠️ 未知的购物车操作: $action', tag: 'OrderController');
    }
  }






  /// 处理服务器刷新购物车消息
  void _handleServerCartRefresh(Map<String, dynamic> data) {
    try {
      logDebug('🔄 收到服务器刷新购物车消息: $data', tag: 'OrderController');
      
      // 立即重新加载购物车数据（不使用防抖，因为这是服务器主动要求刷新）
      _loadCartFromApi().then((_) {
        // 不再显示成功提示，只保留错误信息提示
        logDebug('✅ 购物车数据已根据服务器要求刷新完成', tag: 'OrderController');
      }).catchError((error) {
        logDebug('❌ 购物车刷新失败: $error', tag: 'OrderController');
      });
    } catch (e) {
      logDebug('❌ 处理服务器刷新购物车消息失败: $e', tag: 'OrderController');
    }
  }

  /// 处理服务器购物车添加消息
  void _handleServerCartAdd(Map<String, dynamic> data) {
    try {
      logDebug('➕ 收到服务器购物车添加消息: $data', tag: 'OrderController');
      
      // 服务器确认添加操作成功，不需要刷新（避免重复添加）
      logDebug('✅ 服务器确认添加操作，无需刷新购物车', tag: 'OrderController');
    } catch (e) {
      logDebug('❌ 处理服务器购物车添加消息失败: $e', tag: 'OrderController');
    }
  }


  /// 处理服务器购物车更新消息
  void _handleServerCartUpdate(Map<String, dynamic> data) {
    try {
      logDebug('🔄 收到服务器购物车更新消息: $data', tag: 'OrderController');
      
      // 服务器确认更新操作成功，不需要刷新（避免重复操作）
      logDebug('✅ 服务器确认更新操作，无需刷新购物车', tag: 'OrderController');
    } catch (e) {
      logDebug('❌ 处理服务器购物车更新消息失败: $e', tag: 'OrderController');
    }
  }

  /// 处理服务器购物车删除消息
  void _handleServerCartDelete(Map<String, dynamic> data) {
    try {
      logDebug('🗑️ 收到服务器购物车删除消息: $data', tag: 'OrderController');
      
      // 服务器确认删除操作成功，刷新购物车数据
      _refreshCartFromServer();
    } catch (e) {
      logDebug('❌ 处理服务器购物车删除消息失败: $e', tag: 'OrderController');
    }
  }

  /// 处理服务器购物车清空消息
  void _handleServerCartClear(Map<String, dynamic> data) {
    try {
      logDebug('🧹 收到服务器购物车清空消息: $data', tag: 'OrderController');
      
      // 服务器确认清空操作成功，刷新购物车数据
      _refreshCartFromServer();
    } catch (e) {
      logDebug('❌ 处理服务器购物车清空消息失败: $e', tag: 'OrderController');
    }
  }


  /// 生成20位随机消息ID
  String _generateMessageId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(20, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// 根据服务器响应更新购物车
  void _updateCartFromResponse(PendingOperation operation, dynamic responseData, String? serverMessage) {
    try {
      switch (operation.type) {
        case 'add':
          // 添加操作成功后等待refresh消息重新拉取购物车数据
          if (operation.dish != null) {
            logDebug('✅ 服务器确认菜品 ${operation.dish!.name} 添加成功，等待refresh消息', tag: 'OrderController');
            
            // 清除加载状态
            _setDishLoading(operation.dish!.id, false);
            
            // 不再显示成功提示，只保留错误信息提示
            logDebug('📅 等待服务器发送refresh消息以更新购物车', tag: 'OrderController');
          }
          break;
        case 'update':
          // 处理更新操作
          break;
        case 'delete':
          // 处理删除操作
          break;
        case 'clear':
          // 处理清空操作
          break;
      }
    } catch (e) {
      logDebug('❌ 根据服务器响应更新购物车失败: $e', tag: 'OrderController');
    }
  }

  /// 处理操作错误
  void _handleOperationError(PendingOperation operation, int code, String message) {
    try {
      logDebug('❌ 操作失败: $message (代码: $code)', tag: 'OrderController');
      
      // 清除加载状态
      if (operation.dish != null) {
        _setDishLoading(operation.dish!.id, false);
      }
      
      // 根据错误代码处理不同的错误情况
      switch (code) {
        case 409:
          // 超出上限，弹窗确认是否继续添加
          logDebug('⚠️ 超出上限，需要用户确认是否继续添加', tag: 'OrderController');
          logDebug('🔍 409错误详情 - 菜品: ${operation.dish?.name}, 消息: $message', tag: 'OrderController');
          _show409ConfirmDialog(operation, message);
          break;
        case 501:
          // 查询购物车失败，可能是数据不一致，刷新购物车后重试
          logDebug('⚠️ 查询购物车失败(501)，刷新购物车数据后重试', tag: 'OrderController');
          _handleCart501Error(operation);
          return; // 不显示错误提示，因为会自动重试
        default:
          logDebug('❓ 未知的错误代码: $code', tag: 'OrderController');
          ErrorNotificationManager().showErrorNotification(
            title: '操作失败',
            message: message,
            errorCode: code.toString(),
          );
      }
    } catch (e) {
      logDebug('❌ 处理操作错误失败: $e', tag: 'OrderController');
    }
  }

  /// 处理501购物车查询失败错误
  void _handleCart501Error(PendingOperation operation) {
    try {
      logDebug('🔄 处理501错误：刷新购物车数据后重试操作', tag: 'OrderController');
      
      // 先刷新购物车数据
      _loadCartFromApi().then((_) {
        // 延迟1秒后重试操作，给服务器一些时间同步数据
        Future.delayed(Duration(seconds: 1), () {
          _retryFailedOperation(operation);
        });
      }).catchError((error) {
        logDebug('❌ 刷新购物车数据失败，无法重试操作: $error', tag: 'OrderController');
        // 刷新失败时，显示错误提示
        ErrorNotificationManager().showErrorNotification(
          title: '操作失败',
          message: '购物车数据同步失败，请重试',
          errorCode: 'cart_sync_failed',
        );
      });
    } catch (e) {
      logDebug('❌ 处理501错误失败: $e', tag: 'OrderController');
      ErrorNotificationManager().showErrorNotification(
        title: '操作失败',
        message: '系统错误，请重试',
        errorCode: 'system_error',
      );
    }
  }

  /// 重试失败的操作
  void _retryFailedOperation(PendingOperation operation) {
    try {
      logDebug('🔄 重试操作: ${operation.type}', tag: 'OrderController');
      
      switch (operation.type) {
        case 'delete':
          // 重试删除操作
          if (operation.cartItem != null) {
            logDebug('🔄 重试删除操作: ${operation.cartItem!.dish.name}', tag: 'OrderController');
            _syncDeleteDishToWebSocket(operation.cartItem!);
          }
          break;
        case 'update':
          // 重试更新操作
          if (operation.cartItem != null && operation.quantity != null) {
            logDebug('🔄 重试更新操作: ${operation.cartItem!.dish.name} -> ${operation.quantity}', tag: 'OrderController');
            _syncUpdateDishQuantityToWebSocket(operation.cartItem!, operation.quantity!);
          }
          break;
        case 'add':
          // 重试添加操作
          if (operation.dish != null && operation.quantity != null) {
            logDebug('🔄 重试添加操作: ${operation.dish!.name} x${operation.quantity}', tag: 'OrderController');
            _syncAddDishToWebSocket(operation.dish!, operation.quantity!, operation.selectedOptions);
          }
          break;
        case 'clear':
          // 重试清空操作
          logDebug('🔄 重试清空购物车操作', tag: 'OrderController');
          _syncClearCartToWebSocket();
          break;
        default:
          logDebug('⚠️ 未知的操作类型，无法重试: ${operation.type}', tag: 'OrderController');
      }
    } catch (e) {
      logDebug('❌ 重试操作失败: $e', tag: 'OrderController');
      ErrorNotificationManager().showErrorNotification(
        title: '重试失败',
        message: '操作重试失败，请手动重试',
        errorCode: 'retry_failed',
      );
    }
  }


  /// 同步添加菜品到WebSocket
  Future<String?> _syncAddDishToWebSocket(Dish dish, int quantity, Map<String, List<String>>? selectedOptions) async {
    if (table.value?.tableId == null) {
      logDebug('⚠️ 桌台ID为空，跳过WebSocket同步', tag: 'OrderController');
      return null;
    }

    try {
      // 生成消息ID
      final messageId = _generateMessageId();
      
      // 存储待确认操作
      _pendingOperations[messageId] = PendingOperation(
        type: 'add',
        dish: dish,
        selectedOptions: selectedOptions,
        quantity: quantity,
      );
      
      bool success = false;
      
      final tableId = table.value!.tableId.toString();
      final dishId = int.tryParse(dish.id) ?? 0;
      final options = _convertOptionsToServerFormat(selectedOptions);
      
      logDebug('📤 添加菜品参数: 桌台ID=$tableId, 菜品ID=$dishId, 数量=$quantity, 消息ID=$messageId', tag: 'OrderController');
      
      success = await _wsManager.sendAddDishToCartWithId(
        tableId: tableId,
        dishId: dishId,
        quantity: quantity,
        options: options,
        forceOperate: false,
        messageId: messageId,
      );
      
      logDebug('📤 添加菜品到WebSocket: ${dish.name} x$quantity, 消息ID: $messageId', tag: 'OrderController');

      if (success) {
        return messageId;
      } else {
        logDebug('❌ 添加菜品同步到WebSocket失败', tag: 'OrderController');
        _pendingOperations.remove(messageId);
        return null;
      }
    } catch (e) {
      logDebug('❌ 同步添加菜品到WebSocket异常: $e', tag: 'OrderController');
      return null;
    }
  }

  /// 同步更新菜品数量到WebSocket
  Future<void> _syncUpdateDishQuantityToWebSocket(CartItem cartItem, int quantity) async {
    if (table.value?.tableId == null) {
      logDebug('⚠️ 桌台ID为空，跳过WebSocket同步', tag: 'OrderController');
      return;
    }

    if (cartItem.cartSpecificationId == null) {
      logDebug('⚠️ cartSpecificationId为空，跳过WebSocket同步', tag: 'OrderController');
      return;
    }

    if (cartItem.cartId == null) {
      logDebug('⚠️ 购物车外层ID为空，跳过WebSocket同步', tag: 'OrderController');
      return;
    }

    try {
      // 生成消息ID
      final messageId = _generateMessageId();
      
      // 存储待确认操作
      _pendingOperations[messageId] = PendingOperation(
        type: 'update',
        cartItem: cartItem,
        quantity: quantity,
      );

      final success = await _wsManager.sendUpdateDishQuantityWithId(
        tableId: table.value!.tableId.toString(),
        quantity: quantity,
        cartId: cartItem.cartId!, // 使用购物车外层ID
        cartSpecificationId: cartItem.cartSpecificationId!,
        messageId: messageId,
      );

      if (success) {
        logDebug('📤 更新菜品数量已同步到WebSocket: ${cartItem.dish.name} x$quantity, 消息ID: $messageId', tag: 'OrderController');
      } else {
        logDebug('❌ 更新菜品数量同步到WebSocket失败', tag: 'OrderController');
        _pendingOperations.remove(messageId);
      }
    } catch (e) {
      logDebug('❌ 同步更新菜品数量到WebSocket异常: $e', tag: 'OrderController');
    }
  }

  /// 同步减少菜品数量到WebSocket（使用incr_quantity字段）
  Future<void> _syncDecreaseDishQuantityToWebSocket(CartItem cartItem, int incrQuantity) async {
    if (table.value?.tableId == null) {
      logDebug('⚠️ 桌台ID为空，跳过WebSocket同步', tag: 'OrderController');
      return;
    }

    if (cartItem.cartSpecificationId == null) {
      logDebug('⚠️ cartSpecificationId为空，跳过WebSocket同步', tag: 'OrderController');
      return;
    }

    if (cartItem.cartId == null) {
      logDebug('⚠️ 购物车外层ID为空，跳过WebSocket同步', tag: 'OrderController');
      return;
    }

    try {
      // 生成消息ID
      final messageId = _generateMessageId();
      
      // 存储待确认操作
      _pendingOperations[messageId] = PendingOperation(
        type: 'update',
        cartItem: cartItem,
        quantity: cart[cartItem] ?? 0,
      );

      final success = await _wsManager.sendDecreaseDishQuantityWithId(
        tableId: table.value!.tableId.toString(),
        cartId: cartItem.cartId!,
        cartSpecificationId: cartItem.cartSpecificationId!,
        incrQuantity: incrQuantity,
        messageId: messageId,
      );

      if (success) {
        logDebug('📤 减少菜品数量已同步到WebSocket: ${cartItem.dish.name} 增量$incrQuantity, 消息ID: $messageId', tag: 'OrderController');
      } else {
        logDebug('❌ 减少菜品数量同步到WebSocket失败', tag: 'OrderController');
        _pendingOperations.remove(messageId);
      }
    } catch (e) {
      logDebug('❌ 同步减少菜品数量到WebSocket异常: $e', tag: 'OrderController');
    }
  }

  /// 同步删除菜品到WebSocket
  Future<void> _syncDeleteDishToWebSocket(CartItem cartItem) async {
    if (table.value?.tableId == null) {
      logDebug('⚠️ 桌台ID为空，跳过WebSocket同步', tag: 'OrderController');
      return;
    }

    if (cartItem.cartSpecificationId == null) {
      logDebug('⚠️ cartSpecificationId为空，跳过WebSocket同步', tag: 'OrderController');
      return;
    }

    if (cartItem.cartId == null) {
      logDebug('⚠️ 购物车外层ID为空，跳过WebSocket同步', tag: 'OrderController');
      return;
    }

    try {
      // 生成消息ID
      final messageId = _generateMessageId();
      
      // 存储待确认操作
      _pendingOperations[messageId] = PendingOperation(
        type: 'delete',
        cartItem: cartItem,
      );

      final success = await _wsManager.sendDeleteDishWithId(
        tableId: table.value!.tableId.toString(),
        cartSpecificationId: cartItem.cartSpecificationId!,
        cartId: cartItem.cartId!, // 使用购物车外层ID
        messageId: messageId,
      );

      if (success) {
        logDebug('📤 删除菜品已同步到WebSocket: ${cartItem.dish.name}, 消息ID: $messageId', tag: 'OrderController');
      } else {
        logDebug('❌ 删除菜品同步到WebSocket失败', tag: 'OrderController');
        _pendingOperations.remove(messageId);
      }
    } catch (e) {
      logDebug('❌ 同步删除菜品到WebSocket异常: $e', tag: 'OrderController');
    }
  }

  /// 同步清空购物车到WebSocket
  Future<void> _syncClearCartToWebSocket() async {
    if (table.value?.tableId == null) {
      logDebug('⚠️ 桌台ID为空，跳过WebSocket同步', tag: 'OrderController');
      return;
    }

    try {
      final success = await _wsManager.sendClearCart(
        tableId: table.value!.tableId.toString(),
      );

      if (success) {
        logDebug('📤 清空购物车已同步到WebSocket', tag: 'OrderController');
        // 延迟刷新购物车数据以确保服务器端处理完成
        Future.delayed(Duration(milliseconds: 1000), () {
          _refreshCartAfterOperation();
        });
      } else {
        logDebug('❌ 清空购物车同步到WebSocket失败', tag: 'OrderController');
      }
    } catch (e) {
      logDebug('❌ 同步清空购物车到WebSocket异常: $e', tag: 'OrderController');
    }
  }

  /// WebSocket操作后刷新购物车数据
  void _refreshCartAfterOperation() {
    logDebug('🔄 WebSocket操作后刷新购物车数据', tag: 'OrderController');
    _loadCartFromApi();
  }

  /// 转换规格选项为服务器格式
  List<DishOption> _convertOptionsToServerFormat(Map<String, List<String>>? selectedOptions) {
    if (selectedOptions == null || selectedOptions.isEmpty) {
      return [];
    }

    final options = <DishOption>[];
    
    // 根据选中的规格选项构建DishOption列表
    selectedOptions.forEach((optionIdStr, itemIdStrs) {
      if (itemIdStrs.isNotEmpty) {
        // optionIdStr是optionId的字符串形式，itemIdStrs是itemIds的字符串列表
        final optionId = int.tryParse(optionIdStr) ?? 0;
        final itemIds = itemIdStrs.map((idStr) => int.tryParse(idStr) ?? 0).toList();
        
        // 只有当optionId和itemIds都有效时才添加
        if (optionId > 0 && itemIds.any((id) => id > 0)) {
          options.add(DishOption(
            id: optionId,
            itemIds: itemIds,
            customValues: [],
          ));
        }
      }
    });
    
    return options;
  }

  /// 处理桌台相关消息
  void _handleTableMessage(Map<String, dynamic> data) {
    final action = data['action'] as String?;
    
    switch (action) {
      case 'change_menu':
        _handleServerChangeMenu(data);
        break;
      case 'change_people_count':
        _handleServerChangePeopleCount(data);
        break;
      case 'change_table':
        _handleServerChangeTable(data);
        break;
      default:
        logDebug('⚠️ 未知的桌台操作: $action', tag: 'OrderController');
    }
  }


  /// 处理服务器修改菜单消息
  void _handleServerChangeMenu(Map<String, dynamic> data) {
    try {
      logDebug('📋 收到服务器修改菜单消息: $data', tag: 'OrderController');
      
      final menuId = data['menu_id'] as int?;
      if (menuId != null) {
        logDebug('📝 需要切换到菜单ID: $menuId', tag: 'OrderController');
        
        // 检查当前菜单是否已经是目标菜单
        if (menu.value?.menuId == menuId) {
          logDebug('✅ 当前菜单已经是目标菜单，无需切换', tag: 'OrderController');
          return;
        }
        
        // 更新菜单信息 - 需要从菜单列表中查找对应的菜单
        _updateMenuById(menuId);
      }
    } catch (e) {
      logDebug('❌ 处理服务器修改菜单消息失败: $e', tag: 'OrderController');
    }
  }
  
  /// 根据菜单ID更新菜单信息
  Future<void> _updateMenuById(int menuId) async {
    try {
      logDebug('🔄 开始根据菜单ID $menuId 更新菜单信息...', tag: 'OrderController');
      
      // 检查当前菜单是否已经是目标菜单
      if (menu.value?.menuId == menuId) {
        logDebug('✅ 当前菜单已经是目标菜单，重新加载菜品和购物车数据', tag: 'OrderController');
        await _loadDishesAndCart();
        return;
      }
      
      // 获取所有菜单列表
      final result = await _api.getTableMenuList();
      if (result.isSuccess && result.data != null) {
        // 查找目标菜单
        final targetMenu = result.data!.firstWhere(
          (menu) => menu.menuId == menuId,
          orElse: () => result.data!.first, // 如果找不到，使用第一个菜单
        );
        
        // 更新菜单信息
        menu.value = targetMenu;
        logDebug('✅ 菜单信息已更新: ${targetMenu.menuName} (ID: ${targetMenu.menuId})', tag: 'OrderController');
        
        // 重新加载菜品和购物车数据
        await _loadDishesAndCart();
        
        logDebug('🔄 菜单切换完成，UI已刷新', tag: 'OrderController');
      } else {
        logDebug('❌ 获取菜单列表失败: ${result.msg}', tag: 'OrderController');
        // 即使获取菜单列表失败，也尝试重新加载菜品和购物车数据
        await _loadDishesAndCart();
      }
    } catch (e) {
      logDebug('❌ 根据菜单ID更新菜单信息失败: $e', tag: 'OrderController');
      // 即使更新菜单失败，也尝试重新加载菜品和购物车数据
      await _loadDishesAndCart();
    }
  }

  /// 处理服务器修改人数消息
  void _handleServerChangePeopleCount(Map<String, dynamic> data) {
    try {
      logDebug('👥 收到服务器修改人数消息: $data', tag: 'OrderController');
      
      final adultCount = data['adult_count'] as int?;
      final childCount = data['child_count'] as int?;
      
      if (adultCount != null && childCount != null) {
        logDebug('📝 人数已修改: 成人$adultCount, 儿童$childCount', tag: 'OrderController');
        
        // 调用API接口更新人数
        _updatePeopleCountViaApi(adultCount, childCount);
      }
    } catch (e) {
      logDebug('❌ 处理服务器修改人数消息失败: $e', tag: 'OrderController');
    }
  }

  /// 通过API更新人数
  Future<void> _updatePeopleCountViaApi(int adultCount, int childCount) async {
    try {
      final tableId = table.value?.tableId.toInt();
      if (tableId == null) {
        logDebug('❌ 桌台ID为空，无法更新人数', tag: 'OrderController');
        return;
      }

      logDebug('🔄 调用API更新人数: 桌台$tableId, 成人$adultCount, 儿童$childCount', tag: 'OrderController');
      
      final result = await _api.changePeopleCount(
        tableId: tableId,
        adultCount: adultCount,
        childCount: childCount,
      );

      if (result.isSuccess) {
        logDebug('✅ 人数更新成功', tag: 'OrderController');
        // 更新本地人数信息
        this.adultCount.value = adultCount;
        this.childCount.value = childCount;
      } else {
        logDebug('❌ 人数更新失败: ${result.msg}', tag: 'OrderController');
        ErrorNotificationManager().showErrorNotification(
          title: '更新失败',
          message: '人数更新失败: ${result.msg}',
          errorCode: 'update_people_failed',
        );
      }
    } catch (e) {
      logDebug('❌ 调用人数更新API异常: $e', tag: 'OrderController');
      ErrorNotificationManager().showErrorNotification(
        title: '更新异常',
        message: '人数更新异常: $e',
        errorCode: 'update_people_exception',
      );
    }
  }

  /// 处理服务器更换桌子消息
  void _handleServerChangeTable(Map<String, dynamic> data) {
    try {
      logDebug('🔄 收到服务器更换桌子消息: $data', tag: 'OrderController');
      
      final tableName = data['table_name'] as String?;
      
      if (tableName != null && table.value != null) {
        logDebug('📝 桌名已修改: $tableName', tag: 'OrderController');
        
        // 更新桌台名称
        final currentTable = table.value!;
        final updatedTable = TableListModel(
          hallId: currentTable.hallId,
          hallName: currentTable.hallName,
          tableId: currentTable.tableId,
          tableName: tableName,
          standardAdult: currentTable.standardAdult,
          standardChild: currentTable.standardChild,
          currentAdult: currentTable.currentAdult,
          currentChild: currentTable.currentChild,
          status: currentTable.status,
          businessStatus: currentTable.businessStatus,
          businessStatusName: currentTable.businessStatusName,
          mainTableId: currentTable.mainTableId,
          menuId: currentTable.menuId,
          openTime: currentTable.openTime,
          orderTime: currentTable.orderTime,
          orderDuration: currentTable.orderDuration,
          openDuration: currentTable.openDuration,
          checkoutTime: currentTable.checkoutTime,
          orderAmount: currentTable.orderAmount,
          mainTable: currentTable.mainTable,
        );
        table.value = updatedTable;
      }
    } catch (e) {
      logDebug('❌ 处理服务器更换桌子消息失败: $e', tag: 'OrderController');
    }
  }




  /// 处理购物车响应消息（操作确认）
  void _handleCartResponseMessage(Map<String, dynamic> data) {
    try {
      logDebug('📨 收到服务器操作确认消息: $data', tag: 'OrderController');
      
      final code = data['code'] as int?;
      final message = data['message'] as String?;
      final originalId = data['original_id'] as String?;
      final responseData = data['data'];
      
      if (code != null && message != null && originalId != null) {
        logDebug('📝 操作确认: 代码$code, 消息$message, 原始ID$originalId', tag: 'OrderController');
        
        // 检查是否有对应的待确认操作
        if (_pendingOperations.containsKey(originalId)) {
          final operation = _pendingOperations[originalId]!;
          
          if (code == 0) {
            // 操作成功，更新UI
            logDebug('✅ 操作成功，更新购物车UI', tag: 'OrderController');
            _updateCartFromResponse(operation, responseData, message);
          } else {
            // 操作失败，处理错误
            logDebug('❌ 操作失败: $message', tag: 'OrderController');
            _handleOperationError(operation, code, message);
          }
          
          // 移除待确认操作
          _pendingOperations.remove(originalId);
        } else {
          logDebug('⚠️ 未找到对应的待确认操作: $originalId', tag: 'OrderController');
        }
      }
    } catch (e) {
      logDebug('❌ 处理服务器操作确认消息失败: $e', tag: 'OrderController');
    }
  }

  /// 从服务器刷新购物车数据（带防抖）
  void _refreshCartFromServer() {
    try {
      logDebug('🔄 准备从服务器刷新购物车数据', tag: 'OrderController');
      
      // 取消之前的刷新计时器
      _cartRefreshTimer?.cancel();
      
      // 设置1000ms的防抖延迟，给服务器更多时间同步数据
      _cartRefreshTimer = Timer(Duration(milliseconds: 1000), () {
        logDebug('🔄 执行购物车数据刷新', tag: 'OrderController');
        _loadCartFromApi();
      });
    } catch (e) {
      logDebug('❌ 从服务器刷新购物车数据失败: $e', tag: 'OrderController');
    }
  }

  @override
  void onClose() {
    // 移除WebSocket消息监听器
    if (_webSocketMessageListener != null) {
      _wsManager.removeServerMessageListener(_webSocketMessageListener!);
      _webSocketMessageListener = null;
    }
    
    // 清理WebSocket连接
    if (table.value?.tableId != null) {
      _wsManager.disconnectTable(table.value!.tableId.toString());
    }
    
    // 清理计时器
    _cartRefreshTimer?.cancel();
    
    // 清理防抖定时器
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    
    super.onClose();
  }

  /// 显示409错误确认对话框
  void _show409ConfirmDialog(PendingOperation operation, String message) {
    try {
      logDebug('🔔 开始显示409确认对话框', tag: 'OrderController');
      
      if (operation.dish == null) {
        logDebug('❌ 菜品信息为空，无法显示确认对话框', tag: 'OrderController');
        return;
      }
      
      logDebug('🔔 显示409确认对话框: ${operation.dish!.name}', tag: 'OrderController');
      logDebug('🔍 对话框消息内容: $message', tag: 'OrderController');
      
      // 获取当前上下文
      final context = Get.context;
      logDebug('🔍 获取到的上下文: ${context != null ? "有效" : "null"}', tag: 'OrderController');
      
      if (context == null) {
        logDebug('❌ 无法获取上下文，无法显示确认对话框', tag: 'OrderController');
        return;
      }
      
      logDebug('🔍 准备调用Get.dialog显示确认对话框', tag: 'OrderController');
      
      Get.dialog(
        AlertDialog(
          title: Text('超出限制'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                logDebug('❌ 用户取消添加菜品: ${operation.dish!.name}', tag: 'OrderController');
                Get.back();
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                logDebug('✅ 用户选择继续添加菜品: ${operation.dish!.name}', tag: 'OrderController');
                Get.back();
                _retryAddDishWithForce(operation);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange,
              ),
              child: Text('继续添加'),
            ),
          ],
        ),
        barrierDismissible: true,
      );
      
      logDebug('🔍 Get.dialog调用完成', tag: 'OrderController');
    } catch (e) {
      logDebug('❌ 显示409确认对话框失败: $e', tag: 'OrderController');
    }
  }

  /// 重新添加菜品（使用force_operate=true）
  void _retryAddDishWithForce(PendingOperation operation) {
    try {
      if (operation.dish == null) return;
      
      logDebug('🔄 重新添加菜品（强制模式）: ${operation.dish!.name}', tag: 'OrderController');
      
      // 设置加载状态
      _setDishLoading(operation.dish!.id, true);
      
      // 设置超时清除加载状态（10秒后）
      Timer(Duration(seconds: 10), () {
        if (isDishLoading(operation.dish!.id)) {
          _setDishLoading(operation.dish!.id, false);
          logDebug('⏰ 菜品 ${operation.dish!.name} 强制添加超时，清除加载状态', tag: 'OrderController');
        }
      });
      
      // 重新发送添加请求，使用force_operate=true
      _syncAddDishToWebSocketWithForce(
        operation.dish!,
        operation.quantity ?? 1,
        operation.selectedOptions,
      );
    } catch (e) {
      logDebug('❌ 重新添加菜品失败: $e', tag: 'OrderController');
      if (operation.dish != null) {
        _setDishLoading(operation.dish!.id, false);
      }
    }
  }

  /// 同步添加菜品到WebSocket（强制模式）
  Future<String?> _syncAddDishToWebSocketWithForce(
    Dish dish, 
    int quantity, 
    Map<String, List<String>>? selectedOptions
  ) async {
    if (table.value?.tableId == null) {
      logDebug('⚠️ 桌台ID为空，跳过WebSocket同步', tag: 'OrderController');
      return null;
    }

    try {
      // 生成消息ID
      final messageId = _generateMessageId();
      
      // 存储待确认操作
      _pendingOperations[messageId] = PendingOperation(
        type: 'add',
        dish: dish,
        selectedOptions: selectedOptions,
        quantity: quantity,
      );
      
      bool success = false;
      
      final tableId = table.value!.tableId.toString();
      final dishId = int.tryParse(dish.id) ?? 0;
      final options = _convertOptionsToServerFormat(selectedOptions);
      
      logDebug('📤 强制添加菜品参数: 桌台ID=$tableId, 菜品ID=$dishId, 数量=$quantity, 消息ID=$messageId', tag: 'OrderController');
      
      success = await _wsManager.sendAddDishToCartWithId(
        tableId: tableId,
        dishId: dishId,
        quantity: quantity,
        options: options,
        forceOperate: true, // 强制操作
        messageId: messageId,
      );
      
      logDebug('📤 强制添加菜品到WebSocket: ${dish.name} x$quantity, 消息ID: $messageId', tag: 'OrderController');

      if (success) {
        return messageId;
      } else {
        logDebug('❌ 强制添加菜品同步到WebSocket失败', tag: 'OrderController');
        _pendingOperations.remove(messageId);
        return null;
      }
    } catch (e) {
      logDebug('❌ 同步强制添加菜品到WebSocket异常: $e', tag: 'OrderController');
      return null;
    }
  }
}