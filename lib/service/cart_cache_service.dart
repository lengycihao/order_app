// import 'package:get/get.dart';
// import 'package:lib_base/lib_base.dart';
// import 'dart:convert';
// import '../pages/order/order_element/order_controller.dart';
// import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
// import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';

// /// 桌台购物车缓存服务
// /// 负责管理每个桌台的购物车数据和菜单信息的本地缓存
// class CartCacheService extends GetxService {
//   static const String _cartCachePrefix = 'table_cart_';
//   static const String _menuCachePrefix = 'table_menu_';
//   static const String _tableCachePrefix = 'table_info_';
  
//   static CartCacheService get instance => Get.find<CartCacheService>();

//   @override
//   void onInit() {
//     super.onInit();
//     print('🗂️ CartCacheService 初始化完成');
//   }

//   /// 保存桌台购物车数据
//   Future<void> saveTableCart(String tableId, Map<CartItem, int> cart) async {
//     try {
//       final cartData = cart.map((cartItem, count) => MapEntry(
//         _cartItemToJson(cartItem),
//         count,
//       ));
      
//       final jsonString = json.encode({
//         'tableId': tableId,
//         'cart': cartData,
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//       });
      
//       await SpUtil.putString('${_cartCachePrefix}$tableId', jsonString);
//       print('💾 桌台 $tableId 购物车数据已缓存: ${cart.length} 种商品');
//     } catch (e) {
//       print('❌ 保存桌台购物车失败: $e');
//     }
//   }

//   /// 获取桌台购物车数据
//   Map<CartItem, int>? getTableCart(String tableId) {
//     try {
//       final jsonString = SpUtil.getString('${_cartCachePrefix}$tableId');
//       if (jsonString.isEmpty) {
//         print('📂 桌台 $tableId 没有缓存的购物车数据');
//         return null;
//       }

//       final data = json.decode(jsonString) as Map<String, dynamic>;
//       final cartData = data['cart'] as Map<String, dynamic>;
      
//       final cart = <CartItem, int>{};
//       cartData.forEach((key, value) {
//         final cartItem = _cartItemFromJson(json.decode(key));
//         cart[cartItem] = value as int;
//       });
      
//       print('📂 桌台 $tableId 购物车数据已加载: ${cart.length} 种商品');
//       return cart;
//     } catch (e) {
//       print('❌ 获取桌台购物车失败: $e');
//       return null;
//     }
//   }

//   /// 清空桌台购物车缓存
//   Future<void> clearTableCart(String tableId) async {
//     try {
//       await SpUtil.remove('${_cartCachePrefix}$tableId');
//       print('🧹 桌台 $tableId 购物车缓存已清空');
//     } catch (e) {
//       print('❌ 清空桌台购物车缓存失败: $e');
//     }
//   }

//   /// 保存桌台菜单信息
//   Future<void> saveTableMenu(String tableId, TableMenuListModel menu, TableListModel table, int adultCount, int childCount) async {
//     try {
//       final menuData = {
//         'tableId': tableId,
//         'menu': menu.toJson(),
//         'table': table.toJson(),
//         'adultCount': adultCount,
//         'childCount': childCount,
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//       };
      
//       final jsonString = json.encode(menuData);
//       await SpUtil.putString('${_menuCachePrefix}$tableId', jsonString);
//       print('💾 桌台 $tableId 菜单信息已缓存: ${menu.menuName}');
//     } catch (e) {
//       print('❌ 保存桌台菜单信息失败: $e');
//     }
//   }

//   /// 获取桌台菜单信息
//   Map<String, dynamic>? getTableMenu(String tableId) {
//     try {
//       final jsonString = SpUtil.getString('${_menuCachePrefix}$tableId');
//       if (jsonString.isEmpty) {
//         print('📂 桌台 $tableId 没有缓存的菜单信息');
//         return null;
//       }

//       final data = json.decode(jsonString) as Map<String, dynamic>;
//       print('📂 桌台 $tableId 菜单信息已加载: ${data['menu']['menuName']}');
//       return data;
//     } catch (e) {
//       print('❌ 获取桌台菜单信息失败: $e');
//       return null;
//     }
//   }

//   /// 清空桌台菜单信息缓存
//   Future<void> clearTableMenu(String tableId) async {
//     try {
//       await SpUtil.remove('${_menuCachePrefix}$tableId');
//       print('🧹 桌台 $tableId 菜单信息缓存已清空');
//     } catch (e) {
//       print('❌ 清空桌台菜单信息缓存失败: $e');
//     }
//   }

//   /// 保存桌台详细信息
//   Future<void> saveTableDetail(String tableId, TableListModel table) async {
//     try {
//       final tableData = {
//         'tableId': tableId,
//         'table': table.toJson(),
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//       };
      
