import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:lib_domain/api/base_api.dart';
import 'package:lib_domain/entrity/order/dish_list_model/dish_list_model.dart';
import 'package:order_app/pages/order/order_element/order_page.dart';
import 'package:order_app/pages/order/order_element/order_controller.dart';
import 'package:lib_base/utils/navigation_manager.dart';
import 'package:lib_base/logging/logging.dart';

class SelectMenuController extends GetxController {
  // 传入的数据
  var table = TableListModel( 
    hallId: 1,
    hallName: '测试大厅',
    tableId: 1,
    tableName: '测试桌台',
    standardAdult: 2,
    standardChild: 1,
    currentAdult: 0,
    currentChild: 0,
    status: 0,
    businessStatus: 0,
    businessStatusName: '空闲',
    mainTableId: 1,
    menuId: 1,
    openTime: '',
    orderTime: '',
    orderDuration: 0,
    checkoutTime: '',
    orderAmount: 0,
    mainTable: null, openDuration: 0,
  ).obs;
  
  var menu = <TableMenuListModel>[].obs;
  
  // 响应式变量
  var adultCount = 1.obs; // 初始状态成人数量1
  var childCount = 0.obs; // 初始状态儿童数量0
  var selectedMenuIndex = 0.obs;
  var isLoadingDishes = false.obs; // 加载状态
  
  // 获取当前选中的菜单
  TableMenuListModel? getSelectedMenu() {
    return menu.isNotEmpty ? menu[selectedMenuIndex.value] : null;
  }
      