//       final jsonString = json.encode(tableData);
//       await SpUtil.putString('${_tableCachePrefix}$tableId', jsonString);
//       print('💾 桌台 $tableId 详细信息已缓存');
//     } catch (e) {
//       print('❌ 保存桌台详细信息失败: $e');
//     }
//   }

//   /// 获取桌台详细信息
//   TableListModel? getTableDetail(String tableId) {
//     try {
//       final jsonString = SpUtil.getString('${_tableCachePrefix}$tableId');
//       if (jsonString.isEmpty) {
//         return null;
//       }

//       final data = json.decode(jsonString) as Map<String, dynamic>;
//       final tableData = data['table'] as Map<String, dynamic>;
//       return TableListModel.fromJson(tableData);
//     } catch (e) {
//       print('❌ 获取桌台详细信息失败: $e');
//       return null;
//     }
//   }

//   /// 获取所有非空闲桌台的ID列表（有缓存数据的桌台）
//   List<String> getNonIdleTableIds() {
//     try {
//       final allKeys = SpUtil.getKeys();
//       final cartKeys = allKeys.where((key) => key.startsWith(_cartCachePrefix));
//       final menuKeys = allKeys.where((key) => key.startsWith(_menuCachePrefix));
      
//       final Set<String> tableIds = {};
      
//       // 从购物车缓存中获取桌台ID
//       for (final key in cartKeys) {
//         final tableId = key.replaceFirst(_cartCachePrefix, '');
//         final cart = getTableCart(tableId);
//         if (cart != null && cart.isNotEmpty) {
//           tableIds.add(tableId);
//         }
//       }
      
//       // 从菜单缓存中获取桌台ID
//       for (final key in menuKeys) {
//         final tableId = key.replaceFirst(_menuCachePrefix, '');
//         final menu = getTableMenu(tableId);
//         if (menu != null) {
//           tableIds.add(tableId);
//         }
//       }
      
//       print('📋 非空闲桌台列表: ${tableIds.toList()}');
//       return tableIds.toList();
//     } catch (e) {
//       print('❌ 获取非空闲桌台列表失败: $e');
//       return [];
//     }
//   }

//   /// 检查桌台是否为空闲状态（没有购物车数据和菜单信息）
//   bool isTableIdle(String tableId) {
//     final cart = getTableCart(tableId);
//     final menu = getTableMenu(tableId);
    
//     final hasCart = cart != null && cart.isNotEmpty;
//     final hasMenu = menu != null;
    
//     return !hasCart && !hasMenu;
//   }

//   /// 清空所有桌台缓存（退出登录时调用）
//   Future<void> clearAllTableCache() async {
//     try {
//       final allKeys = SpUtil.getKeys();
//       final cacheKeys = allKeys.where((key) => 
//         key.startsWith(_cartCachePrefix) ||
//         key.startsWith(_menuCachePrefix) ||
//         key.startsWith(_tableCachePrefix)
//       ).toList();
      
//       for (final key in cacheKeys) {
//         await SpUtil.remove(key);
//       }
      
//       print('🧹 所有桌台缓存已清空: ${cacheKeys.length} 个缓存项');
//     } catch (e) {
//       print('❌ 清空所有桌台缓存失败: $e');
//     }
//   }

//   /// 清理空闲桌台的缓存
//   Future<void> clearIdleTableCache(String tableId) async {
//     if (isTableIdle(tableId)) {
//       await clearTableCart(tableId);
//       await clearTableMenu(tableId);
//       await SpUtil.remove('${_tableCachePrefix}$tableId');
//       print('🧹 空闲桌台 $tableId 缓存已清理');
//     }
//   }

//   /// CartItem 转 JSON
//   String _cartItemToJson(CartItem cartItem) {
//     return json.encode({
//       'dish': {
//         'id': cartItem.dish.id,
//         'name': cartItem.dish.name,
//         'image': cartItem.dish.image,
//         'price': cartItem.dish.price,
//         'categoryId': cartItem.dish.categoryId,
//         'hasOptions': cartItem.dish.hasOptions,
//       },
//       'selectedOptions': cartItem.selectedOptions,
//     });
//   }

//   /// JSON 转 CartItem
//   CartItem _cartItemFromJson(Map<String, dynamic> json) {
//     final dishData = json['dish'] as Map<String, dynamic>;
//     final selectedOptions = Map<String, List<String>>.from(
//       (json['selectedOptions'] as Map<String, dynamic>? ?? {}).map(
//         (key, value) => MapEntry(key, List<String>.from(value as List)),
//       ),
//     );
    
//     return CartItem(
//       dish: Dish(
//         id: dishData['id'] as String,
//         name: dishData['name'] as String,
//         image: dishData['image'] as String,
//         price: (dishData['price'] as num).toDouble(),
//         categoryId: dishData['categoryId'] as int,
//         hasOptions: dishData['hasOptions'] as bool,
//       ),
//       selectedOptions: selectedOptions,
//     );
//   }
// }