  final BaseApi _baseApi = BaseApi();
  List<List<DishListModel>> dishListModelList = [];

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  /// 初始化数据
  void _initData() {
    // 从 Get.arguments 获取传递的数据
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      // 获取路由参数中的 table_id
      final tableId = args['table_id'] as int?;
      
      // 更新 table 信息
      if (args['table'] != null) {
        table.value = args['table'] as TableListModel;
      }
      
      // 更新 menu 信息
      if (args['menu'] != null) {
        menu.value = args['menu'] as List<TableMenuListModel>;
        
        // 根据桌台的menuId设置默认选中的菜单
        _setDefaultSelectedMenu();
        
        // 有菜单数据后，异步获取菜品列表
        if (menu.isNotEmpty && tableId != null) {
          _loadAllMenuDishes(tableId);
        }
      }
    }
  }

  /// 根据桌台的menuId设置默认选中的菜单
  void _setDefaultSelectedMenu() {
    try {
      final currentTable = table.value;
      if (menu.isNotEmpty) {
        // 在菜单列表中查找当前桌台使用的菜单
        final currentMenuIndex = menu.indexWhere(
          (menuItem) => menuItem.menuId == currentTable.menuId,
        );
        
        if (currentMenuIndex != -1) {
          selectedMenuIndex.value = currentMenuIndex;
          logDebug('✅ 设置默认选中菜单: ${menu[currentMenuIndex].menuName} (索引: $currentMenuIndex)', tag: 'SelectMenuController');
        } else {
          // 如果找不到对应的菜单，保持默认选中第一个
          selectedMenuIndex.value = 0;
          logDebug('⚠️ 未找到桌台使用的菜单ID: ${currentTable.menuId}，使用默认第一个菜单', tag: 'SelectMenuController');
        }
      } else {
        // 如果桌台信息不完整，保持默认选中第一个
        selectedMenuIndex.value = 0;
        logDebug('⚠️ 桌台信息不完整，使用默认第一个菜单', tag: 'SelectMenuController');
      }
    } catch (e) {
      // 异常情况下，保持默认选中第一个
      selectedMenuIndex.value = 0;
      logError('❌ 设置默认选中菜单时出错: $e', tag: 'SelectMenuController');
    }
  }

  /// 异步加载所有菜单的菜品数据
  Future<void> _loadAllMenuDishes(int tableId) async {
    if (menu.isEmpty) return;
    
    isLoadingDishes.value = true;
    dishListModelList.clear(); // 清空之前的数据
    
    try {
      // 使用 Future.wait 并发获取所有菜单的菜品数据
      final futures = menu.map((menuItem) {
        final menuId = menuItem.menuId;
        if (menuId != null) {
          return getMenuDishList(tableId: tableId, menuId: menuId);
        }
        return Future.value(<DishListModel>[]);
      }).toList();
      
      final results = await Future.wait(futures);
      dishListModelList = results;
      
      logDebug('✅ 成功加载了 ${dishListModelList.length} 个菜单的菜品数据', tag: 'SelectMenuController');
      
    } catch (e) {
      logError('❌ 加载菜品数据失败: $e', tag: 'SelectMenuController');
      Get.snackbar('错误', '加载菜品数据失败');
    } finally {
      isLoadingDishes.value = false;
    }
  }

  /// 获取单个菜单的菜品列表
  Future<List<DishListModel>> getMenuDishList({
    required int tableId,
    required int menuId,
  }) async {
    try {
      final result = await _baseApi.getMenudDishList(
        tableID: tableId.toString(),
        menuId: menuId.toString(),
      );
      
      if (result.isSuccess && result.data != null) {
        return result.data!;
      } else {
        logWarning('⚠️ 获取菜单 $menuId 的菜品失败: ${result.msg}', tag: 'SelectMenuController');
        return <DishListModel>[];
      }
    } catch (e) {
      logError('❌ 获取菜单 $menuId 的菜品异常: $e', tag: 'SelectMenuController');
      return <DishListModel>[];
    }
  }

  // /// 根据菜单索引获取菜品列表
  // List<DishListModel> getDishListByMenuIndex(int menuIndex) {
  //   if (menuIndex >= 0 && menuIndex < dishListModelList.length) {
  //     return dishListModelList[menuIndex];
  //   }
  //   return <DishListModel>[];
  // }

  // /// 获取当前选中菜单的菜品列表
  // List<DishListModel> get selectedMenuDishes {
  //   return getDishListByMenuIndex(selectedMenuIndex.value);
  // }

  // /// 手动刷新菜品数据
  // Future<void> refreshDishData() async {
  //   final args = Get.arguments as Map<String, dynamic>?;
  //   final tableId = args?['table_id'] as int?;
    
  //   if (tableId != null) {
  //     await _loadAllMenuDishes(tableId);
  //   }
  // }

  /// 增加成人数量
  void increaseAdultCount() {
    final maxAdult = table.value.standardAdult.toInt();
    if (adultCount.value < maxAdult) {
      adultCount.value++;
    } else {
      // 达到最大时再增加提示
      Get.snackbar(
        '提示', 
        '成人数量不能超过桌台上限 ${maxAdult} 人',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.withOpacity(0.9),
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    }
  }

  /// 减少成人数量
  void decreaseAdultCount() {
    if (adultCount.value > 1) {
      adultCount.value--;
    }
  }

  /// 增加儿童数量
  void increaseChildCount() {
    final maxChild = table.value.standardChild.toInt();
    if (childCount.value < maxChild) {
      childCount.value++;
    } else {
      // 达到最大时再增加提示
      Get.snackbar(
        '提示', 
        '儿童数量不能超过桌台上限 ${maxChild} 人',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.withOpacity(0.9),
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    }
  }

  /// 减少儿童数量
  void decreaseChildCount() {
    if (childCount.value > 0) {
      childCount.value--;
    }
  }

  /// 选择菜单
  void selectMenu(int index) {
    if (index >= 0 && index < menu.length) {
      selectedMenuIndex.value = index;
      logDebug('🎯 选中菜单 $index，菜品数量: ${dishListModelList.length}', tag: 'SelectMenuController');
    }
  }

  /// 开始点餐
  void startOrdering() async {
    if (getSelectedMenu() == null) {
      Get.snackbar('提示', '请选择菜单');
      return;
    }

    if (isLoadingDishes.value) {
      Get.snackbar('提示', '菜品数据加载中，请稍后');
      return;
    }

    // 检查菜品数据是否有效
    if (selectedMenuIndex.value >= dishListModelList.length) {
      Get.snackbar('提示', '菜品数据还未加载完成');
      return;
    }

    try {
      // 调用开桌接口
      final result = await _baseApi.openTable(
        tableId: table.value.tableId.toInt(),
        adultCount: adultCount.value,
        childCount: childCount.value,
        menuId: getSelectedMenu()!.menuId!.toInt(),
        // reserveId: 0, // 默认值
      );

      if (result.isSuccess) {
        // 开桌成功，跳转到点餐页面
        _navigateToOrderPage();
      } else {
        // 开桌失败，显示错误信息
        Get.snackbar('开桌失败', result.msg ?? '未知错误');
      }
    } catch (e) {
      Get.snackbar('开桌失败', '网络错误: $e');
    }
  }

  /// 跳转到点餐页面
  void _navigateToOrderPage() {
    // 额外安全检查
    if (selectedMenuIndex.value >= dishListModelList.length) {
      Get.snackbar('错误', '菜品数据异常，请重试');
      return;
    }
    
    // 准备传递给点餐页面的数据
    final selectedDishes = dishListModelList[selectedMenuIndex.value];
    logDebug('🍽️ 准备传递菜品数据:', tag: 'SelectMenuController');
    // print('  选中菜单索引: ${selectedMenuIndex.value}');
    // print('  菜品类目数量: ${selectedDishes.length}');
    // print('  dishListModelList总长度: ${dishListModelList.length}');
    for (int i = 0; i < selectedDishes.length; i++) {
      // final dishModel = selectedDishes[i];
      // print('    类目 $i: ${dishModel.name}, 菜品数量: ${dishModel.items?.length ?? 0}');
    }
    
    final orderData = {
      'table': table.value,
      'menu': getSelectedMenu()!, // 使用!确保不为null
      'dishes': selectedDishes, // 传递当前选中菜单的菜品
      'adultCount': adultCount.value,
      'childCount': childCount.value,
    };
    
    logDebug('📦 准备传递的完整数据:', tag: 'SelectMenuController');
    // print('  table: ${table.value.tableName}');
    // print('  menu: ${getSelectedMenu()!.menuName}'); 
    // print('  dishes: ${selectedDishes.length} 个类目');
    // print('  adultCount: ${adultCount.value}');
    // print('  childCount: ${childCount.value}');

    // 先删除可能存在的旧实例
    if (Get.isRegistered<OrderController>()) {
      Get.delete<OrderController>();
    }
    
    // 使用导航管理器统一处理跳转逻辑
    NavigationManager.goToOrderPage(() => OrderDishPage(), arguments: orderData);
  }

  /// 返回上一页
  void goBack() {
    Get.back();
  }

  /// 获取菜单标签背景图片
  String getMenuLabelImage(bool isSelected) {
    return isSelected
        ? 'assets/order_table_menu_labbgs.webp'
        : 'assets/order_table_menu_labbgu.webp';
  }

  /// 获取菜单边框颜色
  Color getMenuBorderColor(bool isSelected) {
    return isSelected ? const Color(0xFFFF9027) : const Color(0xFFE0E0E0);
  }

  /// 获取菜单边框宽度
  double getMenuBorderWidth(bool isSelected) {
    return isSelected ? 2.0 : 1.0;
  }
}